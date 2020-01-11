/* IterateIterator.vala
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

using Gee;

namespace Gpseq {
	/**
	 * An iterator for {@link Seq.iterate}.
	 */
	// XXX Implement a spliterator instead of an iterator for data-owned consumer?
	internal class IterateIterator<G> : Object, Traversable<G>, Iterator<G> {
		private G _cur;
		private Gee.Predicate<G> _pred;
		private Gee.MapFunc<G,G> _next;
		private bool _first = true;
		private bool _finish;

		public IterateIterator (
				owned G seed,
				owned Gee.Predicate<G> pred,
				owned Gee.MapFunc<G,G> next) {
			_cur = (owned) seed;
			_pred = (owned) pred;
			_next = (owned) next;
		}

		public bool @foreach (ForallFunc<G> f) {
			if ( !_first && !f(_cur) ) return false;
			while (next()) {
				if ( !f(_cur) ) return false;
			}
			return true;
		}

		public bool read_only {
			get {
				return true;
			}
		}

		public bool valid {
			get {
				return !_first;
			}
		}

		public new G get () {
			assert(valid);
			return _cur;
		}

		public bool has_next () {
			return !_finish && ( _first || _pred(_next(_cur)) );
		}

		public bool next () {
			G g;
			if (_first) {
				_first = false;
				g = (owned) _cur;
			} else {
				g = _next(_cur);
			}
			if (!_pred(g)) {
				_finish = true;
				return false;
			}
			_cur = (owned) g;
			return true;
		}

		public void remove () {
			error("read-only iterator");
		}
	}
}
