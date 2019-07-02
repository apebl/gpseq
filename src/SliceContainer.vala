/* SliceContainer.vala
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
	 * A slice container.
	 */
	internal class SliceContainer<G> : DefaultContainer<G> {
		private int64 _skip;
		private int64 _limit;
		private bool _ordered;
		private bool _started;

		/**
		 * Creates a new slice container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param skip the number of elements to skip
		 * @param limit maximum number of elements the spliterator may contain,
		 * or a negative value if unlimited
		 */
		public SliceContainer (Spliterator<G> spliterator,
				Container<G,void*> parent, int64 skip, int64 limit, bool ordered)
			requires (skip >= 0)
		{
			base(spliterator, parent, new Consumer<G>());
			_skip = skip;
			_limit = limit;
			_ordered = ordered;
		}

		private SliceContainer.copy (SliceContainer<G> container, Spliterator<G> spliterator) {
			base(spliterator, container.parent, container.consumer);
		}

		protected override DefaultContainer<G> make_container (Spliterator<G> spliterator) {
			return new SliceContainer<G>.copy(this, spliterator);
		}

		public override Future<void*> start (Seq seq) {
			var future = parent != null ? parent.start(seq) : Future.of<void*>(null);
			set_parent(null);
			return future.flat_map<void*>(value => {
				return set_up(seq);
			});
		}

		private Future<void*> set_up (Seq seq) {
			if (!seq.is_parallel) {
				spliterator = new SequentialSliceSpliterator<G>(spliterator, _skip, _limit);
				_started = true;
				return Future.of<void*>(null);
			} else if (_ordered) {
				// XXX perform unordered slice if the spliterator is unordered.
				// this needs to add 'attributes' flags to spliterator.
				// TODO optimize when the exact size of the spliterator is
				// known and the spliterator doesn't cover infinite elements.
				int64 len = estimated_size;
				int64 threshold = seq.task_env.resolve_threshold(len, seq.task_env.executor.parallels);
				int max_depth = seq.task_env.resolve_max_depth(len, seq.task_env.executor.parallels);
				OrderedSliceTask<G> task = new OrderedSliceTask<G>(
						_skip, _limit, spliterator, null,
						threshold, max_depth, seq.task_env.executor);
				task.fork();
				return task.future.map<void*>(value => {
					ArrayBuffer<G> result = value;
					spliterator = new ArrayBufferSpliterator<G>(result, 0, result.size);
					_started = true;
					return null;
				});
			} else {
				spliterator = new UnorderedSliceSpliterator<G>(spliterator, _skip, _limit);
				_started = true;
				return Future.of<void*>(null);
			}
		}

		public override bool is_size_known {
			get {
				return _started && base.is_size_known;
			}
		}
	}
}
