/* Compares.vala
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

[Version (since="0.4.0-alpha")]
namespace Gpseq.Compares {
	/**
	 * Returns a null-aware compare function which consider that null is less
	 * than non-null.
	 *
	 *  * Null is less than non-null.
	 *  * If both are null, they are considered equal.
	 *  * If both are non-null, uses the given function //cmp// to compare them.
	 *
	 * @param cmp a compare function to be used if both are non-null. if not
	 * specified, {@link Gee.Functions.get_compare_func_for} is used to get a
	 * proper function.
	 * @return the new compare function
	 */
	/* XXX Functions.get_compare_func_for can't deal with nullable primitive types
	public CompareDataFunc<G?> nulls_first<G> (owned CompareDataFunc<G>? cmp = null) {
		if (cmp == null) cmp = Functions.get_compare_func_for(typeof(G));
		return (a, b) => a == null ? (b == null ? 0 : -1) : (b == null ? 1 : cmp(a, b));
	}
	*/

	/**
	 * Returns a null-aware compare function which consider that null is greater
	 * than non-null.
	 *
	 *  * Null is greater than non-null.
	 *  * If both are null, they are considered equal.
	 *  * If both are non-null, uses the given function //cmp// to compare them.
	 *
	 * @param cmp a compare function to be used if both are non-null. if not
	 * specified, {@link Gee.Functions.get_compare_func_for} is used to get a
	 * proper function.
	 * @return the new compare function
	 */
	/* XXX Functions.get_compare_func_for can't deal with nullable primitive types
	public CompareDataFunc<G?> nulls_last<G> (owned CompareDataFunc<G>? cmp = null) {
		if (cmp == null) cmp = Functions.get_compare_func_for(typeof(G));
		return (a, b) => a == null ? (b == null ? 0 : 1) : (b == null ? -1 : cmp(a, b));
	}
	*/

	/**
	 * Returns a compare function which is a reversed version of the given
	 * function.
	 *
	 * @param cmp a compare function. if not specified,
	 * {@link Gee.Functions.get_compare_func_for} is used to get a proper
	 * function.
	 * @return the new compare function
	 */
	public CompareDataFunc<G> reverse<G> (owned CompareDataFunc<G>? cmp = null) {
		if (cmp == null) cmp = Functions.get_compare_func_for(typeof(G));
		return (a, b) => cmp(b, a);
	}

	/**
	 * Joins the given two compare functions and returns the combined compare
	 * function.
	 *
	 *  i. It compares using //cmp// first
	 *  i. If both are considered equal, it compares them using //cmp2//.
	 *
	 * @param cmp a compare function
	 * @param cmp2 a compare function
	 * @return the new compare function
	 */
	public CompareDataFunc<G> join<G> (owned CompareDataFunc<G> cmp, owned CompareDataFunc<G> cmp2) {
		return (a, b) => {
			int c = cmp(a, b);
			return c != 0 ? c : cmp2(a, b);
		};
	}
}
