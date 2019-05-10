/* AtomicObjectRef.vala
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
	 * An object value that guarantees atomic update
	 */
	internal class AtomicObjectRef : Object {
		private Object? _val;

		public AtomicObjectRef (Object? val) {
			_val = val;
		}

		public Object? val {
			get {
				return (Object?) AtomicPointer.get(&_val);
			}
			set {
				while (true) {
					Object? oldval = _val;
					if (compare_and_exchange(oldval, value)) break;
				}
			}
		}

		public bool compare_and_exchange (Object? oldval, Object? newval) {
			if (AtomicPointer.compare_and_exchange(&_val, oldval, newval)) {
				if (newval != null) newval.ref();
				if (oldval != null) oldval.unref();
				return true;
			}
			return false;
		}
	}
}
