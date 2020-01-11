/* MappedContainer.vala
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
	/*
	 * A container which contains the results of applying a mapper function to
	 * the elements of a input.
	 */
	internal class MappedContainer<R,G> : Object, Spliterator<R>, Container<R,G> {
		private Spliterator<G> _spliterator; // may be a Container
		private Container<G,void*>? _parent;
		private MapFunc<R,G> _mapper;

		/**
		 * Creates a new mapped container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param mapper a //non-interfering// and //stateless// mapping
		 * function
		 */
		public MappedContainer (Spliterator<G> spliterator, Container<G,void*>? parent, owned MapFunc<R,G> mapper) {
			_spliterator = spliterator;
			_parent = parent;
			_mapper = (owned) mapper;
		}

		public Container<G,void*>? parent {
			get {
				return _parent;
			}
		}

		public virtual Future<void*> start (Seq seq) {
			var future = parent != null ? parent.start(seq) : Future.of<void*>(null);
			_parent = null;
			return future;
		}

		public Spliterator<R>? try_split () {
			Spliterator<G>? source = _spliterator.try_split();
			if (source == null) {
				return null;
			} else {
				return new MappedContainer<R,G>(source, _parent, g => { return _mapper(g); });
			}
		}

		public bool try_advance (Func<R> consumer) throws Error {
			return _spliterator.try_advance(g => {
				consumer(_mapper(g));
			});
		}

		public int64 estimated_size {
			get {
				return _spliterator.estimated_size;
			}
		}

		public bool is_size_known {
			get {
				return _spliterator.is_size_known;
			}
		}

		public void each (Func<R> f) throws Error {
			_spliterator.each(g => {
				f(_mapper(g));
			});
		}

		public bool each_chunk (EachChunkFunc<R> f) throws Error {
			R[]? array = null;
			return _spliterator.each_chunk(chunk => {
				if (array == null) {
					array = new R[chunk.length];
				} else if (array.length < chunk.length) {
					array.resize(chunk.length);
				}

				int i = 0;
				while (i < chunk.length) {
					array[i] = _mapper(chunk[i]);
					i++;
				}
				// chunk is always non-empty
				return f(array[0:i]);
			});
		}
	}
}
