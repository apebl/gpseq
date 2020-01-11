/* ArraySpliterator.vala
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

namespace Gpseq {
	/**
	 * A spliterator of an array.
	 */
	public class ArraySpliterator<G> : Object, Spliterator<G> {
		private G[] _array;
		private int _index; // current index
		private int _stop; // zero-based index after the end

		/**
		 * Creates a new array spliterator.
		 * @param array a gpointer array
		 * @param start zero-based index of the begin
		 * @param stop zero-based index after the end
		 */
		public ArraySpliterator (owned G[] array, int start, int stop) {
			_array = (owned) array;
			_index = start - 1;
			_stop = stop;
		}

		public Spliterator<G>? try_split () {
			int mid = (_index + 1 + _stop) >> 1;
			if (_index + 1 >= mid) {
				return null;
			} else {
				SubArray<G> sub = new SubArray<G>(_array);
				SubArraySpliterator<G> result = new SubArraySpliterator<G>(sub, _index + 1, mid);
				_index = mid - 1;
				return result;
			}
		}

		public bool try_advance (Func<G> consumer) throws Error {
			if (estimated_size > 0) {
				consumer(_array[++_index]);
				return true;
			} else {
				return false;
			}
		}

		public int64 estimated_size {
			get {
				return _stop - (_index + 1);
			}
		}

		public bool is_size_known {
			get {
				return true;
			}
		}
	}
}
