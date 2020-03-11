/* WorkerPool.vala
 *
 * Copyright (C) 2019-2020  Космическое П. (kosmospredanie@yandex.ru)
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
		private const int DEFAULT_MAX_THREADS = 8192;

		private static ThreadFactory? default_factory = null;

		/**
		 * Gets the default thread factory. the factory is constructed when this
		 * method is called initially.
		 *
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

		private int _max_threads;
		private int _num_threads; // masters + slaves
		private ThreadFactory _factory;
		private Gee.List<WorkerContext> _contexts;
		private Gee.List<WorkerThread> _threads; // master threads
		private Gee.Set<WorkerThread> _slaves;

		private int _seekers; // AtomicInt

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
		 *
		 * @throws Error if threads can not be created, due to resource limits,
		 * etc.
		 */
		public WorkerPool.with_defaults () throws Error
		{
			// try 2x processors
			uint processors = GLib.get_num_processors();
			processors = uint.max(processors, processors * 2);
			processors = uint.min(int.MAX, processors);
			this( (int) processors, get_default_factory() );
		}

		/**
		 * Creates a new worker pool.
		 *
		 * @param parallels the number of threads
		 * @param factory a thread factory to create new threads
		 *
		 * @throws Error if threads can not be created, due to resource limits,
		 * etc.
		 */
		public WorkerPool (int parallels, ThreadFactory factory) throws Error
				requires (0 < parallels)
		{
			_max_threads = int.max(parallels, DEFAULT_MAX_THREADS);
			_factory = factory;
			_contexts = new ArrayList<WorkerContext>();
			_threads = new ArrayList<WorkerThread>();
			_slaves = new HashSet<WorkerThread>();
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

		private void init_threads (int n) throws Error {
			_num_threads = n;
			for (int i = 0; i < n; i++) {
				WorkerContext ctx = new WorkerContext(this);
				WorkerThread t = new_thread();
				t.context = ctx;
				_contexts.add(ctx);
				_threads.add(t);
			}

			int success = 0;
			try {
				foreach (WorkerThread t in _threads) {
					t.start();
					success++;
				}
			} catch (Error err) {
				terminate_n(success);
				wait_termination();
				throw err;
			}
		}

		private WorkerThread new_thread () {
			return _factory.create_thread(this);
		}

		public int parallels {
			get { return _threads.size; }
		}

		/**
		 * The maximum number of threads that this pool can use.
		 *
		 * The actual limit may be less than this value, due to resource limits.
		 *
		 * This value is always >= {@link parallels}.
		 */
		[Version (since="0.2.0-alpha")]
		public int max_threads {
			get {
				return AtomicInt.get(ref _max_threads);
			}
			set {
				assert(value >= parallels);
				AtomicInt.set(ref _max_threads, value);
			}
		}

		/**
		 * The current number of threads.
		 */
		[Version (since="0.2.0-alpha")]
		public int num_threads {
			get {
				return AtomicInt.get(ref _num_threads);
			}
		}

		/**
		 * The thread factory to create new threads.
		 */
		public ThreadFactory factory {
			get { return _factory; }
		}

		/**
		 * A read-only view of the contexts in this pool.
		 */
		internal Gee.List<WorkerContext> contexts {
			owned get { return _contexts.read_only_view; }
		}

		internal int seekers {
			get {
				return AtomicInt.get(ref _seekers);
			}
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
			WorkerContext? ctx;
			if (thread != null && thread.pool == this) {
				ctx = thread.context;
				if (ctx != null) {
					ctx.work_queue.offer_tail(task);
				} else {
					add_submission(task);
				}
			} else {
				add_submission(task);
			}
			signal_new_task(true);
		}

		/**
		 * Submits a task to the submission queue of this pool.
		 *
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
		internal void signal_new_task (bool check_seekers) {
			if (!check_seekers || 0 == AtomicInt.get(ref _seekers)) {
				_lock.lock();
				_cond.signal();
				_lock.unlock();
			}
		}

		/**
		 * Deactivates the given thread.
		 *
		 * @param t a thread to deactivate
		 */
		internal void block_idle (WorkerThread t) {
			_lock.lock();
			_cond.wait(_lock);
			_lock.unlock();
		}

		internal void begin_seeking () {
			AtomicInt.add(ref _seekers, 1);
		}

		internal void end_seeking () {
			AtomicInt.add(ref _seekers, -1);
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

		internal void thread_terminated (WorkerThread thread) {
			AtomicInt.add(ref _num_threads, -1);
			lock (_slaves) {
				_slaves.remove(thread);
			}
			while (true) {
				int terminating = AtomicInt.get(ref _terminating);
				if (terminating <= 0) break;
				if ( AtomicInt.compare_and_exchange(ref _terminating, terminating, terminating-1) ) {
					break;
				}
			}
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
			int num = AtomicInt.get(ref _num_threads);
			terminate_n(num);
		}

		/**
		 * Starts terminating N threads.
		 *
		 * @param num the number of threads to terminate
		 */
		private void terminate_n (int num) {
			if ( AtomicInt.compare_and_exchange(ref _terminating, -1, num) ) {
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
		 *
		 * @param end_time the monotonic time to wait until
		 * @see terminate
		 * @see wait_termination
		 */
		public void wait_termination_until (int64 end_time) {
			while (!is_terminated && end_time > get_monotonic_time()) {
				Thread.yield();
			}
		}

		internal bool try_new_slave () {
			while (true) {
				int num = AtomicInt.get(ref _num_threads);
				if (num >= max_threads) return false;
				if ( AtomicInt.compare_and_exchange(ref _num_threads, num, num+1) ) {
					return true;
				}
			}
		}

		internal void add_slave (WorkerThread thread) {
			lock (_slaves) {
				bool changed = _slaves.add(thread);
				assert(changed);
			}
		}

		internal void new_slave_failed (WorkerThread thread) {
			AtomicInt.add(ref _num_threads, -1);
			lock (_slaves) {
				_slaves.remove(thread);
			}
		}

		private class DefaultThreadFactory : Object, ThreadFactory {
			public WorkerThread create_thread (WorkerPool pool) {
				return new WorkerThread(pool);
			}
		}
	}
}
