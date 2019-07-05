/* IteratorSpliterator.vala
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
	 * A spliterator of an iterator.
	 */
	public class IteratorSpliterator<G> : Object, Spliterator<G> {
		private const int BATCH_INCR_UNIT = 1024; // 1 << 10
		private const long TRY_MAX_BATCH_SIZE = 16777216; // 1 << 24

		private static int max_batch_size;
		private static int get_max_batch_size () {
			/* no synchronization required for this method;
			 * the method always returns the same value on the same device
			 */
			if (max_batch_size == 0) {
				long min = long.min(MAX_ARRAY_LENGTH, TRY_MAX_BATCH_SIZE);
				max_batch_size = (int) min;
			}
			return max_batch_size;
		}

		private Iterator<G> _iterator;
		private int64 _estimated_size;
		private bool _size_known;
		private int _batch;
		private bool _first = true;

		/**
		 * Creates a new iterator spliterator.
		 * @param iterator an iterator
		 * @param estimated_size the estimated size of the iterator, or negative
		 * if infinite, unknown, etc. If the given iterator points at some
		 * element it is included in this size.
		 * @param size_known true if //estimated_size// is an accurate size,
		 * false otherwise.
		 */
		public IteratorSpliterator (Iterator<G> iterator,
				int64 estimated_size, bool size_known) {
			_iterator = iterator;
			_estimated_size = estimated_size;
			_size_known = size_known;
		}

		/**
		 * Creates a new iterator spliterator with the given collection.
		 * @param collection a collection
		 */
		public IteratorSpliterator.from_collection (Collection<G> collection) {
			this(collection.iterator(), collection.size, true);
		}

		public Spliterator<G>? try_split () {
			if ( (!_size_known || _estimated_size != 0) && _iterator.has_next() ) {
				int n;
				if (_estimated_size > 0) {
					int64 half = _estimated_size >> 1;
					n = half <= MAX_ARRAY_LENGTH ? (int)half : MAX_ARRAY_LENGTH;
				} else {
					n = _batch + BATCH_INCR_UNIT;
					if (n < 0 || n > get_max_batch_size()) {
						n = get_max_batch_size();
					}
				}

				G[] array = new G[n];
				int i = 0;
				if (_first && _iterator.valid) {
					array[i++] = _iterator.get();
				}
				_first = false;
				while (i < n && _iterator.next()) {
					array[i++] = _iterator.get();
				}
				_batch = i; // increasing batch size

				if (_estimated_size > 0) {
					_estimated_size = int64.max(0, _estimated_size - i);
				}
				array.resize(i);
				return new ArraySpliterator<G>((owned) array, 0, i);
			} else {
				return null;
			}
		}

		public bool try_advance (Func<G> consumer) throws Error {
			if (_first && _iterator.valid) {
				consumer(_iterator.get());
				_first = false;
				return true;
			} else if (_iterator.next()) {
				consumer(_iterator.get());
				_first = false;
				return true;
			} else {
				return false;
			}
		}

		public int64 estimated_size {
			get {
				return _estimated_size;
			}
		}

		public bool is_size_known {
			get {
				return _size_known;
			}
		}
	}
}
