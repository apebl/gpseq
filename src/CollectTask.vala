/* CollectTask.vala
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
	 * A fork-join task that performs a mutable reduction operation.
	 */
	internal class CollectTask<A,G> : SpliteratorTask<A,G> {
		private Collector<G,A,void*> _collector;

		/**
		 * Creates a new collect task.
		 *
		 * @param collector a collector
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public CollectTask (
				Collector<void*,A,G> collector,
				Spliterator<G> spliterator, CollectTask<A,G>? parent,
				int64 threshold, int max_depth, Executor executor) {
			base(spliterator, parent, threshold, max_depth, executor);
			_collector = collector;
		}

		protected override A empty_result {
			owned get {
				assert_not_reached();
			}
		}

		protected override A leaf_compute () throws Error {
			A result = _collector.create_accumulator();
			spliterator.each(g => {
				_collector.accumulate(g, result);
			});
			return result;
		}

		protected override A merge_results (owned A left, owned A right) throws Error {
			return _collector.combine((owned) left, (owned) right);
		}

		protected override SpliteratorTask<A,G> make_child (Spliterator<G> spliterator) {
			var task = new CollectTask<A,G>(
					_collector, spliterator,
					this, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
