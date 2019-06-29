/* Comparator.vala
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
	 * An utility object for sort.
	 */
	internal class Comparator<G> : Object {
		private CompareFunc<G> _compare_func;

		/**
		 * Creates a new comparator instance.
		 * @param compare_func a compare function. if not specified,
		 * {@link Gee.Functions.get_compare_func_for} is used to get a proper
		 * function
		 */
		public Comparator (owned CompareFunc<G>? compare_func = null) {
			if (compare_func != null) {
				_compare_func = (owned) compare_func;
			} else {
				CompareDataFunc func = Functions.get_compare_func_for(val_type);
				_compare_func = (a, b) => func(a, b);
			}
		}

		public Type val_type {
			get {
				return typeof(G);
			}
		}

		private CompareFunc<G> clone_func () {
			return (a, b) => { return _compare_func(a, b); };
		}

		public int compare (G a, G b) throws Error {
			return _compare_func(a, b);
		}

		public void sort_sub_array (SubArray<G> array) throws Error {
			array.sort( clone_func() );
		}
	}
}
