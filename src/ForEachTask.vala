/* ForEachTask.vala
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
	 * A fork-join task that performs a for-each operation.
	 */
	internal class ForEachTask<G> : ForkJoinTask<void*> {
		private Spliterator<G> _spliterator;
		private unowned Func<G> _func;

		/**
		 * Creates a new for-each task.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param func a //non-interfering// function
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ForEachTask (Spliterator<G> spliterator, Func<G> func,
				int64 threshold, int max_depth, Executor executor)
		{
			base(threshold, max_depth, executor);
			_spliterator = spliterator;
			_func = func;
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
				ForEachTask<G> left = copy(split);
				left.fork();
				ForEachTask<G> right = copy(_spliterator);

				try {
					right.invoke();
					left.join();
				} catch (Error err) {
					promise.set_exception(err);
					return;
				}
				promise.set_value(null);
			}
		}

		private void sequential_compute () {
			_spliterator.each(_func);
			promise.set_value(null);
		}

		private ForEachTask<G> copy (Spliterator<G> spliterator) {
			var task = new ForEachTask<G>(spliterator, _func, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
