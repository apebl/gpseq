/* MatchTask.vala
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
	 * A fork-join task that performs a match operation.
	 */
	internal class MatchTask<G> : SpliteratorTask<bool?,G> {
		private const long CHECK_INTERVAL = 32768; // 1 << 15

		private unowned Predicate<G> _pred;
		private Option _option;

		/**
		 * Creates a new match task.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @param option a match option.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new task
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public MatchTask (
				Predicate<G> pred, Option option,
				Spliterator<G> spliterator, MatchTask<G>? parent,
				int64 threshold, int max_depth, Executor executor)
		{
			base(spliterator, parent, threshold, max_depth, executor);
			_pred = pred;
			_option = option;
		}

		protected override bool? empty_result {
			owned get {
				return !_option.get_short_circuit_result();
			}
		}

		protected override bool? leaf_compute () throws Error {
			bool found = false;
			long chk = 0;
			spliterator.each_chunk(chunk => {
				for (int i = 0; i < chunk.length; i++) {
					if(_pred(chunk[i]) == _option.get_short_circuit_result()) {
						found = true;
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

			if (found) {
				shared_result.value = _option.get_short_circuit_result();
			}
			return empty_result;
		}

		protected override bool? merge_results (
				owned bool? left, owned bool? right) throws Error {
			return left;
		}

		protected override SpliteratorTask<bool?,G> make_child (Spliterator<G> spliterator) {
			var task = new MatchTask<G>(
					_pred, _option,
					spliterator, this,
					threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}

		public enum Option {
			ANY,
			ALL;

			public bool get_short_circuit_result () {
				switch (this) {
					case ANY:
						return true;
					case ALL:
						return false;
					default:
						assert_not_reached();
				}
			}
		}
	}
}
