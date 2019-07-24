/* SubArray.vala
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
	 * An unowned slice of an array.
	 */
	public class SubArray<G> : Object, Traversable<G>, Iterable<G> {
		private unowned G[] _data;

		/**
		 * Creates a new sub array with an unowned view of an array.
		 * @param data an unowned view of a gpointer array
		 */
		public SubArray (G[] data) {
			_data = data;
		}

		/**
		 * Creates a new sub array with another sub array.
		 * @param array a sub array
		 * @param start zero-based index of the begin of the slice
		 * @param stop zero-based index after the end of the slice
		 */
		public SubArray.from_sub_array (
				SubArray<G> array, int start, int stop) {
			_data = array._data[start:stop];
		}

		/**
		 * Gets the array data.
		 * @return the internal array
		 */
		public new unowned G[] get_data () {
			return _data;
		}

		/**
		 * The number of elements.
		 */
		public int size {
			get {
				return _data.length;
			}
		}

		public bool foreach (ForallFunc<G> f) {
			for (int i = 0, n = _data.length; i < n; i++) {
				if(!f(_data[i])) {
					return false;
				}
			}
			return true;
		}

		public new unowned G get (int index) {
			return _data[index];
		}

		public new void set (int index, owned G item) {
			_data[index] = (owned) item;
		}

		/**
		 * Sorts the elements by comparing with the specified compare function.
		 * The sort is stable.
		 *
		 * @param compare_func compare function to compare elements. if it is
		 * not specified, the result of
		 * {@link Gee.Functions.get_compare_func_for} is used
		 */
		public void sort (owned CompareDataFunc<G>? compare_func = null) {
			if (_data.length <= 1) return;
			if (compare_func == null) {
				compare_func = Functions.get_compare_func_for(typeof(G));
			}
			TimSort.sort_sub_array<G>(this, compare_func);
		}

		public Gee.Iterator<G> iterator () {
			return new Iterator<G>(this);
		}

		/**
		 * Copies the data from src into this.
		 * @param start zero-based index of this to store data
		 * @param src the data source to copy
		 * @param src_start zero-based index of the begin to copy
		 * @param count the number of elements to copy
		 */
		public void copy (int start, SubArray<G> src, int src_start, int count) {
			for (int i = 0; i < count; i++) {
				_data[start + i] = src._data[src_start + i];
			}
		}

		/**
		 * Copies the data from src into this.
		 * @param start zero-based index of this to store data
		 * @param src the data source to copy
		 * @param src_start zero-based index of the begin to copy
		 * @param count the number of elements to copy
		 */
		public void copy_array (int start, G[] src, int src_start, int count) {
			for (int i = 0; i < count; i++) {
				_data[start + i] = src[src_start + i];
			}
		}

		/**
		 * Creates a new sub array slice.
		 * @param start zero-based index of the begin of the slice
		 * @param stop zero-based index after the end of the slice
		 * @return the new sub array
		 */
		public SubArray<G> sub_array (int start, int stop) {
			return new SubArray<G>.from_sub_array(this, start, stop);
		}

		private class Iterator<G> : Object, Traversable<G>, Gee.Iterator<G>, BidirIterator<G> {
			private SubArray<G> _array;
			private int _index = -1;
			private bool _removed = false;

			public Iterator (SubArray<G> array) {
				_array = array;
			}

			public bool next () {
				if (_index + 1 < _array.size) {
					_index++;
					_removed = false;
					return true;
				}
				return false;
			}

			public bool has_next () {
				return (_index + 1 < _array.size);
			}

			public bool first () {
				if (_array.size == 0) return false;
				_index = 0;
				_removed =false;
				return true;
			}

			public new G get () {
				assert(!_removed);
				assert(_index >= 0);
				// assume(_index < _array.size);
				return _array[_index];
			}

			public void remove () {
				error("read-only iterator");
			}

			public bool previous () {
				if (_removed && _index >= 0) {
					_removed = false;
					return true;
				}
				if (_index > 0) {
					_index--;
					return true;
				}
				return false;
			}

			public bool has_previous () {
				return (_index > 0 || (_removed && _index >= 0));
			}

			public bool last () {
				if (_array.size == 0) {
					return false;
				}
				_index = _array.size - 1;
				return true;
			}

			public bool read_only {
				get {
					return false;
				}
			}

			public bool valid {
				get {
					return _index >= 0 && _index < _array.size && !_removed;
				}
			}

			public bool foreach (ForallFunc<G> f) {
				if (_index < 0 || _removed) {
					_index++;
				}
				while (_index < _array.size) {
					if (!f(_array[_index])) {
						return false;
					}
					_index++;
				}
				_index = _array.size - 1;
				return true;
			}
		}
	}
}
