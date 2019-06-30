/* SpliteratorTask.vala
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
	 * A base class for spliterator based fork-join tasks.
	 */
	public abstract class SpliteratorTask<R,G> : ForkJoinTask<R> {
		private Spliterator<G>? _spliterator; // may be a Container
		private SpliteratorTask<R,G>? _left_child;
		private SpliteratorTask<R,G>? _right_child;

		/**
		 * Creates a spliterator task.
		 *
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of this task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public SpliteratorTask (
				Spliterator<G> spliterator, SpliteratorTask<R,G>? parent,
				int64 threshold, int max_depth, Executor executor)
		{
			base(parent, threshold, max_depth, executor);
			_spliterator = spliterator;
		}

		protected Spliterator<G> spliterator {
			get {
				return _spliterator;
			}
		}

		/**
		 * The left child of this task.
		 *
		 * If {@link right_child} is non-null, this is also non-null, but not
		 * vice versa. There is no similar rule applied to null.
		 */
		protected SpliteratorTask<R,G>? left_child {
			get {
				return _left_child;
			}
		}

		/**
		 * The right child of this task.
		 *
		 * If this is non-null, {@link left_child} is also non-null, but not
		 * vice versa. There is no similar rule applied to null.
		 */
		protected SpliteratorTask<R,G>? right_child {
			get {
				return _right_child;
			}
		}

		/**
		 * Whether or not this task is a leaf node.
		 *
		 * A task is a leaf node if it has no children.
		 */
		protected bool is_leaf {
			get {
				return _left_child == null || _right_child == null;
			}
		}

		/**
		 * Whether or not the path from the root to this involves only left
		 * child of each node.
		 */
		protected bool is_leftmost {
			get {
				ForkJoinTask<G>? cur = this;
				while (cur != null) {
					SpliteratorTask<R,G>? p = (SpliteratorTask<R,G>?) cur.parent;
					if (p != null && p.left_child != cur) {
						return false;
					} else {
						cur = p;
					}
				}
				return true;
			}
		}

		/**
		 * Cancels all tasks which following this in the encounter order.
		 */
		protected void cancel_later_nodes () {
			SpliteratorTask<R,G>? p = (SpliteratorTask<R,G>?) parent;
			SpliteratorTask<R,G>? cur = this;
			while (p != null) {
				if (p.left_child == cur) {
					p.right_child.cancel();
				}
				cur = p;
				p = (SpliteratorTask<R,G>?) p.parent;
			}
		}

		/**
		 * Gets an empty result.
		 *
		 * When the {@link shared_result} is already ready, this task has been
		 * cancelled, this task throws an error and the task is not root, or
		 * a class that inherits this class needs, the empty result is used and
		 * set to the promise of this task.
		 */
		protected abstract R empty_result {
			owned get;
		}

		protected override void compute () {
			if (shared_result.ready || is_cancelled) {
				set_value(empty_result);
				return;
			}

			int64 size = _spliterator.estimated_size;
			if (0 <= size <= threshold || 0 <= max_depth <= depth) {
				try {
					R result = leaf_compute();
					set_value((owned) result);
				} catch (Error err) {
					set_error((owned) err);
				}
			} else {
				var split = _spliterator.try_split();
				if (split == null) {
					try {
						R result = leaf_compute();
						set_value((owned) result);
					} catch (Error err) {
						set_error((owned) err);
					}
					return;
				}
				_left_child = make_child(split); // must before right
				_right_child = make_child(_spliterator);
				_left_child.fork(); // must after both children have been created

				try {
					_right_child.invoke();
					R result_r = _right_child.future.value;
					R result_l = _left_child.join();

					if (is_root && shared_result.ready) {
						_spliterator = null;
						shared_result.bake_promise(promise);
					} else {
						R result = merge_results((owned) result_l, (owned) result_r);
						set_value((owned) result);
					}
				} catch (Error err) {
					set_error((owned) err);
				} finally {
					_right_child = null; // must before left
					_left_child = null;
				}
			}
		}

		/**
		 * Computes this leaf node task.
		 *
		 * This method will be called by compute() if this task is a leaf node.
		 *
		 * You should override this method instead of {@link compute}.
		 */
		protected abstract R leaf_compute () throws Error;

		/**
		 * Merges the left and right result, then returns the merged result.
		 */
		protected abstract R merge_results (owned R left, owned R right) throws Error;

		/**
		 * Creates a child task with the given spliterator.
		 */
		protected abstract SpliteratorTask<R,G> make_child (Spliterator<G> spliterator);

		private void set_value (owned R value) {
			_spliterator = null;
			if (is_root && shared_result.ready) {
				shared_result.bake_promise(promise);
			} else {
				promise.set_value((owned) value);
			}
		}

		private void set_error (owned Error? error) {
			_spliterator = null;
			if (is_root) {
				promise.set_exception((owned) error);
			} else {
				shared_result.error = (owned) error;
				promise.set_value(empty_result);
			}
		}
	}
}
