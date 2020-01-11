/* EmptySpliterator.vala
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
	 * An empty spliterator.
	 */
	internal class EmptySpliterator<G> : Object, Spliterator<G> {
		/**
		 * Creates a new empty spliterator.
		 */
		public EmptySpliterator () {
		}

		public Spliterator<G>? try_split () {
			return null;
		}

		public bool try_advance (Func<G> consumer) throws Error {
			return false;
		}

		public int64 estimated_size {
			get {
				return 0;
			}
		}

		public bool is_size_known {
			get {
				return true;
			}
		}
	}
}
