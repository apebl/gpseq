/* AtomicInt64Ref.vala
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
	 * A int64 value that guarantees atomic update
	 */
	internal class AtomicInt64Ref {
		public int64 _val;

		public AtomicInt64Ref (int64 val = 0) {
			_val = val;
		}

		public int64 val {
			get {
				return atomic_int64_get(ref _val);
			}
			set {
				atomic_int64_set(ref _val, value);
			}
		}

		public bool compare_and_exchange (int64 oldval, int64 newval) {
			return atomic_int64_compare_and_exchange(ref _val, oldval, newval);
		}
	}
}
