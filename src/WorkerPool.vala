/* WorkerPool.vala
 *
 * Copyright (C) 2019  Космос Преда́ние (kosmospredanie@yandex.ru)
 *
 * This file is part of Gpseq.
 *
 * Gpseq is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * Gpseq is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Gpseq.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

namespace Gpseq {
	/**
	 * A thread pool for executing tasks in parallel.
	 */
	public class WorkerPool : Object, Executor {
		private static ThreadFactory? default_factory = null;
		/**
		 * Gets the default thread factory. the factory is constructed when this
		 * method is called initially.
		 * @return the default thread factory
		 */
		public static ThreadFactory get_default_factory () {
			lock (default_factory) {
				if (default_factory == null) {
					default_factory = new DefaultThreadFactory();
				}
				return (!)default_factory;
			}
		}

		private const int MAX_THREAD_IDLE_ITERATIONS = 4;

		private static int _next_pool_number; // AtomicInt
		private static int next_pool_number () {
			while (true) {
				int oldval = _next_pool_number;
				int newval = (oldval > int.MAX - 1) ? 0 : oldval+1;
				if ( AtomicInt.compare_and_exchange(ref _next_pool_number, oldval, newval) ) {
					return oldval;
				}
			}
		}

		private WorkQueue _submission_queue; // also used to lock

		private ThreadFactory _factory;
		private Gee.List<WorkerThread> _threads;
		private string _thread_name_prefix;
		private int _next_thread_id; // AtomicInt
		private Mutex _lock = Mutex();
		private Cond _cond = Cond(); // used to activate/deactivate threads

		/**
		 * * > 0 if terminate() has been called and the pool has not yet been terminated
		 * * 0 if the pool has been terminated
		 * * -1 otherwise
		 */
		private int _terminating = -1; // AtomicInt

		/**
		 * Creates a new worker pool, with default settings.
		 */
		public WorkerPool.with_defaults ()
		{
			// try 2x processors
			uint processors = GLib.get_num_processors();
			processors = uint.max(processors, processors * 2);
			processors = uint.min(int.MAX, processors);
			this( (int) processors, get_default_factory() );
		}

		/**
		 * Creates a new worker pool.
		 * @param parallels the number of threads
		 * @param factory a thread factory to create new threads
		 */
		public WorkerPool (int parallels, ThreadFactory factory)
				requires (0 < parallels)
		{
			_factory = factory;
			_threads = new ArrayList<WorkerThread>();
			_submission_queue = new WorkQueue();

			var sb = new StringBuilder("GpseqWorkerPool-");
			sb.append(next_pool_number().to_string()).append("-thread-");
			_thread_name_prefix = sb.str;

			init_threads(parallels);
		}

		~WorkerPool () {
			if (!is_terminated) {
				terminate_now();
			}
		}

		private void init_threads (int n) {
			for (int i = 0; i < n; i++) {
				WorkerThread t = new_thread();
				_threads.add(t);
			}
			foreach (WorkerThread t in _threads) {
				t.start();
			}
		}

		private WorkerThread new_thread () {
			return _factory.create_thread(this);
		}

		/**
		 * The number of threads.
		 *
		 * A thread may be deactivated if idle, and activated when a new task
		 * is submitted.
		 */
		public int parallels {
			get { return _threads.size; }
		}

		/**
		 * A read-only view of the threads in this pool.
		 */
		public Gee.List<WorkerThread> threads {
			owned get { return _threads.read_only_view; }
		}

		/**
		 * The thread factory to create new threads.
		 */
		public ThreadFactory factory {
			get { return _factory; }
		}

		/**
		 * The submission queue. when a task is submitted from the outside of
		 * worker threads, the task is queued in this queue.
		 */
		internal WorkQueue submission_queue {
			get { return _submission_queue; }
		}

		/**
		 * Submits a task.
		 *
		 * If the submission is happened in a worker thread, the task is queued
		 * in the work queue of the thread directly. otherwise, the task is
		 * queued in the submission queue of this pool, and the task will be
		 * taken by worker threads.
		 *
		 * This method does nothing if this pool has been terminating or
		 * terminated.
		 *
		 * @param task a task to execute
		 */
		public void submit (Task task) {
			if (is_terminating_started) return;
			WorkerThread? thread = WorkerThread.self();
			if (thread != null && thread.pool == this) {
				thread.push_task(task);
			} else {
				add_submission(task);
			}
			signal_new_task();
		}

		/**
		 * Submits a task to the submission queue of this pool.
		 * @param task a task to submit
		 */
		private void add_submission (Task task) {
			lock (_submission_queue) {
				_submission_queue.offer_tail(task);
			}
		}

		/**
		 * Wakes one or more threads up.
		 */
		private void signal_new_task () {
			_lock.lock();
			_cond.signal();
			_lock.unlock();
		}

		/**
		 * Deactivates the given thread.
		 * @param t a thread to deactivate
		 */
		private void block_idle (WorkerThread t) {
			_lock.lock();
			_cond.wait(_lock);
			_lock.unlock();
		}

		/**
		 * Top-level loop for worker threads
		 */
		internal void work (WorkerThread thread) {
			QueueBalancer bal = thread.balancer;
			int barrens = 0;
			while (true) {
				if (is_terminating_started) return;
				Task? pop = thread.work_queue.poll_tail();
				if (pop != null) {
					pop.compute();
					barrens = 0;
				} else {
					bal.no_tasks(thread);
					barrens++;
					if (barrens > MAX_THREAD_IDLE_ITERATIONS) {
						block_idle(thread);
						if (is_terminating_started) return;
						barrens = 0;
					}
					bal.scan(thread);
				}
			}
		}

		/**
		 * Gets the name for the given id.
		 */
		internal string thread_name (int id) {
			return _thread_name_prefix + id.to_string();
		}

		internal int next_thread_id () {
			while (true) {
				int oldval = _next_thread_id;
				int newval = (oldval > int.MAX - 1) ? 0 : oldval+1;
				if ( AtomicInt.compare_and_exchange(ref _next_thread_id, oldval, newval) ) {
					return oldval;
				}
			}
		}

		internal void dec_terminating () {
			AtomicInt.add(ref _terminating, -1);
		}

		/**
		 * Whether or not this pool has been terminating.
		 *
		 * true if {@link terminate} has been called and this pool has not yet
		 * been terminated, false otherwise.
		 */
		public bool is_terminating {
			get {
				return 0 < AtomicInt.get(ref _terminating);
			}
		}

		/**
		 * Whether or not this pool has been terminated.
		 */
		public bool is_terminated {
			get {
				return 0 == AtomicInt.get(ref _terminating);
			}
		}

		/**
		 * Whether or not {@link terminate} has been called.
		 */
		public bool is_terminating_started {
			get {
				return 0 <= AtomicInt.get(ref _terminating);
			}
		}

		/**
		 * Starts terminating threads.
		 *
		 * This method does not wait for all threads to complete termination.
		 *
		 * This method does nothing if this pool has been terminating or
		 * terminated.
		 */
		public void terminate () {
			if (AtomicInt.compare_and_exchange(ref _terminating, -1, _threads.size)) {
				_lock.lock();
				_cond.broadcast();
				_lock.unlock();
			}
		}

		/**
		 * Starts terminating threads and wait for all threads to complete
		 * termination.
		 */
		public void terminate_now () {
			terminate();
			wait_termination();
		}

		/**
		 * Blocks until all threads have completed termination.
		 * @see terminate
		 * @see wait_termination_until
		 */
		public void wait_termination () {
			while (!is_terminated) {
				Thread.yield();
			}
		}

		/**
		 * Blocks until either all threads have completed termination or
		 * //end_time// has passed.
		 * @param end_time the monotonic time to wait until
		 * @see terminate
		 * @see wait_termination
		 */
		public void wait_termination_until (int64 end_time) {
			while (!is_terminated && end_time > get_monotonic_time()) {
				Thread.yield();
			}
		}

		private class DefaultThreadFactory : Object, ThreadFactory {
			public WorkerThread create_thread (WorkerPool pool) {
				return new WorkerThread(pool);
			}
		}
	}
}
