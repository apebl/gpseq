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
	internal class ReduceTask<G> : ForkJoinTask<Optional<G>> {
		private Spliterator<G> _spliterator; // may be a Container
		private unowned CombineFunc<G> _accumulator;

		/**
		 * Creates a new reduce task.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ReduceTask (Spliterator<G> spliterator, CombineFunc<G> accumulator,
				int64 threshold, int max_depth, Executor executor) {
			base(threshold, max_depth, executor);
			_spliterator = spliterator;
			_accumulator = accumulator;
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
				ReduceTask<G> left = copy(split);
				left.fork();
				ReduceTask<G> right = copy(_spliterator);

				try {
					right.invoke();
					Optional<G> result_r = right.future.value;
					Optional<G> result_l = left.join();
					if (!result_l.is_present) {
						promise.set_value(result_r); // result_r also may be empty
					} else if (!result_r.is_present) {
						promise.set_value(result_l);
					} else {
						G result = _accumulator(result_l.value, result_r.value);
						promise.set_value( new Optional<G>.of(result) );
					}
				} catch (Error err) {
					promise.set_exception(err);
				}
			}
		}

		private void sequential_compute () {
			bool found = false;
			G? result = null;
			_spliterator.each(g => {
				if (!found) {
					found = true;
					result = g;
				} else {
					result = _accumulator(result, g);
				}
			});
			promise.set_value(found ? new Optional<G>.of(result) : new Optional<G>.empty());
		}

		private ReduceTask<G> copy (Spliterator<G> spliterator) {
			var task = new ReduceTask<G>(spliterator, _accumulator, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
