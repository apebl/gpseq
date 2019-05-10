/* Supplier.vala
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
	 * An object that supplies results.
	 */
	public interface Supplier<G> : Object {
		/**
		 * Creates a new supplier from the given supply function.
		 * @param func a supply function
		 * @return a new supplier from the given supply function
		 */
		public static Supplier<G> from_func<G> (owned SupplyFunc<G> func) {
			return new DefaultSupplier<G>((owned) func);
		}

		/**
		 * Supplies a result.
		 * @return a result
		 */
		public abstract G supply ();
	}
}
