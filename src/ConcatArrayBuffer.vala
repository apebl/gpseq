/* ConcatArrayBuffer.vala
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
	 * A concatenated array buffer.
	 */
	internal class ConcatArrayBuffer<G> : ArrayBuffer<G> {

		/**
		 * Concatenates the given array buffers.
		 *
		 * If the given //bufs// is empty, returns a new empty array buffer. Or
		 * if the //bufs// contains only one element, returns the element.
		 *
		 * @param bufs an array of array buffers
		 * @return a concatenated array buffer
		 */
		public static ArrayBuffer<G> concat_multiple<G> (ArrayBuffer<G>[] bufs) {
			ArrayBuffer<G>[] array = {};
			for (int i = 0; i < bufs.length - 1; i += 2) {
				array += new ConcatArrayBuffer<G>(bufs[i], bufs[i+1]);
			}
			if ((bufs.length % 2) != 0) {
				array += bufs[bufs.length - 1];
			}

			if (array.length == 0) {
				return new ArrayBuffer<G>({});
			} else if (array.length == 1) {
				return array[0];
			} else {
				return concat_multiple<G>(array);
			}
		}

		private ArrayBuffer<G> _left;
		private ArrayBuffer<G> _right;

		/**
		 * Creates a new concatenated array buffer.
		 * @param left the left input
		 * @param right the right input
		 */
		public ConcatArrayBuffer (ArrayBuffer<G> left, ArrayBuffer<G> right) {
			base({});
			if (left.size > int64.MAX - right.size) {
				error("Buffer exceeds max buffer size");
			}
			_left = left;
			_right = right;
		}

		public override int64 size {
			get {
				return _left.size + _right.size;
			}
		}

		public override bool foreach (ForallFunc<G> f) {
			if (!_left.foreach(f)) return false;
			if (!_right.foreach(f)) return false;
			return true;
		}

		public new override unowned G get (int64 index) {
			assert(0 <= index && index < size);
			if (index < _left.size) {
				return _left[index];
			} else {
				return _right[index - _left.size];
			}
		}

		public new override void set (int64 index, owned G item) {
			assert(0 <= index && index < size);
			if (index < _left.size) {
				_left[index] = item;
			} else {
				_right[index - _left.size] = item;
			}
		}

		public override ArrayBuffer<G> slice (int64 start, int64 stop) {
			if (start == 0 && stop == size) return this;
			assert(0 <= start && start <= size);
			assert(0 <= stop && stop <= size);
			int64 size_l = _left.size;
			if (start >= size_l) {
				return _right.slice(start - size_l, stop - size_l);
			} else if (stop <= size_l) {
				return _left.slice(start, stop);
			} else {
				ArrayBuffer<G> left = _left.slice(start, size_l);
				ArrayBuffer<G> right = _right.slice(0, stop - size_l);
				return new ConcatArrayBuffer<G>(left, right);
			}
		}
	}
}
