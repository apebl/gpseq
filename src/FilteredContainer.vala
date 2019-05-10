/* FilteredContainer.vala
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
	 * A container which contains the elements of a input that match the a
	 * predicate.
	 */
	internal class FilteredContainer<G> : DefaultContainer<G> {
		/**
		 * Creates a new filtered container.
		 * @param spliterator a spliterator that may or may not be a container
		 * @param parent the parent of the new container
		 * @param pred a //non-interfering// and //stateless// predicate
		 */
		public FilteredContainer (Spliterator<G> spliterator, Container<G,void*> parent,
				owned Predicate<G> pred) {
			base(spliterator, parent, new FilteredConsumer<G>((owned) pred));
		}

		private FilteredContainer.copy (FilteredContainer<G> container, Spliterator<G> spliterator) {
			base(spliterator, container.parent, container.consumer);
		}

		protected override DefaultContainer<G> make_container (Spliterator<G> spliterator) {
			return new FilteredContainer<G>.copy(this, spliterator);
		}

		private class FilteredConsumer<G> : Consumer<G> {
			private Predicate<G> _pred;

			public FilteredConsumer (owned Predicate<G> pred) {
				_pred = (owned) pred;
			}

			public override Func<G> function (owned Func<G> f) {
				return (g) => {
					if (_pred(g)) {
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
