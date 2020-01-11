/* FoldTask.vala
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
	 * A fork-join task that performs a reduction operation.
	 */
	internal class FoldTask<A,G> : SpliteratorTask<A,G> {
		private unowned FoldFunc<A,G> _accumulator;
		private unowned CombineFunc<A> _combiner;
		private A _identity;

		/**
		 * Creates a new fold task.
		 *
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for accumulating
		 * @param combiner an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @param identity the identity value for the combiner function
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public FoldTask (
				FoldFunc<A,G> accumulator, CombineFunc<A> combiner, A identity,
				Spliterator<G> spliterator, FoldTask<A,G>? parent,
				int64 threshold, int max_depth, Executor executor) {
			base(spliterator, parent, threshold, max_depth, executor);
			_accumulator = accumulator;
			_combiner = combiner;
			_identity = identity;
		}

		protected override A empty_result {
			owned get {
				assert_not_reached();
			}
		}

		protected override A leaf_compute () throws Error {
			A result = _identity;
			spliterator.each(g => {
				result = _accumulator(g, result);
			});
			return result;
		}

		protected override A merge_results (owned A left, owned A right) throws Error {
			return _combiner((owned) left, (owned) right);
		}

		protected override SpliteratorTask<A,G> make_child (Spliterator<G> spliterator) {
			var task = new FoldTask<A,G>(
					_accumulator, _combiner, _identity,
					spliterator, this,
					threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
