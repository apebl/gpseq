/* Seq.vala
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
	 * A sequence of elements, supporting sequential and parallel operations.
	 *
	 * == Seq pipelines ==
	 *
	 * There are two kinds of operations in seq; //intermediate// and
	 * //terminal// operations. A seq pipeline consists of zero or more
	 * intermediate operations and a terminal operation.
	 *
	 * === Intermediate operations ===
	 *
	 * Intermediate operations are always //lazy//. It means that traversal of
	 * the source does not begin until a terminal operation is executed. They
	 * return a new seq that will perform the operation, and the operation will
	 * be performed just before a terminal operation is executed. The previous
	 * seq, that has called the intermediate operation method, of the new one
	 * is closed and can no longer be used.
	 *
	 * Intermediate operations are further divided into //stateless// and
	 * //stateful// operations. Stateless operations retain no state from
	 * previously seen element when processing a new element. Therefore, each
	 * element can be processed independently on other elements. Stateful
	 * operations may incorporate state from previously seen elements when
	 * processing new elements, and may need to process the entire input
	 * before producing a result. Consequently, seq pipelines containing
	 * stateful intermediate operations may require multiple passes or may need
	 * to buffer significant data. On the contrary, seq pipelines containing
	 * only stateless intermediate (and terminal) operations can be processed
	 * in a single pass.
	 *
	 * === Terminal operations ===
	 *
	 * Terminal operations may traverse the source to produce a result or a
	 * side-effect. Almost all of terminal operations are //eager//. They
	 * complete their traversal of the input and processing of the pipeline
	 * before returning. The only exceptions are {@link Seq.iterator} and
	 * {@link Seq.spliterator}. They are provided for client-controlled
	 * traversals. After the terminal operation is performed, the seq is closed
	 * and can no longer be used.
	 *
	 * === Short-circuiting ===
	 *
	 * Some operations are regarded as //short-circuiting// operations.
	 * A short-circuiting intermediate operation may produce a finite seq as a
	 * result when infinite input given. A short-circuiting terminal operation
	 * may terminate in finite time when infinite input given. For processing
	 * a seq of infinite source to terminate normally in finite time, it is
	 * necessary that the pipeline contains a short-circuiting operation.
	 *
	 * === Parallelism ===
	 *
	 * When the terminal operation is started, the seq pipeline is executed
	 * sequentially or in parallel depending on the mode of the seq on which it
	 * is invoked. The mode is sequential in an initial seq, and can be changed
	 * by {@link Seq.sequential} and {@link Seq.parallel} intermediate
	 * operations.
	 *
	 * All operations respect encounter order in sequential execution. In
	 * parallel execution, however, all stateful intermediate and terminal
	 * operations may not respect the encounter order, except for operations
	 * identified as explicitly ordered such as {@link Seq.find_first}.
	 *
	 * === Non-interference ===
	 *
	 * If a data source, such as list, is used to create a seq, the data source
	 * must not be //interfered// until the execution of the seq pipeline is
	 * completed. It means ensuring that the data source is not modified until
	 * the execution of the seq pipeline is completed. Except for the non-eager
	 * operations iterator() and spliterator(), execution is performed when the
	 * terminal operation is invoked. In case of the non-eager operations, the
	 * data source must not be modified while the iterator/spliterator is used.
	 *
	 * === Stateless ===
	 *
	 * The result of seq pipeline may be nondeterministic or incorrect if the
	 * behaviors to the seq operations are //stateful// -- its result depends on
	 * any state that might change during the execution of the seq pipeline.
	 *
	 * === Associativity ===
	 *
	 * An //associative// operator or function '~' follows:
	 * //(a ~ b) ~ c == a ~ (b ~ c)//
	 *
	 * Numeric addition, numeric multiplication, min, max, and string
	 * concatenation are examples of associative operations.
	 *
	 * == Notes ==
	 *
	 * With nullable primitive types, operations using {@link CompareDataFunc}
	 * function, such as order_by(), produce an undesirable result if the
	 * compare function is not specified. You should provide specified compare
	 * function to get a proper result.
	 *
	 * Some operation might not work properly with unowned types. The best
	 * approach is never to use unowned types for seq.
	 *
	 * If an operation method is tried after the seq has been closed, the try
	 * is (assertion) failed.
	 *
	 * A result future of a sequential pipeline is already completed when
	 * returned from the terminal operation method, and therefore you do not
	 * have to wait the future for getting the value.
	 */
	public class Seq<G> : Object {
		/**
		 * Creates a new sequential seq of the given array.
		 *
		 * The given array itself will not be modified by seq operations. and
		 * the array must not be modified until the execution of the seq
		 * pipeline is completed. Except for the non-eager operations iterator()
		 * and spliterator(), execution is performed when the terminal operation
		 * is invoked. In case of the non-eager operations, the array must not
		 * be modified while the iterator/spliterator is used.
		 *
		 * This method doesn't steal the ownership of the array. The array must
		 * not be freed until the execution is completed.
		 *
		 * @param array a gpointer array
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_array<G> (G[] array, TaskEnv? env = null) {
			Spliterator<G> spliter = new SubArraySpliterator<G>(
					new SubArray<G>(array), 0, array.length);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential seq of the given array.
		 *
		 * The given array itself will not be modified by seq operations. and
		 * the array must not be modified until the execution of the seq
		 * pipeline is completed. Except for the non-eager operations iterator()
		 * and spliterator(), execution is performed when the terminal operation
		 * is invoked. In case of the non-eager operations, the array must not
		 * be modified while the iterator/spliterator is used.
		 *
		 * This method steals the ownership of the array. The array wil be
		 * freed after the execution is completed.
		 *
		 * @param array a gpointer array
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_owned_array<G> (owned G[] array, TaskEnv? env = null) {
			// must take length first, before ownership transferred
			int len = array.length;
			Spliterator<G> spliter = new ArraySpliterator<G>((owned) array, 0, len);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential seq of the given generic array.
		 *
		 * The given generic array itself will not be modified by seq
		 * operations. and the array must not be modified until the execution of
		 * the seq pipeline is completed. Except for the non-eager operations
		 * iterator() and spliterator(), execution is performed when the
		 * terminal operation is invoked. In case of the non-eager operations,
		 * the array must not be modified while the iterator/spliterator is
		 * used.
		 *
		 * @param array a generic array
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_generic_array<G> (GenericArray<G> array, TaskEnv? env = null) {
			Spliterator<G> spliter = new GenericArraySpliterator<G>(array, 0, array.length);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential seq of the given iterator.
		 *
		 * Most of the seq operations affect the state of the given iterator by
		 * moving it forward. and the iterator must not be modified until the
		 * execution of the seq pipeline is completed. Except for the non-eager
		 * operations iterator() and spliterator(), execution is performed when
		 * the terminal operation is invoked. In case of the non-eager
		 * operations, the iterator must not be modified while the result
		 * iterator/spliterator is used.
		 *
		 * @param iterator an iterator
		 * @param estimated_size an estimate of the number of elements
		 * @param size_known whether or not the estimated_size is an accurate
		 * size
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_iterator<G> (Iterator<G> iterator,
				int64 estimated_size, bool size_known, TaskEnv? env = null) {
			Spliterator<G> spliter = new IteratorSpliterator<G>(iterator, estimated_size, size_known);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential seq of the given collection.
		 *
		 * The given collection itself will not be modified by seq operations.
		 * and the collection must not be modified until the execution of the
		 * seq pipeline is completed. Except for the non-eager operations
		 * iterator() and spliterator(), execution is performed when the
		 * terminal operation is invoked. In case of the non-eager operations,
		 * the collection must not be modified while the iterator/spliterator is
		 * used.
		 *
		 * @param collection a collection
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_collection<G> (Collection<G> collection, TaskEnv? env = null) {
			Spliterator<G> spliter = new IteratorSpliterator<G>.from_collection(collection);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential seq of the given list.
		 *
		 * The given list itself will not be modified by seq operations. and the
		 * list must not be modified until the execution of the seq pipeline is
		 * completed. Except for the non-eager operations iterator() and
		 * spliterator(), execution is performed when the terminal operation is
		 * invoked. In case of the non-eager operations, the list must not be
		 * modified while the iterator/spliterator is used.
		 *
		 * The result seq of this method will show better performance than the
		 * result of {@link of_collection}.
		 *
		 * @param list a list
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_list<G> (Gee.List<G> list, TaskEnv? env = null) {
			Spliterator<G> spliter = new ListSpliterator<G>(list, 0, list.size);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential infinite unordered seq, which each element
		 * is generated by the given supplier.
		 *
		 * @param supplier a supplier
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_supplier<G> (Supplier<G> supplier, TaskEnv? env = null) {
			Spliterator<G> spliter = new SupplierSpliterator<G>(supplier);
			return new Seq<G>(spliter, env);
		}

		/**
		 * Creates a new sequential infinite unordered seq, which each element
		 * is generated by the given supply function.
		 *
		 * @param func a supply function
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> of_supply_func<G> (owned SupplyFunc<G> func, TaskEnv? env = null) {
			return of_supplier<G>( Supplier.from_func<G>((owned) func), env );
		}

		/**
		 * Creates a new sequential seq, which each element is generated by the
		 * given //next// function applied to the previous element, and the
		 * initial element is the //seed//. The seq terminates when
		 * //pred(item)// returns false.
		 *
		 * The returned seq is similar to the for-loop below:
		 *
		 * {{{
		 * for (G item = seed; pred(item); item = next(item)) {
		 *     // Operations on the item.
		 * }
		 * }}}
		 *
		 * @param seed the initial element
		 * @param pred a predicate function to determine when the seq
		 * terminates
		 * @param next a mapping function to produce a new element by applying
		 * to the previous element
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 * @return the result seq
		 */
		public static Seq<G> iterate<G> (owned G seed,
				owned Gee.Predicate<G> pred, owned Gee.MapFunc<G,G> next,
				TaskEnv? env = null) {
			var iter = new IterateIterator<G>((owned) seed, (owned) pred, (owned) next);
			return Seq.of_iterator<G>(iter, -1, false, env);
		}

		/**
		 * Creates a new sequential empty seq.
		 * @return an empty sequential seq
		 */
		public static Seq<G> empty<G> () {
			return new Seq<G>(Spliterator.empty<G>());
		}

		private Container<G,void*>? _container;
		private TaskEnv _task_env;
		private bool _is_parallel;
		private bool _is_closed;

		/**
		 * Creates a new sequential seq, optionally with a task environment.
		 *
		 * The seq can be changed to parallel mode by {@link Seq.parallel}.
		 *
		 * @param spliterator a spliterator used by the seq
		 * @param env a task environment. If not specified,
		 * {@link TaskEnv.get_default_task_env} is used.
		 */
		public Seq (Spliterator<G> spliterator, TaskEnv? env = null) {
			_container = new DefaultContainer<G>(spliterator, null, new Consumer<G>());
			_task_env = env != null ? env : TaskEnv.get_default_task_env();
		}

		private Seq.from_other (Seq<G> seq, Container<G,void*> container) {
			_container = container;
			_task_env = seq._task_env;
			_is_parallel = seq._is_parallel;
		}

		/**
		 * Copies this seq with the given container, and closes this seq.
		 * @return the copy of this seq
		 */
		private Seq<R> copy_and_close<R> (Container<G,void*> container) {
			Seq<R> result = new Seq<R>.from_other(this, container);
			close();
			return result;
		}

		/**
		 * The type of the elements.
		 */
		public Type element_type {
			get {
				return typeof(G);
			}
		}

		/**
		 * The task environment of this seq.
		 *
		 * This can be accessed even though this seq has been closed.
		 */
		public TaskEnv task_env {
			get {
				return _task_env;
			}
		}

		/**
		 * Whether or not this seq has been closed.
		 */
		public bool is_closed {
			get {
				return _is_closed;
			}
		}

		/**
		 * Closes this seq.
		 *
		 * This method unreferences (i.e. decreases the reference count of) the
		 * internal pipeline source input.
		 *
		 * If this seq has already been closed, this method does nothing.
		 */
		public void close () {
			if (_is_closed) return;
			_container = null;
			_is_closed = true;
		}

		/**
		 * Whether or not this seq is in parallel mode.
		 *
		 * This can be accessed even though this seq has been closed.
		 */
		public bool is_parallel {
			get {
				return _is_parallel;
			}
		}

		/**
		 * Returns a new equivalent seq that is sequential.
		 *
		 * This is a stateless intermediate operation.
		 *
		 * @return a new equivalent seq that is sequential
		 */
		public Seq<G> sequential () {
			assert(_is_closed == false);
			Seq<G> result = copy_and_close<G>(_container);
			result._is_parallel = false;
			return result;
		}

		/**
		 * Returns a new equivalent seq that is parallel.
		 *
		 * This is a stateless intermediate operation.
		 *
		 * @return a new equivalent seq that is parallel
		 */
		public Seq<G> parallel () {
			assert(_is_closed == false);
			Seq<G> result = copy_and_close<G>(_container);
			result._is_parallel = true;
			return result;
		}

		/**
		 * Returns an iterator for the elements of this seq.
		 *
		 * This is a non-eager terminal operation.
		 *
		 * @return an iterator for the elements
		 */
		public Iterator<G> iterator () {
			assert(_is_closed == false);
			Iterator<G> result = new ResultIterator<G>( new ResultSpliterator<G>(_container, this) );
			close();
			return result;
		}

		/**
		 * Returns a spliterator for the elements of this seq.
		 *
		 * This is a non-eager terminal operation.
		 *
		 * @return a spliterator for the elements
		 */
		public Spliterator<G> spliterator () {
			assert(_is_closed == false);
			Spliterator<G> result = new ResultSpliterator<G>(_container, this);
			close();
			return result;
		}

		/**
		 * Returns the count of elements in this seq.
		 *
		 * This operation may or may not traverse input, depending on the
		 * internal conditions.
		 *
		 * This is a terminal operation.
		 *
		 * @return a future of the count of elements
		 */
		public Future<int64?> count () {
			assert(_is_closed == false);
			if (_container.is_size_known && _container.estimated_size >= 0) {
				int64 result = _container.estimated_size;
				close();
				return Future.of<int64?>(result);
			} else if (_is_parallel) {
				return map<int64?>(g => 1)
					.fold<int64?>((g, a) => g + a, (a, b) => a + b, 0);
			} else {
				Future<void*> future = _container.start(this);
				Container<G,void*> container = (!)_container;
				close();
				return future.map<int64?>(value => {
					int64 result = 0;
					if (container.is_size_known && container.estimated_size >= 0) {
						result = container.estimated_size;
					} else {
						container.each(g => result++);
					}
					return result;
				});
			}
		}

		/**
		 * Returns a seq which contains the distinct elements of this seq, based
		 * on the given functions.
		 *
		 * This is a stateful intermediate operation.
		 *
		 * @param hash a //non-interfering// and //stateless// hash function. if
		 * not specified, {@link Gee.Functions.get_hash_func_for} is used to get
		 * a proper function
		 * @param equal a //non-interfering// and //stateless// equal function.
		 * if not specified, {@link Gee.Functions.get_equal_func_for} is used to
		 * get a proper function
		 * @return the new seq
		 */
		public Seq<G> distinct (
				owned HashDataFunc<G>? hash = null,
				owned EqualDataFunc<G>? equal = null) {
			assert(_is_closed == false);
			if (_container.is_size_known && _container.estimated_size <= 1) {
				return copy_and_close<G>(_container);
			} else {
				if (hash == null) hash = Functions.get_hash_func_for(element_type);
				if (equal == null) equal = Functions.get_equal_func_for(element_type);
				Container<G,G> container = new DistinctContainer<G>(_container, _container, (owned) hash, (owned) equal);
				return copy_and_close<G>(container);
			}
		}

		// TODO distinct_ordered

		/**
		 * Returns whether or not all elements of this seq match the given
		 * predicate. If the seq is empty, the result is true.
		 *
		 * This is a short-circuiting terminal operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return a future of the result -- true if either all elements match
		 * the given predicate or the seq is empty, otherwise false
		 */
		public Future<bool?> all_match (Predicate<G> pred) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<bool?>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					MatchTask<G> task = new MatchTask<G>(
							pred, MatchTask.Option.ALL,
							container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<bool?>(value => {
					return container.each_chunk(chunk => {
						for (int i = 0; i < chunk.length; i++) {
							if (!pred(chunk[i])) {
								return false;
							}
						}
						return true;
					});
				});
			}
		}

		/**
		 * Returns whether or not any elements of this seq match the given
		 * predicate. If the seq is empty, the result is false.
		 *
		 * This is a short-circuiting terminal operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return a future of the result -- true if any elements match the
		 * given predicate, otherwise false
		 */
		public Future<bool?> any_match (Predicate<G> pred) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<bool?>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					MatchTask<G> task = new MatchTask<G>(
							pred, MatchTask.Option.ANY,
							container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<bool?>(value => {
					return !container.each_chunk(chunk => {
						for (int i = 0; i < chunk.length; i++) {
							if (pred(chunk[i])) {
								return false;
							}
						}
						return true;
					});
				});
			}
		}

		/**
		 * Returns whether or not no elements of this seq match the given
		 * predicate. If the seq is empty, the result is true.
		 *
		 * This is a short-circuiting terminal operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return a future of the result -- true if either no elements match
		 * the given predicate or the seq is empty, otherwise false
		 */
		public Future<bool?> none_match (Predicate<G> pred) {
			return all_match(g => {
				return !pred(g);
			});
		}

		/**
		 * Returns an optional describing the any element that matches the given
		 * predicate, or an empty optional if not found.
		 *
		 * This is a short-circuiting terminal operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return a future of an optional describing the any element that
		 * matches the given, or an empty optional if not found.
		 */
		public Future<Optional<G>> find_any (Predicate<G> pred) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			if (_is_parallel) {
				Container<G,void*> container = (!)_container;
				close();
				return future.flat_map<Optional<G>>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					FindTask<G> task = new FindTask<G>(
							pred, FindTask.Option.ANY,
							container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return find_first(pred);
			}
		}

		/**
		 * Returns an optional describing the first element that matches the
		 * given predicate, or an empty optional if not found.
		 *
		 * This operation respects encounter order even though the seq is
		 * in parallel mode.
		 *
		 * This is a short-circuiting terminal operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return a future of an optional describing the first element that
		 * matches the given, or an empty optional if not found.
		 */
		public Future<Optional<G>> find_first (Predicate<G> pred) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<Optional<G>>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					FindTask<G> task = new FindTask<G>(
							pred, FindTask.Option.FIRST,
							container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<Optional<G>>(value => {
					G? result = null;
					bool found = false;
					container.each_chunk(chunk => {
						for (int i = 0; i < chunk.length; i++) {
							if (pred(chunk[i])) {
								result = chunk[i];
								found = true;
								return false;
							}
						}
						return true;
					});
					return found ? new Optional<G>.of(result) : new Optional<G>.empty();
				});
			}
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq after
		 * discarding the first //n// elements.
		 *
		 * On parallel execution, this operation doesn't respect encounter
		 * order.
		 *
		 * This is a stateful intermediate operation.
		 *
		 * @param n the number of elements to skip
		 * @return the new seq
		 */
		public Seq<G> skip (int64 n)
			requires (n >= 0)
		{
			return chop(n);
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq,
		 * truncated to be no longer than //n// in length.
		 *
		 * On parallel execution, this operation doesn't respect encounter
		 * order.
		 *
		 * This is a short-circuiting stateful intermediate operation.
		 *
		 * @param n maximum number of elements the seq may contain
		 * @return the new seq
		 */
		public Seq<G> limit (int64 n)
			requires (n >= 0)
		{
			return chop(0, n);
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq after
		 * discarding the first //n// elements, truncated to be no longer than
		 * //n// in length.
		 *
		 * On parallel execution, this operation doesn't respect encounter
		 * order.
		 *
		 * This is a stateful intermediate operation, and also short-circuiting
		 * if the given length is not negative.
		 *
		 * @param offset the number of elements to skip
		 * @param length maximum number of elements the seq may contain, or a
		 * negative value if unlimited
		 * @return the new seq
		 */
		public Seq<G> chop (int64 offset, int64 length = -1)
			requires (offset >= 0)
		{
			assert(_is_closed == false);
			if (offset == 0 && length < 0) {
				return copy_and_close<G>(_container);
			} else {
				Container<G,G> container = new SliceContainer<G>(_container, _container, offset, length, false);
				return copy_and_close<G>(container);
			}
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq after
		 * discarding the first //n// elements.
		 *
		 * This operation always respects encounter order.
		 *
		 * This is a stateful intermediate operation.
		 *
		 * This operation is quite expensive on parallel execution.
		 * Using {@link skip} instead or switching to sequential execution may
		 * improve performance.
		 *
		 * @param n the number of elements to skip
		 * @return the new seq
		 */
		public Seq<G> skip_ordered (int64 n)
			requires (n >= 0)
		{
			return chop_ordered(n);
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq,
		 * truncated to be no longer than //n// in length.
		 *
		 * This operation always respects encounter order.
		 *
		 * This is a short-circuiting stateful intermediate operation.
		 *
		 * This operation is quite expensive on parallel execution.
		 * Using {@link limit} instead or switching to sequential execution may
		 * improve performance.
		 *
		 * @param n maximum number of elements the seq may contain
		 * @return the new seq
		 */
		public Seq<G> limit_ordered (int64 n)
			requires (n >= 0)
		{
			return chop_ordered(0, n);
		}

		/**
		 * Returns a seq which contains the remaining elements of this seq after
		 * discarding the first //n// elements, truncated to be no longer than
		 * //n// in length.
		 *
		 * This operation always respects encounter order.
		 *
		 * This is a stateful intermediate operation, and also short-circuiting
		 * if the given length is not negative.
		 *
		 * This operation is quite expensive on parallel execution.
		 * Using {@link chop} instead or switching to sequential execution may
		 * improve performance.
		 *
		 * @param offset the number of elements to skip
		 * @param length maximum number of elements the seq may contain, or a
		 * negative value if unlimited
		 * @return the new seq
		 */
		public Seq<G> chop_ordered (int64 offset, int64 length = -1)
			requires (offset >= 0)
		{
			assert(_is_closed == false);
			if (offset == 0 && length < 0) {
				return copy_and_close<G>(_container);
			} else {
				Container<G,G> container = new SliceContainer<G>(_container, _container, offset, length, true);
				return copy_and_close<G>(container);
			}
		}

		/**
		 * Returns a seq which contains the elements of this seq that match the
		 * given predicate.
		 *
		 * This is a stateless intermediate operation.
		 *
		 * @param pred a //non-interfering// and //stateless// predicate
		 * @return the new seq
		 */
		public Seq<G> filter (owned Predicate<G> pred) {
			assert(_is_closed == false);
			Container<G,G> container = new FilteredContainer<G>(_container, _container, (owned) pred);
			return copy_and_close<G>(container);
		}

		/**
		 * Performs a reduction operation on the elements of this seq. This is
		 * equivalent to:
		 *
		 * {{{
		 * A result = identity;
		 * foreach (G g in seq) {
		 *     result = accumulator(g, result);
		 * }
		 * return result;
		 * }}}
		 *
		 * but is not constrained to execute sequentially.
		 *
		 * The identity value must be an identity for the combiner function. it
		 * means that: //a// is equal to //combiner(identity, a)//
		 *
		 * The combiner function must be compatible with the accumulator
		 * function. it means that: //accumulator(g, a)// is equal to
		 * //combiner(accumulator(identity, g), a)//
		 *
		 * This is a terminal operation.
		 *
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for accumulating
		 * @param combiner an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @param identity the identity value for the combiner function
		 * @return a future of the result of the reduction
		 */
		public Future<A> fold<A> (FoldFunc<A,G> accumulator, CombineFunc<A> combiner, A identity) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<A>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					FoldTask<A,G> task = new FoldTask<A,G>(
							accumulator, combiner, identity,
							container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<A>(value => {
					A result = identity;
					container.each(g => {
						result = accumulator(g, result);
					});
					return result;
				});
			}
		}

		/**
		 * Performs a reduction operation on the elements of this seq. This is
		 * equivalent to:
		 *
		 * {{{
		 * G? result = null;
		 * bool found = false;
		 * foreach (G g in seq) {
		 *     if (!found) {
		 *         result = g;
		 *         found = true;
		 *     } else {
		 *         result = accumulator(g, result);
		 *     }
		 * }
		 * return found ? new Optional<G>.of(result) : new Optional<G>.empty();
		 * }}}
		 *
		 * but is not constrained to execute sequentially.
		 *
		 * This is a terminal operation.
		 *
		 * @param accumulator an //associative//, //non-interfering//, and
		 * //stateless// function for combining two values
		 * @return a future of the result of the reduction
		 */
		public Future<Optional<G>> reduce (CombineFunc<G> accumulator) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<Optional<G>>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					ReduceTask<G> task = new ReduceTask<G>(
							accumulator, container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<Optional<G>>(value => {
					bool found = false;
					G? result = null;
					container.each(g => {
						if (!found) {
							found = true;
							result = g;
						} else {
							result = accumulator(result, g);
						}
					});
					return found ? new Optional<G>.of(result) : new Optional<G>.empty();
				});
			}
		}

		/**
		 * Returns a seq which contains the results of applying the given mapper
		 * function to the elements of this seq.
		 *
		 * This is a stateless intermediate operation.
		 *
		 * @param mapper a //non-interfering// and //stateless// mapping
		 * function
		 * @return the new seq
		 */
		public Seq<A> map<A> (owned MapFunc<A,G> mapper) {
			assert(_is_closed == false);
			Container<A,G> container = new MappedContainer<A,G>(_container, _container, (owned) mapper);
			return copy_and_close<A>(container);
		}

		/**
		 * Returns a seq which contains the elements of the results of applying
		 * the given mapper function to the elements of this seq.
		 *
		 * This is a stateless intermediate operation.
		 *
		 * @param mapper a //non-interfering// and //stateless// mapping
		 * function. if it returns an {@link Gee.Iterator.valid} iterator, the
		 * element that the iterator points is also included in the result.
		 * @return the new seq
		 */
		public Seq<A> flat_map<A> (owned FlatMapFunc<A,G> mapper) {
			assert(_is_closed == false);
			Container<A,G> container = new FlatMappedContainer<A,G>(_container, _container, (owned) mapper);
			return copy_and_close<A>(container);
		}

		/**
		 * Returns the maximum element of this seq, based on the given compare
		 * function.
		 *
		 * This is a terminal operation.
		 *
		 * @param compare a //non-interfering// and //stateless// compare
		 * function. if not specified, {@link Gee.Functions.get_compare_func_for}
		 * is used to get a proper function
		 * @return a future of an optional describing the maximum element, or
		 * an empty optional if the seq is empty
		 */
		public Future<Optional<G>> max (owned CompareDataFunc<G>? compare = null) {
			if (compare == null) {
				compare = Functions.get_compare_func_for(element_type);
			}
			return reduce((a, b) => {
				return compare(a, b) >= 0 ? a : b;
			}).then(future => { // for keeping block data
				compare = null;
			});
		}

		/**
		 * Returns the minimum element of this seq, based on the given compare
		 * function.
		 *
		 * This is a terminal operation.
		 *
		 * @param compare a //non-interfering// and //stateless// compare
		 * function. if not specified, {@link Gee.Functions.get_compare_func_for}
		 * is used to get a proper function
		 * @return a future of an optional describing the minimum element, or
		 * an empty optional if the seq is empty
		 */
		public Future<Optional<G>> min (owned CompareDataFunc<G>? compare = null) {
			if (compare == null) {
				compare = Functions.get_compare_func_for(element_type);
			}
			return reduce((a, b) => {
				return compare(a, b) <= 0 ? a : b;
			}).then(future => { // for keeping block data
				compare = null;
			});
		}

		/**
		 * Returns a seq which contains the elements of this seq, sorted based
		 * on the given compare function. The sort is stable.
		 *
		 * This is a stateful intermediate operation.
		 *
		 * @param compare a //non-interfering// and //stateless// compare
		 * function. if not specified, {@link Gee.Functions.get_compare_func_for}
		 * is used to get a proper function
		 * @return the new seq
		 */
		public Seq<G> order_by (owned CompareDataFunc<G>? compare = null) {
			assert(_is_closed == false);
			if (_container.is_size_known && _container.estimated_size <= 1) {
				return copy_and_close<G>(_container);
			} else {
				if (compare == null) {
					compare = Functions.get_compare_func_for(element_type);
				}
				Container<G,G> container = new SortedContainer<G>(_container, _container, (owned) compare);
				return copy_and_close<G>(container);
			}
		}

		/**
		 * Applies the given function to each element of this seq.
		 *
		 * This is a terminal operation.
		 *
		 * @param f a //non-interfering// function
		 * @return a future that will be completed with null, or the error if
		 * an error occurs during the operation
		 */
		public Future<void*> foreach (owned Func<G> f) {
			assert(_is_closed == false);
			Future<void*> future = _container.start(this);
			Container<G,void*> container = (!)_container;
			close();
			if (_is_parallel) {
				return future.flat_map<void*>(value => {
					int64 len = container.estimated_size;
					int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
					int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
					ForEachTask<G> task = new ForEachTask<G>(
							f, container, null,
							threshold, max_depth, _task_env.executor);
					task.fork();
					return task.future;
				});
			} else {
				return future.map<void*>(value => {
					container.each(f);
					return null;
				});
			}
		}

		/**
		 * Performs a mutable reduction operation on the elements of this seq.
		 *
		 * If the seq is in parallel mode and the collector is CONCURRENT,
		 * performs a concurrent reduction.
		 *
		 * This is a terminal operation.
		 *
		 * @param collector the collector describing the reduction
		 * @return a future of the result of the reduction
		 * @see Collector
		 */
		public Future<R> collect<R,A> (Collector<R,A,G> collector) {
			assert(_is_closed == false);
			if (_is_parallel) {
				if (CollectorFeatures.CONCURRENT in collector.features) {
					A accumulator;
					try {
						accumulator = collector.create_accumulator();
					} catch (Error err) {
						close();
						var promise = new Promise<R>();
						promise.set_exception((owned) err);
						return promise.future;
					}
					return this.foreach(g => {
						collector.accumulate(g, accumulator);
					}).map<R>(value => {
						return collector.finish(accumulator);
					});
				} else {
					return collect_ordered<R,A>(collector);
				}
			} else {
				return collect_ordered<R,A>(collector);
			}
		}

		/**
		 * Performs a mutable reduction operation on the elements of this seq.
		 *
		 * This operation preserves encounter order even though the seq is in
		 * parallel mode, if the collector is not CONCURRENT or not UNORDERED.
		 * If the seq is in parallel mode and the collector is CONCURRENT and
		 * UNORDERED, performs an unordered concurrent reduction.
		 *
		 * This is a terminal operation.
		 *
		 * @param collector the collector describing the reduction
		 * @return a future of the result of the reduction
		 * @see Collector
		 */
		public Future<R> collect_ordered<R,A> (Collector<R,A,G> collector) {
			assert(_is_closed == false);
			if (_is_parallel) {
				if (CollectorFeatures.CONCURRENT in collector.features
				&& CollectorFeatures.UNORDERED in collector.features) {
					return collect<R,A>(collector);
				} else {
					Future<void*> future = _container.start(this);
					Container<G,void*> container = (!)_container;
					close();
					return future.flat_map<A>(value => {
						int64 len = container.estimated_size;
						int64 threshold = _task_env.resolve_threshold(len, _task_env.executor.parallels);
						int max_depth = _task_env.resolve_max_depth(len, _task_env.executor.parallels);
						CollectTask<A,G> task = new CollectTask<A,G>(
								collector, container, null,
								threshold, max_depth, _task_env.executor);
						task.fork();
						return task.future;
					}).map<R>(accumulator => {
						return collector.finish(accumulator);
					});
				}
			} else {
				Future<void*> future = _container.start(this);
				Container<G,void*> container = (!)_container;
				close();
				return future.map<R>(value => {
					A accumulator = collector.create_accumulator();
					container.each(g => {
						collector.accumulate(g, accumulator);
					});
					return collector.finish(accumulator);
				});
			}
		}

		/**
		 * Groups the elements based on the //classifier// function and returns
		 * the results in a map.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map and list.
		 *
		 * This is equivalent to:
		 *
		 * {{{
		 * seq.collect( Collectors.group_by(classifier) );
		 * }}}
		 *
		 * This is a terminal operation.
		 *
		 * @param classifier a classifier function mapping elements to keys
		 * @return a future of the result map
		 * @see Collectors.group_by
		 */
		public Future< Map<K,Gee.List<G>> > group_by<K> (owned MapFunc<K,G> classifier) {
			return collect( Collectors.group_by<K,G>((owned)classifier) );
		}

		/**
		 * Partitions the elements based on the //pred// function and returns
		 * the results in a map.
		 *
		 * The result map always contains lists for both true and false keys.
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map and list.
		 *
		 * This is equivalent to:
		 *
		 * {{{
		 * seq.collect( Collectors.partition(pred) );
		 * }}}
		 *
		 * This is a terminal operation.
		 *
		 * @param pred a predicate function
		 * @return a future of the result map
		 * @see Collectors.partition
		 */
		public Future< Map<bool,Gee.List<G>> > partition (owned Predicate<G> pred) {
			return collect( Collectors.partition<G>((owned)pred) );
		}
	}
}
