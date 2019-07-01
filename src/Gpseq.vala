/* Gpseq.vala
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
	internal const int MAX_ARRAY_LENGTH = int.MAX;

	/**
	 * Sorts the given array by comparing with the specified compare function,
	 * in parallel. The sort is stable.
	 *
	 * Note. With nullable primitive types, this method produces an undesirable
	 * result if the compare function is not specified. you should provide
	 * specified compare function to get a proper result.
	 *
	 * {{{
	 * int?[] array = {5, 4, 3, 2, 1};
	 * parallel_sort<int?>(array);
	 * // => the result is undesirable, such as 5, 2, 1, 3, 4
	 *
	 * int?[] array2 = {5, 4, 3, 2, 1};
	 * parallel_sort<int?>(array2, (a, b) => {
	 *     if (a == b) return 0;
	 *     else if (a == null) return -1;
	 *     else if (b == null) return 1;
	 *     else return a < b ? -1 : (a == b ? 0 : 1);
	 * });
	 * // => the result is 1, 2, 3, 4, 5
	 * }}}
	 *
	 * @param array a gpointer array to be sorted
	 * @param compare compare function to compare elements. if it is not
	 * specified, the result of {@link Gee.Functions.get_compare_func_for} is
	 * used
	 */
	public void parallel_sort<G> (G[] array, owned CompareFunc<G>? compare = null) {
		int len = array.length;
		if (len <= 1) return Future.of<void*>(null);
		G[] temp_array = new G[len];

		SubArray<G> sub = new SubArray<G>(array);
		SubArray<G> temp = new SubArray<G>(temp_array);
		Comparator<G> cmp = new Comparator<G>((owned) compare);

		TaskEnv env = TaskEnv.get_default_task_env();
		Executor exe = env.executor;
		int num_threads = exe.parallels;
		int64 threshold = env.resolve_threshold(len, num_threads);
		int max_depth = env.resolve_max_depth(len, num_threads);

		SortTask<G> task = new SortTask<G>(sub, temp, cmp, null, threshold, max_depth, exe);
		task.fork();
		task.join_quietly();
	}

	/**
	 * Gets the current value of //atomic//.
	 *
	 * This call acts as a full compiler and hardware
	 * memory barrier (before the get).
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @return the value of the integer
	 **/
	[CCode (cname="gpseq_atomic_int64_get")]
	public extern int64 atomic_int64_get ([CCode (type="volatile gint64 *")] ref int64 atomic);

	/**
	 * Sets the value of //atomic// to //newval//.
	 *
	 * This call acts as a full compiler and hardware
	 * memory barrier (after the set).
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param newval a new value to store
	 **/
	[CCode (cname="gpseq_atomic_int64_set")]
	public extern void atomic_int64_set ([CCode (type="volatile gint64 *")] ref int64 atomic, int64 newval);

	/**
	 * Increments the value of //atomic// by 1.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { *atomic += 1; }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 **/
	[CCode (cname="gpseq_atomic_int64_inc")]
	public extern void atomic_int64_inc ([CCode (type="volatile gint64 *")] ref int64 atomic);

	/**
	 * Decrements the value of //atomic// by 1.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { *atomic -= 1; return (*atomic == 0); }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @return %TRUE if the resultant value is zero
	 **/
	[CCode (cname="gpseq_atomic_int64_dec_and_test")]
	public extern bool atomic_int64_dec_and_test ([CCode (type="volatile gint64 *")] ref int64 atomic);

	/**
	 * Compares //atomic// to //oldval// and, if equal, sets it to //newval//.
	 * If //atomic// was not equal to //oldval// then no change occurs.
	 *
	 * This compare and exchange is done atomically.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { if (*atomic == oldval) { *atomic = newval; return TRUE; } else return FALSE; }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param oldval the value to compare with
	 * @param newval the value to conditionally replace with
	 * @return %TRUE if the exchange took place
	 **/
	[CCode (cname="gpseq_atomic_int64_compare_and_exchange")]
	public extern bool atomic_int64_compare_and_exchange ([CCode (type="volatile gint64 *")] ref int64 atomic, int64 oldval, int64 newval);

	/**
	 * Atomically adds //val// to the value of //atomic//.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { tmp = *atomic; *atomic += val; return tmp; }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param val the value to add
	 * @return the value of //atomic// before the add, signed
	 **/
	[CCode (cname="gpseq_atomic_int64_add")]
	public extern int64 atomic_int64_add ([CCode (type="volatile gint64 *")] ref int64 atomic, int64 val);

	/**
	 * Performs an atomic bitwise 'and' of the value of //atomic// and //val//,
	 * storing the result back in //atomic//.
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { tmp = *atomic; *atomic &= val; return tmp; }
	 * }}}
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param val the value to 'and'
	 * @return the value of //atomic// before the operation, unsigned
	 **/
	[CCode (cname="gpseq_atomic_int64_and")]
	public extern uint64 atomic_int64_and ([CCode (type="volatile guint64 *")] ref uint64 atomic, uint64 val);

	/**
	 * Performs an atomic bitwise 'or' of the value of //atomic// and //val//,
	 * storing the result back in //atomic//.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { tmp = *atomic; *atomic |= val; return tmp; }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param val the value to 'or'
	 * @return the value of //atomic// before the operation, unsigned
	 **/
	[CCode (cname="gpseq_atomic_int64_or")]
	public extern uint64 atomic_int64_or ([CCode (type="volatile guint64 *")] ref uint64 atomic, uint64 val);

	/**
	 * Performs an atomic bitwise 'xor' of the value of //atomic// and //val//,
	 * storing the result back in //atomic//.
	 *
	 * Think of this operation as an atomic version of:
	 *
	 * {{{
	 *   { tmp = *atomic; *atomic ^= val; return tmp; }
	 * }}}
	 *
	 * This call acts as a full compiler and hardware memory barrier.
	 *
	 * @param atomic a pointer to a {@link int64} or {@link uint64}
	 * @param val the value to 'xor'
	 * @return the value of //atomic// before the operation, unsigned
	 **/
	[CCode (cname="gpseq_atomic_int64_xor")]
	public extern uint64 atomic_int64_xor ([CCode (type="volatile guint64 *")] ref uint64 atomic, uint64 val);
}
