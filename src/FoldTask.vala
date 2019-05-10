/* FoldTask.vala
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
	 * A fork-join task that performs a reduction operation.
	 */
	internal class FoldTask<A,G> : ForkJoinTask<A> {
		private Spliterator<G> _spliterator; // may be a Container
		private unowned FoldFunc<A,G> _accumulator;
		private unowned CombineFunc<A> _combiner;
		private A _identity;

		/**
		 * Creates a new fold task.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for accumulating
		 * @param combiner an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @param identity the identity value for the combiner function
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public FoldTask (Spliterator<G> spliterator,
				FoldFunc<A,G> accumulator, CombineFunc<A> combiner, A identity,
				int64 threshold, int max_depth, Executor executor) {
			base(threshold, max_depth, executor);
			_spliterator = spliterator;
			_accumulator = accumulator;
			_combiner = combiner;
			_identity = identity;
		}

		public override void compute () {
			int64 size = _spliterator.estimated_size;
			if (0 <= size <= threshold || 0 <= max_depth <= depth) {
				sequential_compute();
			} else {
				Spliterator<G>? split = _spliterator.try_split();
				if (split == null) {
					sequential_compute();
					return;
				}
				FoldTask<A,G> left = copy(split);
				left.fork();
				FoldTask<A,G> right = copy(_spliterator);

				try {
					right.invoke();
					A result_r = right.future.value;
					A result_l = left.join();
					A result = _combiner(result_l, result_r);
					promise.set_value(result);
				} catch (Error err) {
					promise.set_exception(err);
				}
			}
		}

		private void sequential_compute () {
			A result = _identity;
			_spliterator.each(g => {
				result = _accumulator(g, result);
			});
			promise.set_value(result);
		}

		private FoldTask<A,G> copy (Spliterator<G> spliterator) {
			var task = new FoldTask<A,G>(spliterator, _accumulator, _combiner, _identity, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
