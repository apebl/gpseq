/* Spliterator.vala
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
	 * An object for traversing and partitioning elements of a data source.
	 */
	[GenericAccessors]
	public interface Spliterator<G> : Object {
		private const int CHUNK_SIZE = 128;

		/**
		 * Creates a new empty spliterator.
		 * @return a new empty spliterator
		 */
		public static Spliterator<G> empty<G> () {
			return new EmptySpliterator<G>();
		}

		/**
		 * The type of the elements in this spliterator.
		 */
		public Type element_type {
			get {
				return typeof(G);
			}
		}

		/**
		 * If this spliterator can be partitioned, returns a spliterator
		 * covering some elements that will not be covered by this spliterator.
		 * otherwise, returns null.
		 *
		 * The returned spliterator must cover a prefix of the elements if
		 * the data source has an encounter order.
		 *
		 * The returned spliterator could not 'own' its elements.
		 * (no 'ownership'; i.e. unowned)
		 *
		 * This method may return null for any reason, including emptiness, data
		 * structure constraints, and efficiency considerations.
		 *
		 * Note. An ideal efficient work of //try_split// method is dividing
		 * its elements exactly in half.
		 *
		 * @return a partition of this spliterator.
		 */
		public abstract Spliterator<G>? try_split ();

		/**
		 * If a remaining element exists, performs the given consumer function
		 * on it, advances to the next element if remaining, and returns true.
		 * otherwise returns false.
		 *
		 * The function is performed on the next element in encounter order, if
		 * the data source has an encounter order.
		 *
		 * @return false if no remaining elements existed, true otherwise.
		 */
		public abstract bool try_advance (Func<G> consumer) throws Error; // XXX data-owned consumer?

		/**
		 * The estimated size of the remaining elements. it is negative if
		 * infinite, unknown, or can't be estimated for any reason.
		 *
		 * If {@link is_size_known} is true, this estimate is an accurate size.
		 */
		public abstract int64 estimated_size { get; }

		/**
		 * Whether or not the accurate size of this spliterator is known.
		 *
		 * If this is true, {@link estimated_size} returns an accurate size.
		 *
		 * This value always could be changed false -> true when status changed,
		 * but not vice versa.
		 *
		 * Note. //is_size_known && estimated_size < 0// is possible. (e.g.
		 * an infinite spliterator)
		 */
		public abstract bool is_size_known { get; }

		/**
		 * Applies the given function to each of the remaining elements.
		 *
		 * The function is performed in encounter order, if the data source has
		 * an encounter order.
		 *
		 * This method would be more optimized than manual {@link try_advance}
		 * calls.
		 */
		public virtual void each (Func<G> f) throws Error { // XXX data-owned consumer?
			do {} while (try_advance(f));
		}

		/**
		 * Applies the given function to each chunk of the remaining elements,
		 * until last chunk or function returns false.
		 *
		 * The function is performed in encounter order, if the data source has
		 * an encounter order.
		 *
		 * The chunks given to the function are always non-empty.
		 *
		 * This method would be more optimized than manual {@link try_advance}
		 * calls.
		 *
		 * @return false if the argument returned false at last invocation and
		 * true otherwise.
		 */
		public virtual bool each_chunk (EachChunkFunc<G> f) throws Error {
			G[] array = new G[CHUNK_SIZE];
			while (true) {
				int i = 0;
				do {} while (
					i < CHUNK_SIZE && try_advance(g => { array[i++] = g; })
				);
				if (i == 0) return true;
				if ( !f(array[0:i]) ) return false;
				if (i < CHUNK_SIZE) return true;
			}
		}
	}
}
