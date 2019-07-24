/* DefaultContainer.vala
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
	 * Default container implementation.
	 */
	internal class DefaultContainer<G> : Object, Spliterator<G>, Container<G,G> {
		private Spliterator<G> _spliterator; // may be a Container
		private Container<G,G>? _parent;
		private Consumer<G> _consumer;

		/**
		 * Creates a new default container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param consumer a consumer
		 */
		public DefaultContainer (Spliterator<G> spliterator,
				Container<G,void*>? parent, Consumer<G> consumer) {
			_spliterator = spliterator;
			_parent = parent;
			_consumer = consumer;
		}

		protected Spliterator<G> spliterator {
			get {
				return _spliterator;
			}
			set {
				assert(value != null);
				_spliterator = value;
			}
		}

		public Container<G,void*>? parent {
			get {
				return _parent;
			}
		}

		protected void set_parent (Container<G,void*>? parent) {
			_parent = parent;
		}

		protected Consumer<G> consumer {
			get {
				return _consumer;
			}
			set {
				assert(value != null);
				_consumer = value;
			}
		}

		public virtual Future<void*> start (Seq seq) {
			var future = parent != null ? parent.start(seq) : Future.of<void*>(null);
			set_parent(null);
			return future;
		}

		public virtual Spliterator<G>? try_split () {
			Spliterator<G>? spliter = _spliterator.try_split();
			if (spliter == null) {
				return null;
			} else {
				return make_container(spliter);
			}
		}

		/**
		 * Creates a child container with the given spliterator.
		 * @param a spliterator to create a child container
		 * @return the new child container
		 */
		protected virtual DefaultContainer<G> make_container (Spliterator<G> spliterator) {
			return new DefaultContainer<G>(spliterator, _parent, _consumer);
		}

		public virtual bool try_advance (Func<G> consumer) throws Error {
			Func<G> func = _consumer.function(g => consumer(g));
			return _spliterator.try_advance(func);
		}

		public virtual int64 estimated_size {
			get {
				return _spliterator.estimated_size;
			}
		}

		public virtual bool is_size_known {
			get {
				return _consumer.is_identity_function && _spliterator.is_size_known;
			}
		}

		public virtual void each (Func<G> f) throws Error {
			Func<G> func = _consumer.function(g => f(g));
			_spliterator.each(func);
		}

		public virtual bool each_chunk (EachChunkFunc<G> f) throws Error {
			if (_consumer.is_identity_function) {
				return _spliterator.each_chunk(f);
			} else {
				G? item = null;
				bool got = false;
				Func<G> func = _consumer.function(g => {
					item = g;
					got = true;
				});

				G[]? array = null;
				EachChunkFunc<G> loop_func = (chunk) => {
					if (array == null) {
						array = new G[chunk.length];
					} else if (array.length < chunk.length) {
						array.resize(chunk.length);
					}

					int idx = 0;
					for (int i = 0; i < chunk.length; i++) {
						func(chunk[i]);
						if (got) {
							array[idx++] = item;
							got = false;
						}
					}
					if (idx == 0) return true;
					return f(array[0:idx]);
				};
				return _spliterator.each_chunk(loop_func);
			}
		}
	}
}
