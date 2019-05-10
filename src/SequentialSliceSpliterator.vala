/* SequentialSliceSpliterator.vala
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
	 * A slice spliterator that will be executed sequentially.
	 */
	internal class SequentialSliceSpliterator<G> : Object, Spliterator<G> {
		private Spliterator<G> _spliterator; // may be a Container
		private int64 _skip;
		private int64 _limit;

		/**
		 * Creates a new sequential slice spliterator.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param skip the number of elements to skip
		 * @param limit maximum number of elements the spliterator may contain,
		 * or a negative value if unlimited
		 */
		public SequentialSliceSpliterator (Spliterator<G> spliterator, int64 skip, int64 limit)
			requires (skip >= 0)
		{
			_spliterator = spliterator;
			_skip = skip;
			_limit = limit;
		}

		public Spliterator<G>? try_split () {
			return null;
		}

		public bool try_advance (Func<G> consumer) {
			if (_limit == 0) return false;
			return _spliterator.try_advance(g => {
				if (_skip > 0) {
					_skip--;
				} else if (_limit != 0) {
					if (_limit > 0) _limit--;
					consumer(g);
				}
			});
		}

		public int64 estimated_size {
			get {
				if (_limit != 0) {
					int64 size = _spliterator.estimated_size;
					if (size < 0) return size;
					size -= _skip;
					if (size < 0) size = 0;
					else if (_limit > 0 && size > _limit) size = _limit;
					return size;
				} else {
					return 0;
				}
			}
		}

		public bool is_size_known {
			get {
				return (_spliterator.is_size_known && _spliterator.estimated_size >= 0) || _limit == 0;
			}
		}

		public void each (Func<G> f) {
			each_chunk(chunk => {
				for (int i = 0; i < chunk.length; i++) {
					f(chunk[i]);
				}
				return true;
			});
		}

		public bool each_chunk (EachChunkFunc<G> f) {
			if (_limit == 0) return true;
			bool result = true;
			_spliterator.each_chunk(chunk => {
				// XXX This assumes chunk.length <= int64.MAX
				int len = chunk.length;
				int64 skip = _skip;
				int64 s = (int64)(skip - len);
				_skip = int64.max(0, s);
				if (s >= 0) return true;
				else if (_limit == 0) return false;
				else if (_limit > 0) {
					int64 l = (int64)(len - skip);
					if (l > _limit) l = _limit;
					_limit -= l;
					result = f(chunk[skip:skip+l]);
					return result;
				} else {
					result = f(chunk[skip:len]);
					return result;
				}
			});
			return result;
		}
	}
}
