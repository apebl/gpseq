/* ShortCircuitTask.vala
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
	 * A base class for fork-join tasks that performs a short-circuiting
	 * operation.
	 *
	 * A short-circuit task need to implement //leaf_compute()// instead of
	 * //compute()//.
	 *
	 * To get the final result of a short-circuit task, use //shared_result//
	 * instead of //future//.
	 */
	internal abstract class ShortCircuitTask<G,R> : ForkJoinTask<Optional<R>> {
		private Spliterator<G> _spliterator; // may be a Container
		private unowned ShortCircuitTask<G,R>? _parent;
		private ShortCircuitTask<G,R>? _left_child;
		private ShortCircuitTask<G,R>? _right_child;

		private AtomicObjectRef _shared_result;
		private AtomicBoolRef _canceled;

		/**
		 * Creates a new short-circuit task.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ShortCircuitTask (Spliterator<G> spliterator, ShortCircuitTask<G,R>? parent,
				int64 threshold, int max_depth, Executor executor) {
			base(threshold, max_depth, executor);
			_spliterator = spliterator;
			_parent = parent;
			if (parent == null) {
				_shared_result = new AtomicObjectRef(null);
			} else {
				_shared_result = parent._shared_result;
			}
			_canceled = new AtomicBoolRef();
		}

		/**
		 * The spliterator of this task.
		 */
		protected Spliterator<G> spliterator {
			get {
				return _spliterator;
			}
		}

		/**
		 * The parent of this task.
		 */
		protected ShortCircuitTask<G,R>? parent {
			get {
				return _parent;
			}
		}

		/**
		 * The left child of this task.
		 *
		 * If {@link right_child} is non-null, this is also non-null, but not
		 * vice versa. There is no similar rule applied to null.
		 */
		protected ShortCircuitTask<G,R>? left_child {
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
		protected ShortCircuitTask<G,R>? right_child {
			get {
				return _right_child;
			}
		}

		/**
		 * Clears children of this task.
		 */
		protected void clear_children () {
			_right_child = null; // must before left
			_left_child = null;
		}

		/**
		 * Whether or not this task is the root node.
		 */
		protected bool is_root {
			get {
				return _parent == null;
			}
		}

		/**
		 * Whether or not this task is a leaf node. a task is a leaf node if the
		 * task has no children.
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
				ShortCircuitTask<G,R>? cur = this;
				while (cur != null) {
					ShortCircuitTask<G,R> p = cur.parent;
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
		 * The shared result, or the local result of this task if the shared
		 * result has not yet been set.
		 */
		public Optional<R> shared_result {
			owned get {
				// the value could be changed only once
				Object? obj = _shared_result.val;
				if (null != obj) {
					return (Optional<R>) obj;
				} else {
					return future.value;
				}
			}
		}

		/**
		 * Whether or not the shared result has been set.
		 */
		protected bool is_shared_result_ready {
			get {
				return null != _shared_result.val;
			}
		}

		/**
		 * Returns an empty result indicating the computation completed with no
		 * task finding a result.
		 */
		protected abstract Optional<R> empty_result {
			owned get;
		}

		/**
		 * Sets shared result if it has not yet set, using compare-and-exchange.
		 */
		protected void short_circuit (Optional<R> result) {
			_shared_result.compare_and_exchange(null, result);
		}

		/**
		 * Marks this task as canceled.
		 */
		protected void cancel () {
			_canceled.val = true;
		}

		/**
		 * Whether or not this task have been canceled. A task is considered
		 * canceled if it or any of its ancestors have been canceled.
		 */
		protected bool is_canceled {
			get {
				ShortCircuitTask<G,R>? p = parent;
				bool canceled = _canceled.val;
				while (!canceled && p != null) {
					canceled = p._canceled.val;
					p = p.parent;
				}
				return canceled;
			}
		}

		/**
		 * Cancels all tasks which following this in the encounter order.
		 */
		protected void cancel_later_nodes () {
			ShortCircuitTask<G,R>? p = parent;
			ShortCircuitTask<G,R>? cur = this;
			while (p != null) {
				if (p.left_child == cur) {
					if (!p.right_child._canceled.val) {
						p.right_child.cancel();
					}
				}
				cur = p;
				p = p.parent;
			}
		}

		public override void compute () {
			if (is_shared_result_ready || is_canceled) {
				set_result(empty_result);
				return;
			}

			int64 size = _spliterator.estimated_size;
			if (0 <= size <= threshold || 0 <= max_depth <= depth) {
				Optional<R> result = leaf_compute();
				set_result(result);
			} else {
				var split = _spliterator.try_split();
				if (split == null) {
					Optional<R> result = leaf_compute();
					set_result(result);
					return;
				}
				_left_child = make_child(split); // must before right
				_right_child = make_child(_spliterator);
				_left_child.fork(); // must after both children have been created

				try {
					_right_child.invoke();
					Optional<R> result_r = _right_child.future.value;
					Optional<R> result_l = _left_child.join();
					Optional<R> result = merge_results(result_l, result_r);
					set_result(result);
				} catch (Error err) {
					promise.set_exception(err);
					return;
				}
			}
		}

		private void set_result (Optional<R> result) {
			_spliterator = null;
			promise.set_value(result);
		}

		/**
		 * Computes the result with a leaf node. this method will be called by
		 * {@link ShortCircuitTask.compute}
		 * @return a local result
		 */
		protected abstract Optional<R> leaf_compute ();

		/**
		 * Merges the results of the children of this task.
		 * @param the merged result
		 */
		protected abstract Optional<R> merge_results (Optional<R> left, Optional<R> right);

		/**
		 * Makes a child task. the depth of the child task should be
		 * //this.depth + 1//
		 */
		protected abstract ShortCircuitTask<G,R> make_child (Spliterator<G> spliterator);
	}
}
