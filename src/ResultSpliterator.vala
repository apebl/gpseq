/* ResultSpliterator.vala
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
	 * A spliterator wrapping a {@link Container}.
	 */
	internal class ResultSpliterator<G> : Object, Spliterator<G> {
		private Spliterator<G>? _spliterator; // may be a Container
		private Seq<G>? _seq;
		private bool _is_parallel;

		/**
		 * Creates a new result spliterator.
		 * @param container a container
		 * @param seq the seq that has produced the container
		 */
		public ResultSpliterator (Container<G,void*> container, Seq<G> seq) {
			_spliterator = container;
			_seq = seq;
			_is_parallel = _seq.is_parallel;
		}

		private ResultSpliterator.from_split (Spliterator<G> spliterator) {
			_spliterator = spliterator;
		}

		public Spliterator<G>? try_split () {
			if (_spliterator == null) return null;
			if (!_is_parallel) return null;
			check_traversal();
			Spliterator<G>? split = _spliterator.try_split();
			if (split == null) {
				return null;
			} else {
				return new ResultSpliterator<G>.from_split(split);
			}
		}

		public bool try_advance (Func<G> consumer) {
			if (_spliterator == null) return false;
			check_traversal();
			G? item = null;
			bool found = false;
			Func<G> func = (g) => {
				item = g;
				found = true;
			};
			while (_spliterator.try_advance(func)) {
				if (found) {
					consumer(item);
					return true;
				}
			}
			_spliterator = null;
			return false;
		}

		public int64 estimated_size {
			get {
				if (_spliterator == null) return 0;
				check_traversal();
				return _spliterator.estimated_size;
			}
		}

		public bool is_size_known {
			get {
				if (_spliterator == null) return true;
				check_traversal();
				return _spliterator.is_size_known;
			}
		}

		public void each (Func<G> f) {
			if (_spliterator == null) return;
			check_traversal();
			_spliterator.each(f);
			_spliterator = null;
		}

		public bool each_chunk (EachChunkFunc<G> f) {
			if (_spliterator == null) return true;
			check_traversal();
			bool result = _spliterator.each_chunk(f);
			_spliterator = null;
			return result;
		}

		private inline void check_traversal () {
			if (_seq != null) {
				((Container<G,void*>) _spliterator).start(_seq);
				_seq = null;
			}
		}
	}
}
