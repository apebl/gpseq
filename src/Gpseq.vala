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

	private const int64 SORT_THRESHOLD = 32768; // 1 << 15

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
	 * parallel_sort<int?>(array).wait();
	 * // => the result is undesirable, such as 5, 2, 1, 3, 4
	 *
	 * int?[] array2 = {5, 4, 3, 2, 1};
	 * parallel_sort<int?>(array2, (a, b) => {
	 *     if (a == null) return -1;
	 *     else if (b == null) return 1;
	 *     else return a < b ? -1 : (a == b ? 0 : 1);
	 * }).wait();
	 * // => the result is 1, 2, 3, 4, 5
	 * }}}
	 *
	 * @param array a gpointer array to be sorted
	 * @param compare compare function to compare elements. if it is not
	 * specified, the result of {@link Gee.Functions.get_compare_func_for} is
	 * used
	 * @return a future which will be completed with a null value if the sort
	 * succeeds, or with an exception if the sort fails because an error is
	 * thrown from the compare function
	 */
	public Future<void*> parallel_sort<G> (G[] array, owned CompareDataFunc<G>? compare = null) {
		int len = array.length;
		if (len <= SORT_THRESHOLD) {
			SubArray<G> sub = new SubArray<G>(array);
			sub.sort((owned) compare);
			return Future.of<void*>(null);
		} else {
			SubArray<G> sub = new SubArray<G>(array);
			G[] temp = new G[len];
			Comparator<G> cmp = new Comparator<G>((owned) compare);

			TaskEnv env = TaskEnv.get_common_task_env();
			Executor exe = env.executor;
			int num_threads = exe.parallels;
			int64 threshold = env.resolve_threshold(len, num_threads);
			int max_depth = env.resolve_max_depth(len, num_threads);

			SortTask<G> task = new SortTask<G>(sub, (owned)temp, cmp, null, threshold, max_depth, exe);
			task.fork();
			return task.future;
		}
	}

	/**
	 * Schedules the given function to execute asynchronously.
	 *
	 * The {@link Executor} of {@link TaskEnv.get_common_task_env} will execute
	 * the function. By default, it is a {@link WorkerPool} which uses
	 * work-stealing algorithm.
	 *
	 * @param func a task function to execute
	 * @return a future of the execution
	 *
	 * @see WorkerPool
	 * @see FuncTask
	 */
	public Future<G> task<G> (owned TaskFunc<G> func) {
		var task = new FuncTask<G>((owned) func);
		TaskEnv.get_common_task_env().executor.submit(task);
		return task.future;
	}

	/**
	 * Runs the given blocking task.
	 *
	 * If the current thread is not a {@link WorkerThread}, this method just
	 * runs the task without any further work. Otherwise, this method tries to
	 * create (or optain from pool, depending on the internal implementation) a
	 * new thread.
	 *
	 * -> If succeed, the new thread takes the context of this thread and
	 * runs the remaining tasks in the context. This thread runs the
	 * blocking task and is marked as //blocked// until the task ends.
	 * After it ends, this thread is unblocked and takes the context back,
	 * and the new thread is terminated (or returned to the pool).
	 *
	 * -> If failed, e.g. the maximum number of threads exceeded, this
	 * method just runs the function without any further work.
	 *
	 * @param func a task function
	 *
	 * @throws Error the error thrown by the function
	 *
	 * @see Gpseq.blocking_get
	 * @see WorkerThread.blocking
	 */
	[Version (since="0.2.0-alpha")]
	public void blocking (VoidTaskFunc func) throws Error {
		blocking_get<void*>(() => {
			func();
			return null;
		});
	}

	/**
	 * Runs the given blocking task and returns the result.
	 *
	 * If the current thread is not a {@link WorkerThread}, this method just
	 * runs the task without any further work. Otherwise, this method tries to
	 * create (or optain from pool, depending on the internal implementation) a
	 * new thread.
	 *
	 * -> If succeed, the new thread takes the context of this thread and
	 * runs the remaining tasks in the context. This thread runs the
	 * blocking task and is marked as //blocked// until the task ends.
	 * After it ends, this thread is unblocked and takes the context back,
	 * and the new thread is terminated (or returned to the pool).
	 *
	 * -> If failed, e.g. the maximum number of threads exceeded, this
	 * method just runs the function without any further work.
	 *
	 * @param func a task function
	 * @return the result produced by the function
	 *
	 * @throws Error the error thrown by the function
	 *
	 * @see Gpseq.blocking
	 * @see WorkerThread.blocking
	 */
	[Version (since="0.2.0-alpha")]
	public G blocking_get<G> (TaskFunc<G> func) throws Error {
		WorkerThread? thread = WorkerThread.self();
		if (thread == null) return func();
		return thread.blocking<G>(func);
	}

	/**
	 * Runs the subtasks and returns the results.
	 *
	 * Submits the left task to the executor first, runs the right task in
	 * the current thread, and waits for them to complete.
	 *
	 * This method uses the executor of the common task env.
	 *
	 * {{{
	 * int fibonacci (int n) {
	 *     if (n <= 1) {
	 *         return n;
	 *     } else {
	 *         // Note. Not 'int' but 'int?' (boxed value type)
	 *         var (left, right) = join<int?>( () => fibonacci(n-1),
	 *                                         () => fibonacci(n-2) );
	 *         return left + right;
	 *     }
	 * }
	 * }}}
	 *
	 * @param left the left task
	 * @param right the right task
	 * @return (left-result, right-result) An array containing the two results.
	 *
	 * @throws Error the error thrown by the subtasks
	 *
	 * @see ForkJoinTask
	 * @see SpliteratorTask
	 * @see TaskEnv.get_common_task_env
	 */
	[Version (since="0.3.0")]
	public G[] join<G> (owned TaskFunc<G> left, owned TaskFunc<G> right) throws Error {
		var executor = TaskEnv.get_common_task_env().executor;
		var left_task = new FuncTask<G>((owned) left);
		executor.submit(left_task);
		var right_task = new FuncTask<G>((owned) right);
		right_task.invoke();
		G right_result = right_task.future.value;
		G left_result;
		WorkerThread? t = WorkerThread.self();
		if (t == null) {
			left_result = left_task.future.wait();
		} else {
			t.task_join(left_task);
			left_result = left_task.future.value;
		}
		return { left_result, right_result };
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

	[CCode (cname="g_atomic_int_get", type="gint", cheader_filename = "glib.h")]
	private extern uint atomic_uint_get ([CCode (type="volatile gint *")] ref uint atomic);
	[CCode (cname="g_atomic_int_set", cheader_filename = "glib.h")]
	private extern void atomic_uint_set ([CCode (type="volatile gint *")] ref uint atomic, [CCode (type="gint")] uint newval);
	[CCode (cname="g_atomic_int_inc", cheader_filename = "glib.h")]
	private extern void atomic_uint_inc ([CCode (type="volatile gint *")] ref uint atomic);
	[CCode (cname="g_atomic_int_compare_and_exchange", cheader_filename = "glib.h")]
	private extern bool atomic_uint_compare_and_exchange (
			[CCode (type="volatile gint *")] ref uint atomic,
			[CCode (type="gint")] uint oldval, [CCode (type="gint")] uint newval);
	[CCode (cname="g_atomic_int_add", type="gint", cheader_filename = "glib.h")]
	private extern uint atomic_uint_add ([CCode (type="volatile gint *")] ref uint atomic, [CCode (type="gint")] uint val);
	[CCode (cname="g_atomic_int_or", cheader_filename = "glib.h")]
	private extern uint atomic_uint_or ([CCode (type="volatile guint *")] ref uint atomic, uint val);
}
