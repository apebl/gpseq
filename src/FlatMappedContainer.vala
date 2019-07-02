/* FlatMappedContainer.vala
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
	/*
	 * A container which contains the elements of the results of applying a
	 * mapper function to the elements of a input.
	 */
	internal class FlatMappedContainer<R,G> : Object, Spliterator<R>, Container<R,G> {
		private const int CHUNK_SIZE = 128; // must be >= 1

		private Spliterator<G> _spliterator; // may be a Container
		private Container<G,void*>? _parent;
		private FlatMapFunc<R,G> _mapper;
		private Iterator<R>? _storage;

		/**
		 * Creates a new flat mapped container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param mapper a //non-interfering// and //stateless// mapping
		 * function
		 */
		public FlatMappedContainer (Spliterator<G> spliterator, Container<G,void*>? parent, owned FlatMapFunc<R,G> mapper) {
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
				return new FlatMappedContainer<R,G>(source, _parent, g => { return _mapper(g); });
			}
		}

		public bool try_advance (Func<R> consumer) throws Error {
			bool result = false;
			if (_storage == null) {
				result = _spliterator.try_advance(g => {
					_storage = _mapper(g);
				});
			}
			if ( _storage != null && (_storage.valid || _storage.next()) ) {
				consumer(_storage.get());
				if (!_storage.next()) {
					_storage = null;
				}
				return true;
			}
			return result;
		}

		public int64 estimated_size {
			get {
				return _spliterator.estimated_size;
			}
		}

		public bool is_size_known {
			get {
				return false;
			}
		}

		public void each (Func<R> f) throws Error {
			if (_storage != null) {
				foreach_iter(_storage, f);
				_storage = null;
			}
			_spliterator.each(g => {
				Iterator<R> iter = _mapper(g);
				foreach_iter(iter, f);
			});
		}

		private void foreach_iter (Iterator<R> iter, Func<R> f) throws Error {
			if (iter.valid) f(iter.get());
			while ( iter.next() ) {
				f(iter.get());
			}
		}

		public bool each_chunk (EachChunkFunc<R> f) throws Error {
			R[] buf = new R[CHUNK_SIZE];

			if (_storage != null) {
				int i = 0;
				if (_storage.valid) buf[i++] = _storage.get();
				do {
					while (i < CHUNK_SIZE && _storage.next()) {
						buf[i++] = _storage.get();
					}
					if ( i > 0 && !f(buf[0:i]) ) {
						return false;
					}
					i = 0;
				} while ( _storage.has_next() );
				_storage = null;
			}

			return _spliterator.each_chunk(chunk => {
				int idx = 0;
				for (int i = 0; i < chunk.length; i++) {
					Iterator<R> storage = _mapper(chunk[i]);
					if (storage.valid) buf[idx++] = storage.get();
					do {
						while (idx < CHUNK_SIZE && storage.next()) {
							buf[idx++] = storage.get();
						}
						if ( idx > 0 && !f(buf[0:idx]) ) {
							if (storage.has_next()) _storage = storage;
							return false;
						}
						idx = 0;
					} while ( storage.has_next() );
				}
				return true;
			});
		}
	}
}
