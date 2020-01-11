/* ForEachTask.vala
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
	 * A fork-join task that performs a for-each operation.
	 */
	internal class ForEachTask<G> : SpliteratorTask<void*,G> {
		private unowned Func<G> _func;

		/**
		 * Creates a new for-each task.
		 *
		 * @param func a //non-interfering// function
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public ForEachTask (
				Func<G> func,
				Spliterator<G> spliterator, ForEachTask<G>? parent,
				int64 threshold, int max_depth, Executor executor)
		{
			base(spliterator, parent, threshold, max_depth, executor);
			_func = func;
		}

		protected override void* empty_result {
			owned get {
				assert_not_reached();
			}
		}

		protected override void* leaf_compute () throws Error {
			spliterator.each(_func);
			return null;
		}

		protected override void* merge_results (owned void* left, owned void* right) throws Error {
			return null;
		}

		protected override SpliteratorTask<void*,G> make_child (Spliterator<G> spliterator) {
			var task = new ForEachTask<G>(_func,
					spliterator, this, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}
	}
}
