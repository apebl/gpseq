/* DistinctContainer.vala
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
	 * A container which contains the distinct elements of an input.
	 */
	internal class DistinctContainer<G> : DefaultContainer<G> {
		private HashDataFunc<G>? _hash;
		private EqualDataFunc<G>? _equal;
		private bool _started;

		/**
		 * Creates a new distinct container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param hash a //non-interfering// and //stateless// hash function
		 * @param equal a //non-interfering// and //stateless// equal function
		 */
		public DistinctContainer (Spliterator<G> spliterator, Container<G,void*> parent,
				owned HashDataFunc<G> hash, owned EqualDataFunc<G> equal) {
			base(spliterator, parent, new Consumer<G>());
			_hash = (owned) hash;
			_equal = (owned) equal;
		}

		private DistinctContainer.copy (DistinctContainer<G> container, Spliterator<G> spliterator) {
			base(spliterator, container.parent, container.consumer);
		}

		protected override DefaultContainer<G> make_container (Spliterator<G> spliterator) {
			return new DistinctContainer<G>.copy(this, spliterator);
		}

		public override Future<void*> start (Seq seq) {
			var future = parent != null ? parent.start(seq) : Future.of<void*>(null);
			set_parent(null);
			return (Future<void*>) future.flat_map<void*>(value => {
				return perform(seq);
			});
		}

		private Future<void*> perform (Seq seq) {
			if (seq.is_parallel) {
				return perform_parallel(seq);
			} else {
				return perform_sequential();
			}
		}

		private Future<void*> perform_parallel (Seq seq) {
			// TODO implement lock-free hash set/map
			Set<G> seen = new HashSet<G>((owned) _hash, (owned) _equal);
			Func<G> func = (g) => add_to_set(g, seen);
			int64 len = estimated_size;
			int64 threshold = seq.task_env.resolve_threshold(len, seq.task_env.executor.parallels);
			int max_depth = seq.task_env.resolve_max_depth(len, seq.task_env.executor.parallels);
			ForEachTask<G> task = new ForEachTask<G>(
					func, spliterator, null,
					threshold, max_depth, seq.task_env.executor);
			task.fork();
			return (Future<void*>) task.future.map<void*>(value => {
				spliterator = new IteratorSpliterator<G>.from_collection(seen);
				_started = true;
				return null;
			});
		}

		private void add_to_set (G g, Set<G> seen) {
			lock (_hash) {
				seen.add(g);
			}
		}

		private Future<void*> perform_sequential () {
			// XXX optimize distinct() of sorted container
			// sorted container doesn't need to store all seen elements but only
			// a last seen element. the optimization needs to add 'attributes'
			// flags property to spliterator.
			consumer = new SequentialDistinctConsumer<G>((owned) _hash, (owned) _equal);
			_started = true;
			return Future.of<void*>(null);
		}

		public override bool is_size_known {
			get {
				return _started && base.is_size_known;
			}
		}

		private class SequentialDistinctConsumer<G> : Consumer<G> {
			private Set<G> _seen; // freed when the container is freed

			public SequentialDistinctConsumer(
					owned HashDataFunc<G> hash, owned EqualDataFunc<G> equal) {
				_seen = new HashSet<G>((owned) hash, (owned) equal);
			}

			public override Func<G> function (owned Func<G> f) {
				return (g) => {
					if (!_seen.contains(g)) {
						_seen.add(g);
						f(g);
					}
				};
			}

			public override bool is_identity_function {
				get {
					return false;
				}
			}
		}
	}
}
