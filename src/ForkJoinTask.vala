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

using Gee;

namespace Gpseq {
	/**
	 * A base class for fork-join tasks that run within a fork-join
	 * pool.
	 *
	 * Note. Instances of a fork-join task class are not reusable.
	 */
	public abstract class ForkJoinTask<G> : Object {
		private int64 _threshold;
		private int _max_depth;
		private int _depth;
		private Executor _executor;
		private Promise<G> _promise;

		/**
		 * Creates a fork-join task.
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ForkJoinTask (int64 threshold, int max_depth, Executor executor)
			requires (threshold > 0)
		{
			_threshold = threshold;
			_max_depth = max_depth;
			_executor = executor;
			_promise = new Promise<G>();
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
		 * Whether or not this task has been completed or an exception has been
		 * occurred.
		 */
		public bool is_done {
			get {
				return future.ready || future.exception != null;
			}
		}

		/**
		 * Blocks until this task is done, and returns the task result.
		 * @throws Error an error occurred in the {@link future}
		 */
		public G join () throws Error {
			ForkJoinThread? t = ForkJoinThread.self();
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
			try {
				return future.wait();
			} catch (FutureError err) {
				throw future.exception;
			}
		}

		/**
		 * Blocks until this task is done, and returns the task result.
		 *
		 * This method calls {@link GLib.error} instead of throwing a
		 * {@link GLib.Error}.
		 */
		public G join_quietly () {
			try {
				return join();
			} catch (Error err) {
				error("%s", err.message);
			}
		}

		/**
		 * Immediately performs the task computation.
		 * @throws Error an error occurred in the {@link future}
		 */
		public void invoke () throws Error { // no return to avoid generic
			compute();
			Error? err = future.exception;
			if (err != null) throw err;
		}

		/**
		 * Immediately performs the task computation.
		 *
		 * This method calls {@link GLib.error} instead of throwing a
		 * {@link GLib.Error}.
		 */
		public void invoke_quietly () {
			try {
				invoke();
			} catch (Error err) {
				error("%s", err.message);
			}
		}

		/**
		 * Submits this task to the {@link executor}.
		 */
		public void fork () {
			_executor.submit(this);
		}

		/**
		 * Computes and sets {@link ForkJoinTask.future} value.
		 */
		public abstract void compute ();
	}
}
