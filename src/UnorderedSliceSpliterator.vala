/* UnorderedSliceSpliterator.vala
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
	 * A slice spliterator that doesn't preserve order.
	 */
	internal class UnorderedSliceSpliterator<G> : Object, Spliterator<G> {
		private Spliterator<G> _spliterator; // may be a Container
		private bool _unlimited;
		private int64 _skip_threshold;
		private AtomicInt64Ref _permits;

		/**
		 * Creates a new unordered slice spliterator.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param skip the number of elements to skip
		 * @param limit maximum number of elements the spliterator may contain,
		 * or a negative value if unlimited
		 */
		public UnorderedSliceSpliterator (Spliterator<G> spliterator, int64 skip, int64 limit)
			requires (skip >= 0)
		{
			assert(limit < 0 || skip <= int64.MAX - limit);
			_spliterator = spliterator;
			_unlimited = limit < 0;
			_skip_threshold = _unlimited ? 0 : limit;
			_permits = new AtomicInt64Ref(_unlimited ? skip : skip + limit);
		}

		private UnorderedSliceSpliterator.from_parent (
				Spliterator<G> spliterator, UnorderedSliceSpliterator<G> parent) {
			_spliterator = spliterator;
			_unlimited = parent._unlimited;
			_skip_threshold = parent._skip_threshold;
			_permits = parent._permits;
		}

		public Spliterator<G>? try_split () {
			if (_permits.val == 0) return null;
			Spliterator<G>? spliter = _spliterator.try_split();
			return spliter == null ? null : new UnorderedSliceSpliterator<G>.from_parent(spliter, this);
		}

		public bool try_advance (Func<G> consumer) throws Error {
			while (_unlimited || _permits.val > 0) {
				G? temp = null;
				bool found = false;
				if ( !_spliterator.try_advance(g => { temp = g; found = true; }) ) {
					return false;
				} else if (found && acquire_permits(1) == 1) {
					consumer(temp);
					return true;
				}
			}
			return false;
		}

		public int64 estimated_size {
			get {
				if (_unlimited || 0 != _permits.val) {
					return _spliterator.estimated_size;
				} else {
					return 0;
				}
			}
		}

		public bool is_size_known {
			get {
				return _spliterator.is_size_known && 0 == _permits.val;
			}
		}

		/**
		 * Acquires permission to skip or process elements.
		 * @param num the number of elements that the caller has in hand
		 * @return the number of elements that should be processed. remaining
		 * elements should be discarded
		 */
		private int64 acquire_permits (int64 num)
			requires (num > 0)
		{
			int64 remainings = 0;
			int64 grabbings = 0;
			do {
				remainings = _permits.val;
				if (remainings == 0) {
					return _unlimited ? num : 0;
				} else {
					grabbings = int64.min(remainings, num);
				}
			} while (grabbings > 0 && !_permits.compare_and_exchange(remainings, remainings - grabbings));

			if (_unlimited) {
				return int64.max(0, num - grabbings);
			} else if (remainings > _skip_threshold) {
				return int64.max(0, grabbings - (remainings - _skip_threshold));
			} else {
				return grabbings;
			}
		}

		public void each (Func<G> f) throws Error {
			each_chunk(chunk => {
				for (int i = 0; i < chunk.length; i++) {
					f(chunk[i]);
				}
				return true;
			});
		}

		public bool each_chunk (EachChunkFunc<G> f) throws Error {
			bool result = true;
			_spliterator.each_chunk(chunk => {
				if (_permits.val > 0) {
					int len = chunk.length;
					int64 acquired = acquire_permits(len);
					if (acquired == 0) return true;
					result = f(chunk[0:acquired]);
					return result;
				} else if (_unlimited) {
					result = f(chunk);
					return result;
				} else {
					return false;
				}
			});
			return result;
		}
	}
}
