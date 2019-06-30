/* FindTask.vala
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
	 * A fork-join task that performs a find operation.
	 */
	internal class FindTask<G> : SpliteratorTask<Optional<G>,G> {
		private const long CHECK_INTERVAL = 32768; // 1 << 15

		private unowned Predicate<G> _pred;
		private Option _option;

		/**
		 * Creates a new find task.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @param option a search option
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public FindTask (
				Predicate<G> pred, Option option,
				Spliterator<G> spliterator, FindTask<G>? parent,
				int64 threshold, int max_depth, Executor executor)
		{
			base(spliterator, parent, threshold, max_depth, executor);
			_pred = pred;
			_option = option;
		}

		protected override Optional<G> empty_result {
			owned get {
				return new Optional<G>.empty();
			}
		}

		protected override Optional<G> leaf_compute () throws Error {
			Optional<G>? result = null;
			long chk = 0;
			spliterator.each_chunk(chunk => {
				for (int i = 0; i < chunk.length; i++) {
					if(_pred(chunk[i])) {
						result = new Optional<G>.of(chunk[i]);
						return false;
					}
				}
				chk += chunk.length;
				if (chk > CHECK_INTERVAL) {
					chk = 0;
					if (shared_result.ready || is_cancelled) {
						return false;
					}
				}
				return true;
			});

			if (result != null) {
				local_result_found(result);
				return result;
			}
			return empty_result;
		}

		protected override Optional<G> merge_results (
				owned Optional<G> left, owned Optional<G> right) throws Error {
			if (left.is_present) {
				local_result_found(left);
				return left;
			} else if (right.is_present){
				local_result_found(right);
				return right;
			} else {
				return left; // empty
			}
		}

		protected override SpliteratorTask<Optional<G>,G> make_child (Spliterator<G> spliterator) {
			var task = new FindTask<G>(
					_pred, _option,
					spliterator, this,
					threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}

		private void local_result_found (Optional<G> result) {
			if (is_leftmost || _option == Option.ANY) {
				shared_result.value = result;
			} else {
				cancel_later_nodes();
			}
		}

		public enum Option {
			ANY,
			FIRST
		}
	}
}
