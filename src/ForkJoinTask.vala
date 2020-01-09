/* ForkJoinTask.vala
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

namespace Gpseq {
	/**
	 * A base class for fork-join tasks that run within a worker pool.
	 *
	 * Note. Fork-join tasks are not reusable.
	 */
	public abstract class ForkJoinTask<G> : Object, Task<G> {
		private unowned ForkJoinTask<G>? _parent;

		private int64 _threshold;
		private int _max_depth;
		private int _depth;
		private Executor _executor;

		private Promise<G> _promise;
		private SharedResult<G> _shared_result;
		private AtomicBoolVal _cancelled;

		/**
		 * Creates a fork-join task.
		 *
		 * @param parent the parent of this task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		protected ForkJoinTask (
				ForkJoinTask<G>? parent,
				int64 threshold, int max_depth, Executor executor)
			requires (threshold > 0)
		{
			_parent = parent;
			_threshold = threshold;
			_max_depth = max_depth;
			_executor = executor;
			_promise = new Promise<G>();
			_shared_result = parent == null ? new SharedResult<G>() : parent._shared_result;
			_cancelled = new AtomicBoolVal();
		}

		/**
		 * Gets the parent of this task.
		 */
		public ForkJoinTask<G>? parent {
			get {
				return _parent;
			}
		}

		/**
		 * Gets the root task.
		 */
		public ForkJoinTask<G> root {
			get {
				unowned ForkJoinTask<G>? task = this;
				while (task.parent != null) {
					task = task.parent;
				}
				return task;
			}
		}

		/**
		 * Whether or not this task is root.
		 */
		public bool is_root {
			get {
				return _parent == null;
			}
		}

		/**
		 * The sequential computation threshold.
		 */
		public int64 threshold {
			get {
				return _threshold;
			}
		}

		/**
		 * The max task split depth. unlimited if negative
		 */
		public int max_depth {
			get {
				return _max_depth;
			}
		}

		/**
		 * The split depth of this task.
		 */
		public int depth {
			get {
				return _depth;
			}
			set {
				_depth = value;
			}
		}

		/**
		 * The executor that will invoke this task
		 */
		public Executor executor {
			get {
				return _executor;
			}
		}

		/**
		 * The promise to set a result of {@link future}.
		 */
		protected Promise<G> promise {
			get {
				return _promise;
			}
		}

		/**
		 * The fork-join result of this task.
		 */
		public Future<G> future {
			get {
				return _promise.future;
			}
		}

		/**
		 * Blocks until this task is done, and returns the task result.
		 * @throws Error an error occurred in the {@link future}
		 */
		public G join () throws Error {
			WorkerThread? t = WorkerThread.self();
			if (t == null) {
				return external_join();
			} else {
				t.task_join(this);
				return future.value;
			}
		}

		/**
		 * Blocks the non-fork-join-thread until this task is done.
		 * @throws Error an error occurred in the {@link future}
		 */
		private G external_join () throws Error {
			return future.wait();
		}

		/**
		 * Submits this task to the {@link executor}.
		 */
		public void fork () {
			_executor.submit(this);
		}

		/**
		 * Gets the shared result.
		 *
		 * All tasks share the same shared result instance with their root task.
		 */
		public SharedResult<G> shared_result {
			get {
				return _shared_result;
			}
		}

		/**
		 * Marks this task as cancelled.
		 */
		protected void cancel () {
			_cancelled.val = true;
		}

		/**
		 * Whether or not this task have been cancelled.
		 *
		 * A task is considered cancelled if it or any of its ancestors have
		 * been cancelled.
		 */
		protected bool is_cancelled {
			get {
				ForkJoinTask<G>? p = parent;
				bool cancelled = _cancelled.val;
				while (!cancelled && p != null) {
					cancelled = p._cancelled.val;
					p = p.parent;
				}
				return cancelled;
			}
		}

		/**
		 * {@inheritDoc}
		 */
		public abstract void compute ();

		public class SharedResult<G> {
			private const int INIT = 0;
			private const int PENDING = 1;
			private const int READY = 2;
			private const int ERROR = 3;

			private int _state;
			private G? _value;
			private Error? _error;

			/**
			 * Whether or not this is ready -- the value has been assigned or
			 * an error has been set.
			 */
			public bool ready {
				get {
					return PENDING < AtomicInt.get(ref _state);
				}
			}

			public G value {
				get {
					assert( READY == AtomicInt.get(ref _state) );
					return _value;
				}
				owned set {
					if ( AtomicInt.compare_and_exchange(ref _state, INIT, PENDING) ) {
						_value = (owned) value;
						bool cas_result = AtomicInt.compare_and_exchange(ref _state, PENDING, READY);
						assert(cas_result);
					}
				}
			}

			public Error? error {
				get {
					assert( PENDING < AtomicInt.get(ref _state) );
					return _error;
				}
				owned set {
					if ( AtomicInt.compare_and_exchange(ref _state, INIT, PENDING) ) {
						_error = (owned) value;
						bool cas_result = AtomicInt.compare_and_exchange(ref _state, PENDING, ERROR);
						assert(cas_result);
					}
				}
			}

			/**
			 * Sets the value or error to the promise.
			 *
			 * The ownership of the value or error is transferred to the
			 * promise, therefore this result should not be used after this
			 * method called.
			 */
			public void bake_promise (Promise<G> promise) {
				int state = AtomicInt.get(ref _state);
				assert(PENDING < state);
				if (state == READY) {
					promise.set_value((owned) _value);
				} else {
					promise.set_exception((owned) _error);
				}
			}
		}
	}
}
