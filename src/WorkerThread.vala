/* WorkerThread.vala
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
	 * A worker thread.
	 */
	public class WorkerThread : Object {
		private const int MAX_THREAD_IDLE_ITERATIONS = 4;

		/**
		 * A table storing worker threads.
		 */
		private static Map<Thread, WorkerThread>? threads;

		/**
		 * Gets the worker thread corresponding to the given thread.
		 *
		 * @return the worker thread corresponding to the given Thread, or
		 * null if not found
		 */
		public static WorkerThread? get_by (Thread thread) {
			lock (threads) {
				if (threads == null) {
					threads = new HashMap<Thread, WorkerThread>();
				}
				return threads[thread];
			}
		}

		/**
		 * Gets the worker thread corresponding to the current thread.
		 *
		 * @return the worker thread corresponding to the current thread, or
		 * null if the current thread is not a worker thread
		 */
		public static WorkerThread? self () {
			return get_by(Thread.self<void*>());
		}

		/**
		 * Registers the worker thread.
		 */
		private static void set_thread (Thread k, WorkerThread v) {
			lock (threads) {
				if (threads == null) {
					threads = new HashMap<Thread, WorkerThread>();
				}
				threads[k] = v;
			}
		}

		/**
		 * Unregisters the worker thread corresponding to the given thread.
		 */
		private static void unset_thread (Thread k) {
			lock (threads) {
				if (threads == null) {
					threads = new HashMap<Thread, WorkerThread>();
				}
				threads.unset(k);
			}
		}

		private static void move_context (WorkerThread from, WorkerThread to) {
			lock (from._context) {
				lock (to._context) {
					assert(from._context != null);
					to._context = from._context;
					from._context = null;
					to._context.thread = to;
				}
			}
		}

		private unowned WorkerThread? _parent = null;
		private bool _blocked;
		private bool _seeking;

		private Thread<void*>? _thread = null; // also used to lock
		private unowned WorkerPool _pool;
		private WorkerContext _context;
		private string _name;
		private bool _terminated;

		/**
		 * Creates a new worker thread.
		 *
		 * @param pool a worker pool
		 */
		public WorkerThread (WorkerPool pool) {
			_pool = pool;
			_name = pool.thread_name( pool.next_thread_id() );
		}

		/**
		 * Creates a new slave worker thread.
		 *
		 * @param parent the parent
		 */
		internal WorkerThread.slave (WorkerThread parent) {
			this(parent.pool);
			_parent = parent;
			move_context(parent, this);
		}

		~WorkerThread () {
			unset_thread(_thread);
		}

		/**
		 * The parent of this thread.
		 */
		internal WorkerThread? parent {
			get {
				return _parent;
			}
		}

		/**
		 * Whether or not this thread is currently blocked.
		 */
		internal bool is_blocked {
			get {
				lock (_context) {
					return _blocked;
				}
			}
			set {
				lock (_context) {
					_blocked = value;
				}
			}
		}

		/**
		 * The internal thread object, or null if this worker thread has not
		 * yet started.
		 */
		public Thread<void*>? thread {
			get {
				lock (_thread) {
					return _thread;
				}
			}
		}

		/**
		 * The worker pool to which this thread belongs.
		 */
		public WorkerPool pool {
			get {
				return _pool;
			}
		}

		/**
		 * The worker context currently linked with this thread.
		 */
		internal WorkerContext? context {
			get {
				lock (_context) {
					return _context;
				}
			}
			set {
				lock (_context) {
					_context = value;
				}
			}
		}

		/**
		 * The name of this thread.
		 */
		public string name {
			get {
				return _name;
			}
		}

		/**
		 * Whether or not this thread has been started.
		 */
		public bool is_started {
			get {
				lock (_thread) {
					return _thread != null;
				}
			}
		}

		/**
		 * Whether or not this thread has been terminated.
		 */
		public bool is_terminated {
			get {
				lock (_thread) {
					return _terminated;
				}
			}
		}

		/**
		 * Whether or not this thread is alive. A thread is alive if it has been
		 * started and has not yet terminated.
		 */
		public bool is_alive {
			get {
				lock (_thread) {
					return _thread != null && !_terminated;
				}
			}
		}

		/**
		 * Starts this thread.
		 *
		 * @throws Error if a system thread can not be created, due to resource
		 * limits, etc.
		 */
		public void start () throws Error {
			lock (_thread) {
				lock (threads) {
					var thread = new Thread<void*>.try(_name, run);
					_thread = thread;
					set_thread(_thread, this);
				}
			}
		}

		/**
		 * Waits until this thread finishes.
		 *
		 * @see GLib.Thread.join
		 */
		public void join () {
			assert(is_started);
			_thread.join();
		}

		/**
		 * Runs the given blocking task and returns the result.
		 *
		 * This method tries to create a new thread.
		 *
		 * -> If succeed, the new thread takes the context of this thread and
		 * runs the remaining tasks in the context. This thread runs the
		 * blocking task and is marked as //blocked// until the task ends.
		 * After it ends, this thread is unblocked and takes the context back,
		 * and the new thread is terminated.
		 *
		 * -> If failed, e.g. the maximum number of threads exceeded, this
		 * method just runs the function without any further work.
		 *
		 * This method must be called in //this// thread.
		 *
		 * @param func a task function
		 * @return the result produced by the function
		 *
		 * @throws Error the error thrown by the function
		 *
		 * @see Gpseq.blocking
		 * @see Gpseq.blocking_get
		 */
		[Version (since="0.2.0-alpha")]
		public G blocking<G> (TaskFunc<G> func) throws Error {
			lock (_context) {
				if (_context == null) {
					return func();
				}
			}

			if ( !_pool.try_new_slave() ) {
				return func();
			}

			WorkerThread? slave;
			lock (_context) {
				_blocked = true;
				slave = new WorkerThread.slave(this);
			}

			_pool.add_slave((!)slave);
			try {
				((!)slave).start();
			} catch (Error err) {
				_pool.new_slave_failed((!)slave);
				move_context((!)slave, this);
			}
			slave = null;

			try {
				return func();
			} catch (Error err) {
				throw err;
			} finally {
				lock (_context) {
					_blocked = false;
				}
			}
		}

		/**
		 * Top-level loop for worker threads
		 */
		internal void work () {
			int barrens = 0;
			while (true) {
				if (_pool.is_terminating_started) return;

				WorkerContext? ctx;
				lock (_context) { ctx = _context; }
				if ( ctx == null || check_parent_released() ) {
					return;
				}

				Task? pop = ctx.work_queue.poll_tail();
				if (pop != null) {
					if (_seeking) {
						_seeking = false;
						_pool.signal_new_task(false);
					}
					pop.compute();
					barrens = 0;
				} else {
					QueueBalancer bal = ctx.balancer;
					bal.no_tasks(ctx);
					barrens++;
					if (barrens > MAX_THREAD_IDLE_ITERATIONS) {
						if (_parent == null) {
							_pool.block_idle(this);
							_seeking = true;
							if (_pool.is_terminating_started) return;
						}
						barrens = 0;
					}
					bal.scan(ctx);
				}
			}
		}

		/**
		 * Loop for task join.
		 */
		internal void task_join (Task task) throws Error {
			while (true) {
				if (task.future.ready) return;

				WorkerContext? ctx;
				lock (_context) { ctx = _context; }
				if ( ctx == null || check_parent_released() ) {
					Thread.yield();
					continue;
				}

				Task? pop = ctx.work_queue.poll_tail();
				if (pop != null) {
					pop.invoke();
					if (pop == task) return;
				} else {
					QueueBalancer bal = ctx.balancer;
					bal.no_tasks(ctx);
					bal.scan(ctx);
				}
			}
		}

		/**
		 * Thread loop function.
		 */
		private void* run () {
			work();
			lock (_thread) {
				_terminated = true;
			}
			_pool.thread_terminated(this);
			return null;
		}

		private inline bool check_parent_released () {
			if (_parent != null) {
				lock (_parent._context) {
					if (!_parent._blocked) {
						move_context(this, _parent);
						return true;
					}
				}
			}
			return false;
		}
	}
}
