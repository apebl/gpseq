/* SortedContainer.vala
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
	/*
	 * A container which contains the elements of a input, sorted based on a
	 * compare function.
	 */
	internal class SortedContainer<G> : DefaultContainer<G> {
		private CompareFunc<G>? _compare;

		/**
		 * Creates a new sorted container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param compare a //non-interfering// and //stateless// compare
		 * function
		 */
		public SortedContainer (Spliterator<G> spliterator, Container<G,void*> parent,
				owned CompareFunc<G> compare) {
			base(spliterator, parent, new Consumer<G>());
			_compare = (owned) compare;
		}

		private SortedContainer.copy (SortedContainer<G> container, Spliterator<G> spliterator) {
			base(spliterator, container.parent, container.consumer);
		}

		protected override DefaultContainer<G> make_container (Spliterator<G> spliterator) {
			return new SortedContainer<G>.copy(this, spliterator);
		}

		public override Future<void*> start (Seq seq) {
			var future = parent != null ? parent.start(seq) : Future.of<void*>(null);
			set_parent(null);
			return future.flat_map<void*>(value => {
				try {
					return sort(seq);
				} catch (Error err) {
					var promise = new Promise<void*>();
					promise.set_exception((owned) err);
					return promise.future;
				}
			});
		}

		private Future<void*> sort (Seq seq) throws Error {
			G[] array = spliter_to_array();
			SubArray<G> sub = new SubArray<G>(array);
			int len = array.length;
			if (seq.is_parallel) {
				G[] temp = new G[len];
				Comparator<G> cmp = new Comparator<G>((owned) _compare);
				int64 threshold = seq.task_env.resolve_threshold(len, seq.task_env.executor.parallels);
				int max_depth = seq.task_env.resolve_max_depth(len, seq.task_env.executor.parallels);

				SortTask<G> task = new SortTask<G>(
						sub, (owned)temp, cmp,
						null, threshold, max_depth, seq.task_env.executor);
				task.fork();
				return task.future.map<void*>(value => {
					spliterator = new ArraySpliterator<G>((owned) array, 0, len);
					return null;
				});
			} else {
				sub.sort((owned) _compare);
				spliterator = new ArraySpliterator<G>((owned) array, 0, len);
				return Future.of<void*>(null);
			}
		}

		private G[] spliter_to_array () throws Error {
			G[] array;
			if (!spliterator.is_size_known || spliterator.estimated_size < 0) {
				array = {}; // XXX use estimated_size
				int i = 0;
				spliterator.each(g => {
					if (i >= MAX_ARRAY_LENGTH) {
						error("Seq exceeds max array length");
					} else if (i >= array.length) {
						int64 next_len = next_pot(i);
						if (next_len > MAX_ARRAY_LENGTH || next_len < 0) {
							next_len = (int64)MAX_ARRAY_LENGTH;
						}
						array.resize((int) next_len);
					}
					array[i++] = g;
				});
				if (array.length != i) array.resize(i);
			} else if (spliterator.estimated_size > 0) {
				if (spliterator.estimated_size > MAX_ARRAY_LENGTH) {
					error("Seq exceeds max array length");
				}
				array = new G[spliterator.estimated_size];
				int i = 0;
				spliterator.each(g => {
					array[i++] = g;
				});
			} else { // spliterator.estimated_size == 0
				array = {};
			}
			return array;
		}

		/**
		 * Finds next power of two, which is greater than and not equal to n.
		 * @return next power of two, which is greater than and not equal to n
		 */
		private inline int64 next_pot (int64 n) {
			n |= n >> 1;
			n |= n >> 2;
			n |= n >> 4;
			n |= n >> 8;
			n |= n >> 16;
			n |= n >> 32;
			return (n > int64.MAX - 1) ? -1 : ++n;
		}
	}
}
