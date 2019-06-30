/* ReduceTask.vala
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
	 * A fork-join task that performs a reduction operation.
	 */
	internal class ReduceTask<G> : SpliteratorTask<Optional<G>,G> {
		private unowned CombineFunc<G> _accumulator;

		/**
		 * Creates a new reduce task.
		 *
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ReduceTask (
				CombineFunc<G> accumulator,
				Spliterator<G> spliterator, ReduceTask<G>? parent,
				int64 threshold, int max_depth, Executor executor) {
			base(spliterator, parent, threshold, max_depth, executor);
			_accumulator = accumulator;
		}

		protected override Optional<G> empty_result {
			owned get {
				assert_not_reached();
			}
		}

		protected override Optional<G> leaf_compute () throws Error {
			bool found = false;
			G? result = null;
			spliterator.each(g => {
				if (!found) {
					found = true;
					result = g;
				} else {
					result = _accumulator(result, g);
				}
			});
			return found ? new Optional<G>.of(result) : new Optional<G>.empty();
		}

		protected override Optional<G> merge_results
				(owned Optional<G> left, owned Optional<G> right) throws Error {
			if (!left.is_present) {
				return right; // right also may be empty
			} else if (!right.is_present) {
				return left;
			} else {
				G result = _accumulator(left.value, right.value);
				return new Optional<G>.of(result);
			}
		}

		protected override SpliteratorTask<Optional<G>,G> make_child (Spliterator<G> spliterator) {
			var task = new ReduceTask<G>(
					_accumulator,
					spliterator, this,
					threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
