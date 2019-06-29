/* ResultIterator.vala
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
	 * An iterator wrapping a {@link ResultSpliterator}.
	 */
	internal class ResultIterator<G> : Object, Traversable<G>, Iterator<G> {
		private ResultSpliterator<G> _spliterator;
		private G? _current;
		private bool _has_current;
		private G? _next;
		private bool _has_next;

		public ResultIterator (ResultSpliterator<G> spliterator) {
			_spliterator = spliterator;
		}

		public bool @foreach (ForallFunc<G> f) {
			if (valid && !f(_current)) return false;
			while (next()) {
				if (!f(_current)) return false;
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
				return _has_current;
			}
		}

		public new G @get () {
			assert(_has_current);
			return _current;
		}

		public bool has_next () {
			if (_has_next) {
				return true;
			} else {
				try {
					_has_next = _spliterator.try_advance(g => { _next = g; });
				} catch (Error err) {
					error("%s", err.message);
				}
				return _has_next;
			}
		}

		public bool next () {
			if (_has_next) {
				_current = _next;
				_has_current = true;
				_next = null;
				_has_next = false;
				return true;
			} else {
				try {
					_has_next = _spliterator.try_advance(g => { _next = g; });
				} catch (Error err) {
					error("%s", err.message);
				}
				if (_has_next) {
					return next();
				} else {
					return false;
				}
			}
		}

		public void remove () {
			error("read-only iterator");
		}
	}
}
