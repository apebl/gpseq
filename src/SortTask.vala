/* SortTask.vala
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
	 * A fork-join task that performs a sort operation.
	 */
	internal class SortTask<G> : ForkJoinTask<void*> {
		private SubArray<G> _array;
		private SubArray<G> _temp;
		private Comparator<G> _comparator;

		/**
		 * Creates a new sort task.
		 * @param array a sub array
		 * @param temp a temporary sub array used in the execution. its size
		 * must be //>= array.size// (//== array.size// is enough)
		 * @param comparator a comparator
		 * @param threshold sequential computation threshold
		 * @param max_depth max task split depth. unlimited if negative
		 * @param executor an executor that will invoke the task
		 */
		public SortTask (SubArray<G> array, SubArray<G> temp, Comparator<G> comparator,
				int64 threshold, int max_depth, Executor executor)
			requires (temp.size >= array.size)
		{
			base(threshold, max_depth, executor);
			_array = array;
			_temp = temp;
			_comparator = comparator;
		}

		public override void compute () {
			int size = _array.size;
			if (size <= threshold || 0 <= max_depth <= depth) {
				_comparator.sort_sub_array(_array); // timsort
				promise.set_value(null);
			} else {
				int mid = size >> 1;
				SubArray<G> left_array = _array.sub_array(0, mid);
				SubArray<G> left_temp = _temp.sub_array(0, mid);
				SortTask<G> left = copy(left_array, left_temp);
				left.fork();
				SubArray<G> right_array = _array.sub_array(mid, size);
				SubArray<G> right_temp = _temp.sub_array(mid, size);
				SortTask<G> right = copy(right_array, right_temp);

				try {
					right.invoke();
					left.join();
				} catch (Error err) {
					promise.set_exception(err);
					return;
				}
				merge(left, right);
				promise.set_value(null);
			}
		}

		private SortTask<G> copy (SubArray<G> array, SubArray<G> temp) {
			var task = new SortTask<G>(array, temp, _comparator, threshold, max_depth, executor);
			task.depth = depth + 1;
			return task;
		}

		private void merge (SortTask<G> left, SortTask<G> right) {
			SubArray<G> ary0 = left._array;
			SubArray<G> ary1 = right._array;

			unowned G a = ary0[ary0.size - 1];
			unowned G b = ary1[0];
			if (_comparator.compare(a, b) < 0) {
				return; // already sorted
			}

			MergeTask<G> task = new MergeTask<G>(ary0, ary1, _temp,
					_comparator, threshold, max_depth, executor);
			task.depth = depth;
			try {
				task.invoke();
			} catch (Error err) {
				promise.set_exception(err);
				return;
			}
			_array.copy(0, _temp, 0, _array.size);
		}

		private class MergeTask<G> : ForkJoinTask<void*> {
			private SubArray<G> _left;
			private SubArray<G> _right;
			private SubArray<G> _output;
			private Comparator<G> _comparator;

			public MergeTask (SubArray<G> left, SubArray<G> right,
					SubArray<G> output, Comparator<G> comparator,
					int64 threshold, int max_depth, Executor executor) {
				base(threshold, max_depth, executor);
				_left = left;
				_right = right;
				_output = output;
				_comparator = comparator;
			}

			private MergeTask<G> copy (SubArray<G> left, SubArray<G> right, SubArray<G> output) {
				var task = new MergeTask<G>(left, right, output, _comparator, threshold, max_depth, executor);
				task.depth = depth + 1;
				return task;
			}

			public override void compute () {
				SubArray<G> left = _left;
				SubArray<G> right = _right;
				int len_l = left.size;
				int len_r = right.size;

				if (len_l == 0) {
					promise.set_value(null);
				} else if (len_l + len_r <= threshold || 0 <= max_depth <= depth) {
					sequential_merge(left, right, _output);
					promise.set_value(null);
				} else {
					int q = (len_l-1) >> 1;
					int q2 = binary_search(left[q], right);
					int q3 = q + q2;
					_output[q3] = left[q];

					MergeTask<G> task = copy( left.sub_array(0, q), right.sub_array(0, q2), _output );
					task.fork();
					MergeTask<G> task2 = copy( left.sub_array(q+1, len_l), right.sub_array(q2, len_r), _output.sub_array(q3+1, _output.size) );

					try {
						task2.invoke();
						task.join();
					} catch (Error err) {
						promise.set_exception(err);
						return;
					}
					promise.set_value(null);
				}
			}

			private void sequential_merge (SubArray<G> left, SubArray<G> right, SubArray<G> output) {
				int l = 0; // left index
				int r = 0; // right index
				int o = 0; // output index
				int len_l = left.size;
				int len_r = right.size;
				while (l < len_l && r < len_r) {
					int cmp = _comparator.compare(left[l], right[r]);
					if (cmp <= 0) {
						output[o++] = left[l++];
					} else {
						output[o++] = right[r++];
					}
				}
				while (l < len_l) {
					output[o++] = left[l++];
				}
				while (r < len_r) {
					output[o++] = right[r++];
				}
			}

			private int binary_search (G find, SubArray<G> array) {
				int lo = 0;
				int hi = array.size;
				while (lo < hi) {
					int mid = (lo + hi) >> 1;
					unowned G item = array[mid];
					int cmp = _comparator.compare(find, item);
					if (cmp <= 0) {
						hi = mid;
					} else {
						lo = mid + 1;
					}
				}
				return hi;
			}
		}
	}
}
