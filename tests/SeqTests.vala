/* SeqTests.vala
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

using Gpseq;
using Gee;
using TestUtils;

public abstract class SeqTests<G> : Gpseq.TestSuite {
	private const int64 LENGTH = 65536;
	private const int64 SKIP = 16384;
	private const int64 LIMIT = 32768;
	private const int64 OVERSIZE = LENGTH + 726;

	private int64 __length;
	private int64 __skip;
	private int64 __limit;
	private int64 __oversize;

	public SeqTests (string name) {
		base(name);
		register_tests();
	}

	private void register_tests () {
		add_test("element_type", test_element_type);
		add_test("sequential", test_sequential);
		add_test("parallel", test_parallel);

		add_test("closed", () => test_closed(false));
		add_test("closed:parallel", () => test_closed(true));

		add_test("sequential-ready", () => test_sequential_ready);

		add_test("iterator", test_iterator, prepare);
		add_test("spliterator", test_spliterator, prepare);

		add_test("count", test_count, prepare);
		add_test("count:filtered", () => test_filtered_count(false), prepare);
		add_test("count:filtered:parallel", () => test_filtered_count(true), prepare);

		add_test("distinct", () => test_distinct(false), prepare);
		add_test("distinct:parallel", () => test_distinct(true), prepare);

		add_test("all_match", () => test_all_match(false), prepare);
		add_test("all_match:parallel", () => test_all_match(true), prepare);
		add_test("any_match", () => test_any_match(false), prepare);
		add_test("any_match:parallel", () => test_any_match(true), prepare);
		add_test("none_match", () => test_none_match(false), prepare);
		add_test("none_match:parallel", () => test_none_match(true), prepare);

		add_test("find_any", () => test_find_any(false), prepare);
		add_test("find_any:parallel", () => test_find_any(true), prepare);
		add_test("find_first", () => test_find_first(false), prepare);
		add_test("find_first:parallel", () => test_find_first(true), prepare);

		add_test("skip", () => test_skip(false, __skip), prepare);
		add_test("skip:parallel", () => test_skip(true, __skip), prepare);
		add_test("skip:zero", () => test_skip(false, 0), prepare);
		add_test("skip:zero:parallel", () => test_skip(true, 0), prepare);
		add_test("skip:oversize", () => test_skip(false, __oversize), prepare);
		add_test("skip:oversize:parallel", () => test_skip(true, __oversize), prepare);
		add_test("limit", () => test_limit(false, __limit), prepare);
		add_test("limit:parallel", () => test_limit(true, __limit), prepare);
		add_test("limit:oversize", () => test_limit(false, __oversize), prepare);
		add_test("limit:oversize:parallel", () => test_limit(true, __oversize), prepare);
		add_test("limit:short-circuit-infinite", () => test_limit_short_circuiting(false), prepare);
		add_test("limit:short-circuit-infinite:parallel", () => test_limit_short_circuiting(true), prepare);
		add_test("chop", () => test_chop(false, __skip, __limit), prepare);
		add_test("chop:parallel", () => test_chop(true, __skip, __limit), prepare);
		add_test("chop:zero-skip", () => test_chop(false, 0, __limit), prepare);
		add_test("chop:zero-skip:parallel", () => test_chop(true, 0, __limit), prepare);
		add_test("chop:oversize-skip", () => test_chop(false, __oversize, __limit), prepare);
		add_test("chop:oversize-skip:parallel", () => test_chop(true, __oversize, __limit), prepare);
		add_test("chop:zero-limit", () => test_chop(false, __skip, 0), prepare);
		add_test("chop:zero-limit:parallel", () => test_chop(true, __skip, 0), prepare);
		add_test("chop:oversize-limit", () => test_chop(false, __skip, __oversize), prepare);
		add_test("chop:oversize-limit:parallel", () => test_chop(true, __skip, __oversize), prepare);
		add_test("chop:unlimited", () => test_chop(false, __skip, -1), prepare);
		add_test("chop:unlimited:parallel", () => test_chop(true, __skip, -1), prepare);
		add_test("chop:zero-skip:zero-limit", () => test_chop(false, 0, 0), prepare);
		add_test("chop:zero-skip:zero-limit:parallel", () => test_chop(true, 0, 0), prepare);
		add_test("chop:zero-skip:oversize-limit", () => test_chop(false, 0, __oversize), prepare);
		add_test("chop:zero-skip:oversize-limit:parallel", () => test_chop(true, 0, __oversize), prepare);
		add_test("chop:zero-skip:unlimited", () => test_chop(false, 0, -1), prepare);
		add_test("chop:zero-skip:unlimited:parallel", () => test_chop(true, 0, -1), prepare);
		add_test("chop:oversize-skip:zero-limit", () => test_chop(false, __oversize, 0), prepare);
		add_test("chop:oversize-skip:zero-limit:parallel", () => test_chop(true, __oversize, 0), prepare);
		add_test("chop:oversize-skip:oversize-limit", () => test_chop(false, __oversize, __oversize), prepare);
		add_test("chop:oversize-skip:oversize-limit:parallel", () => test_chop(true, __oversize, __oversize), prepare);
		add_test("chop:oversize-skip:unlimited", () => test_chop(false, __oversize, -1), prepare);
		add_test("chop:oversize-skip:unlimited:parallel", () => test_chop(true, __oversize, -1), prepare);
		add_test("chop:short-circuit-infinite", () => test_chop_short_circuiting(false), prepare);
		add_test("chop:short-circuit-infinite:parallel", () => test_chop_short_circuiting(true), prepare);

		add_test("skip_ordered", () => test_skip_ordered(false, __skip), prepare);
		add_test("skip_ordered:parallel", () => test_skip_ordered(true, __skip), prepare);
		add_test("skip_ordered:zero", () => test_skip_ordered(false, 0), prepare);
		add_test("skip_ordered:zero:parallel", () => test_skip_ordered(true, 0), prepare);
		add_test("skip_ordered:oversize", () => test_skip_ordered(false, __oversize), prepare);
		add_test("skip_ordered:oversize:parallel", () => test_skip_ordered(true, __oversize), prepare);
		add_test("limit_ordered", () => test_limit_ordered(false, __limit), prepare);
		add_test("limit_ordered:parallel", () => test_limit_ordered(true, __limit), prepare);
		add_test("limit_ordered:oversize", () => test_limit_ordered(false, __oversize), prepare);
		add_test("limit_ordered:oversize:parallel", () => test_limit_ordered(true, __oversize), prepare);
		add_test("limit_ordered:short-circuit-infinite", () => test_limit_ordered_short_circuiting(false), prepare);
		add_test("limit_ordered:short-circuit-infinite:parallel", () => test_limit_ordered_short_circuiting(true), prepare);
		add_test("chop_ordered", () => test_chop_ordered(false, __skip, __limit), prepare);
		add_test("chop_ordered:parallel", () => test_chop_ordered(true, __skip, __limit), prepare);
		add_test("chop_ordered:zero-skip", () => test_chop_ordered(false, 0, __limit), prepare);
		add_test("chop_ordered:zero-skip:parallel", () => test_chop_ordered(true, 0, __limit), prepare);
		add_test("chop_ordered:oversize-skip", () => test_chop_ordered(false, __oversize, __limit), prepare);
		add_test("chop_ordered:oversize-skip:parallel", () => test_chop_ordered(true, __oversize, __limit), prepare);
		add_test("chop_ordered:zero-limit", () => test_chop_ordered(false, __skip, 0), prepare);
		add_test("chop_ordered:zero-limit:parallel", () => test_chop_ordered(true, __skip, 0), prepare);
		add_test("chop_ordered:oversize-limit", () => test_chop_ordered(false, __skip, __oversize), prepare);
		add_test("chop_ordered:oversize-limit:parallel", () => test_chop_ordered(true, __skip, __oversize), prepare);
		add_test("chop_ordered:unlimited", () => test_chop_ordered(false, __skip, -1), prepare);
		add_test("chop_ordered:unlimited:parallel", () => test_chop_ordered(true, __skip, -1), prepare);
		add_test("chop_ordered:zero-skip:zero-limit", () => test_chop_ordered(false, 0, 0), prepare);
		add_test("chop_ordered:zero-skip:zero-limit:parallel", () => test_chop_ordered(true, 0, 0), prepare);
		add_test("chop_ordered:zero-skip:oversize-limit", () => test_chop_ordered(false, 0, __oversize), prepare);
		add_test("chop_ordered:zero-skip:oversize-limit:parallel", () => test_chop_ordered(true, 0, __oversize), prepare);
		add_test("chop_ordered:zero-skip:unlimited", () => test_chop_ordered(false, 0, -1), prepare);
		add_test("chop_ordered:zero-skip:unlimited:parallel", () => test_chop_ordered(true, 0, -1), prepare);
		add_test("chop_ordered:oversize-skip:zero-limit", () => test_chop_ordered(false, __oversize, 0), prepare);
		add_test("chop_ordered:oversize-skip:zero-limit:parallel", () => test_chop_ordered(true, __oversize, 0), prepare);
		add_test("chop_ordered:oversize-skip:oversize-limit", () => test_chop_ordered(false, __oversize, __oversize), prepare);
		add_test("chop_ordered:oversize-skip:oversize-limit:parallel", () => test_chop_ordered(true, __oversize, __oversize), prepare);
		add_test("chop_ordered:oversize-skip:unlimited", () => test_chop_ordered(false, __oversize, -1), prepare);
		add_test("chop_ordered:oversize-skip:unlimited:parallel", () => test_chop_ordered(true, __oversize, -1), prepare);
		add_test("chop_ordered:short-circuit-infinite", () => test_chop_ordered_short_circuiting(false), prepare);
		add_test("chop_ordered:short-circuit-infinite:parallel", () => test_chop_ordered_short_circuiting(true), prepare);

		add_test("filter", test_filter, prepare);

		add_test("fold", () => test_fold(false), prepare);
		add_test("fold:parallel", () => test_fold(true), prepare);
		add_test("reduce", () => test_reduce(false), prepare);
		add_test("reduce:parallel", () => test_reduce(true), prepare);

		add_test("map", test_map, prepare);
		add_test("flat_map", test_flat_map, prepare);

		add_test("max", () => test_max(false), prepare);
		add_test("max:parallel", () => test_max(true), prepare);
		add_test("min", () => test_min(false), prepare);
		add_test("min:parallel", () => test_min(true), prepare);

		add_test("order_by", () => test_order_by(false), prepare);
		add_test("order_by:parallel", () => test_order_by(true), prepare);
		add_test("order_by:check-stable", () => test_stable_order_by(false), prepare);
		add_test("order_by:check-stable:parallel", () => test_stable_order_by(true), prepare);

		add_test("foreach", () => test_foreach(false), prepare);
		add_test("foreach:parallel", () => test_foreach(true), prepare);

		add_test("collect", () => test_collect(false), prepare);
		add_test("collect:parallel", () => test_collect(true), prepare);
		add_test("collect_ordered", () => test_collect_ordered(false), prepare);
		add_test("collect_ordered:parallel", () => test_collect_ordered(true), prepare);

		add_test("complex-fold", () => test_complex_fold(false), prepare);
		add_test("complex-fold:parallel", () => test_complex_fold(true), prepare);

		add_test("collector-to_generic_array", () => test_collector_to_generic_array(false), prepare);
		add_test("collector-to_generic_array:parallel", () => test_collector_to_generic_array(true), prepare);
		add_test("collector-to_generic_array:ordered", () => test_collector_to_generic_array(false, true), prepare);
		add_test("collector-to_generic_array:ordered:parallel", () => test_collector_to_generic_array(true, true), prepare);
		add_test("collector-to_collection", () => test_collector_to_collection(false), prepare);
		add_test("collector-to_collection:parallel", () => test_collector_to_collection(true), prepare);
		add_test("collector-to_collection:ordered", () => test_collector_to_collection(false, true), prepare);
		add_test("collector-to_collection:ordered:parallel", () => test_collector_to_collection(true, true), prepare);
		add_test("collector-to_list", () => test_collector_to_list(false), prepare);
		add_test("collector-to_list:parallel", () => test_collector_to_list(true), prepare);
		add_test("collector-to_list:ordered", () => test_collector_to_list(false, true), prepare);
		add_test("collector-to_list:ordered:parallel", () => test_collector_to_list(true, true), prepare);
		/*
		add_test("collector-to_concurrent_list", () => test_collector_to_concurrent_list(false), prepare);
		add_test("collector-to_concurrent_list:parallel", () => test_collector_to_concurrent_list(true), prepare);
		add_test("collector-to_concurrent_list:ordered", () => test_collector_to_concurrent_list(false, true), prepare);
		add_test("collector-to_concurrent_list:ordered:parallel", () => test_collector_to_concurrent_list(true, true), prepare);
		*/
		add_test("collector-to_set", () => test_collector_to_set(false), prepare);
		add_test("collector-to_set:parallel", () => test_collector_to_set(true), prepare);
		add_test("collector-to_set:ordered", () => test_collector_to_set(false, true), prepare);
		add_test("collector-to_set:ordered:parallel", () => test_collector_to_set(true, true), prepare);
		add_test("collector-to_map", () => test_collector_to_map(false), prepare);
		add_test("collector-to_map:parallel", () => test_collector_to_map(true), prepare);
		add_test("collector-to_map:ordered", () => test_collector_to_map(false, true), prepare);
		add_test("collector-to_map:ordered:parallel", () => test_collector_to_map(true, true), prepare);

		add_test("collector-sum_int", () => test_collector_sum_int(false), prepare);
		add_test("collector-sum_int:parallel", () => test_collector_sum_int(true), prepare);
		add_test("collector-sum_uint", () => test_collector_sum_uint(false), prepare);
		add_test("collector-sum_uint:parallel", () => test_collector_sum_uint(true), prepare);
		add_test("collector-sum_long", () => test_collector_sum_long(false), prepare);
		add_test("collector-sum_long:parallel", () => test_collector_sum_long(true), prepare);
		add_test("collector-sum_ulong", () => test_collector_sum_ulong(false), prepare);
		add_test("collector-sum_ulong:parallel", () => test_collector_sum_ulong(true), prepare);
		add_test("collector-sum_int32", () => test_collector_sum_int32(false), prepare);
		add_test("collector-sum_int32:parallel", () => test_collector_sum_int32(true), prepare);
		add_test("collector-sum_uint32", () => test_collector_sum_uint32(false), prepare);
		add_test("collector-sum_uint32:parallel", () => test_collector_sum_uint32(true), prepare);
		add_test("collector-sum_int64", () => test_collector_sum_int64(false), prepare);
		add_test("collector-sum_int64:parallel", () => test_collector_sum_int64(true), prepare);
		add_test("collector-sum_uint64", () => test_collector_sum_uint64(false), prepare);
		add_test("collector-sum_uint64:parallel", () => test_collector_sum_uint64(true), prepare);

		add_test("collector-group_by", () => test_collector_group_by(false), prepare);
		add_test("collector-group_by:parallel", () => test_collector_group_by(true), prepare);
		add_test("collector-group_by:ordered", () => test_collector_group_by(false, true), prepare);
		add_test("collector-group_by:ordered:parallel", () => test_collector_group_by(true, true), prepare);
		add_test("collector-partition", () => test_collector_partition(false), prepare);
		add_test("collector-partition:parallel", () => test_collector_partition(true), prepare);
		add_test("collector-partition:ordered", () => test_collector_partition(false, true), prepare);
		add_test("collector-partition:ordered:parallel", () => test_collector_partition(true, true), prepare);

		add_test("collector-max", () => test_collector_max(false), prepare);
		add_test("collector-max:parallel", () => test_collector_max(true), prepare);
		add_test("collector-max:ordered", () => test_collector_max(false, true), prepare);
		add_test("collector-max:ordered:parallel", () => test_collector_max(true, true), prepare);
		add_test("collector-min", () => test_collector_min(false), prepare);
		add_test("collector-min:parallel", () => test_collector_min(true), prepare);
		add_test("collector-min:ordered", () => test_collector_min(false, true), prepare);
		add_test("collector-min:ordered:parallel", () => test_collector_min(true, true), prepare);
		add_test("collector-count", () => test_collector_count(false), prepare);
		add_test("collector-count:parallel", () => test_collector_count(true), prepare);
		add_test("collector-count:ordered", () => test_collector_count(false, true), prepare);
		add_test("collector-count:ordered:parallel", () => test_collector_count(true, true), prepare);
		add_test("collector-fold", () => test_collector_fold(false), prepare);
		add_test("collector-fold:parallel", () => test_collector_fold(true), prepare);
		add_test("collector-fold:ordered", () => test_collector_fold(false, true), prepare);
		add_test("collector-fold:ordered:parallel", () => test_collector_fold(true, true), prepare);
		add_test("collector-reduce", () => test_collector_reduce(false), prepare);
		add_test("collector-reduce:parallel", () => test_collector_reduce(true), prepare);
		add_test("collector-reduce:ordered", () => test_collector_reduce(false, true), prepare);
		add_test("collector-reduce:ordered:parallel", () => test_collector_reduce(true, true), prepare);
		add_test("collector-filter", () => test_collector_filter(false), prepare);
		add_test("collector-filter:parallel", () => test_collector_filter(true), prepare);
		add_test("collector-filter:ordered", () => test_collector_filter(false, true), prepare);
		add_test("collector-filter:ordered:parallel", () => test_collector_filter(true, true), prepare);
		add_test("collector-tee", () => test_collector_tee(false), prepare);
		add_test("collector-tee:parallel", () => test_collector_tee(true), prepare);
		add_test("collector-tee:ordered", () => test_collector_tee(false, true), prepare);
		add_test("collector-tee:ordered:parallel", () => test_collector_tee(true, true), prepare);
		add_test("collector-map", () => test_collector_map(false), prepare);
		add_test("collector-map:parallel", () => test_collector_map(true), prepare);
		add_test("collector-map:ordered", () => test_collector_map(false, true), prepare);
		add_test("collector-map:ordered:parallel", () => test_collector_map(true, true), prepare);
		add_test("collector-wrap", () => test_collector_wrap(false), prepare);
		add_test("collector-wrap:parallel", () => test_collector_wrap(true), prepare);
		add_test("collector-wrap:ordered", () => test_collector_wrap(false, true), prepare);
		add_test("collector-wrap:ordered:parallel", () => test_collector_wrap(true, true), prepare);
	}

	/**
	 * Creates a sequential infinite unordered seq of random elements.
	 * @return the created seq
	 */
	protected abstract Seq<G> create_rand_seq ();

	/**
	 * Creates an iterator of random elements.
	 * @return the created iterator
	 */
	protected abstract Iterator<G> create_rand_iter (int64 length, uint32? seed = null);

	/**
	 * Creates an iterator of distinct elements.
	 * @return the created iterator
	 */
	protected abstract Iterator<G> create_distinct_iter (int64 length);

	protected abstract uint hash (G g);
	protected abstract bool equal (G a, G b);
	protected abstract int compare (G a, G b);
	protected abstract bool filter (G g);
	protected abstract G random ();
	protected abstract G combine (owned G a, owned G b);
	protected abstract G identity ();
	protected abstract string map_to_str (owned G g);
	protected abstract Iterator<G> flat_map (owned G g);
	protected abstract int map_to_int (owned G g);

	private Seq<G> empty_seq (bool parallel = false) {
		Seq<G> seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		return seq;
	}

	private void prepare () {
		__length = LENGTH;
		__skip = SKIP;
		__limit = LIMIT;
		__oversize = OVERSIZE;
		TaskEnv.set_default_task_env( TestTaskEnv.get_instance() );
	}

	private void test_element_type () {
		assert(empty_seq().element_type == typeof(G));
	}

	private void test_sequential () {
		Seq<G> seq = empty_seq(true);
		assert(seq.is_parallel);
		assert(!seq.sequential().is_parallel);
	}

	private void test_parallel () {
		Seq<G> seq = empty_seq(false);
		assert(!seq.is_parallel);
		assert(seq.parallel().is_parallel);
	}

	private void test_closed (bool parallel) {
		Seq<G> seq;
		seq = empty_seq(parallel); seq.close(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.sequential(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.parallel(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.iterator(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.spliterator(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.count(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.distinct(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.all_match(g => false); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.any_match(g => true); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.none_match(g => true); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.find_any(g => true); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.find_first(g => true); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.skip(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.limit(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.chop(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.skip_ordered(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.limit_ordered(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.chop_ordered(0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.filter(() => true); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.fold<void*>(g => { return null; }, (a, b) => { return null; }, null); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.reduce((a, b) => { return a; }); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.map<G>(g => { return g; }); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.flat_map<G>(g => Collection.empty<G>().iterator()); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.max(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.min(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.order_by(); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.foreach(g => {}); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.collect( Collectors.sum_int<G>(() => 0) ); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.collect_ordered( Collectors.sum_int<G>(() => 0) ); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.group_by<int>(g => 0); assert(seq.is_closed);
		seq = empty_seq(parallel); seq.partition(g => true); assert(seq.is_closed);
	}

	private void test_sequential_ready () {
		assert( create_rand_seq().limit(LENGTH).count().ready );
		assert( create_rand_seq().limit(LENGTH).all_match(g => true).ready );
		assert( create_rand_seq().limit(LENGTH).any_match(g => false).ready );
		assert( create_rand_seq().limit(LENGTH).none_match(g => false).ready );
		assert( create_rand_seq().limit(LENGTH).find_any(g => false).ready );
		assert( create_rand_seq().limit(LENGTH).find_first(g => false).ready );
		assert( create_rand_seq().limit(LENGTH).fold<void*>(g => { return null; }, (a, b) => { return null; }, null).ready );
		assert( create_rand_seq().limit(LENGTH).reduce((a, b) => { return a; }).ready );
		assert( create_rand_seq().limit(LENGTH).max().ready );
		assert( create_rand_seq().limit(LENGTH).min().ready );
		assert( create_rand_seq().limit(LENGTH).foreach(g => {}).ready );
		assert( create_rand_seq().limit(LENGTH).collect(Collectors.sum_int<G>(() => 0)).ready );
		assert( create_rand_seq().limit(LENGTH).collect_ordered(Collectors.sum_int<G>(() => 0)).ready );
		assert( create_rand_seq().limit(LENGTH).group_by<int>(g => 0).ready );
		assert( create_rand_seq().limit(LENGTH).partition(g => true).ready );
	}

	private void test_iterator () {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Iterator<G> result = Seq.of_iterator<G>(iters[0], __length, true).iterator();
		assert_iter_equals(result, iters[1], equal);
	}

	private void test_spliterator () {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Spliterator<G> result = Seq.of_iterator<G>(iters[0], __length, true).spliterator();
		assert(result.is_size_known);
		assert(result.estimated_size == __length);
		G? item = null;
		try {
			while (result.try_advance(g => item = g)) {
				assert( iters[1].has_next() );
				iters[1].next();
				assert( equal(item, iters[1].get()) );
			}
		} catch (Error err) {
			error("%s", err.message);
		}
	}

	private void test_count () {
		Iterator<G> iter = create_rand_iter(__length);
		int64 result = (!) Seq.of_iterator<G>(iter, __length, true).count().value;
		assert(result == __length);
	}

	private void test_filtered_count (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.filter((g) => filter(g)).count().value;
		int64 validation = 0;
		while (iters[1].next()) {
			if ( filter(iters[1].get()) ) {
				validation++;
			}
		}
		assert(result == validation);
	}

	private void test_distinct (bool parallel) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();
		Iterator<G> result = seq.distinct(hash, equal).iterator();
		GenericArray<G> result_array = iter_to_generic_array<G>(result);

		GenericArray<G> validation = new GenericArray<G>(result_array.length);
		Set<G> seen = new HashSet<G>(hash, equal);
		while (iters[1].next()) {
			G item = iters[1].get();
			if (!seen.contains(item)) {
				seen.add(item);
				validation.add(item);
			}
		}

		if (parallel) {
			result_array.sort_with_data(compare);
			validation.sort_with_data(compare);
		}
		assert_array_equals<G>(result_array.data, validation.data, equal);
	}

	private void test_all_match (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(3);

		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		assert( (!)seq.all_match(g => true).value );

		seq = Seq.of_iterator<G>(iters[1], __length, true);
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.all_match(g => false).value );

		assert(__length > 1);
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		int i = 0;
		assert( !(!)seq.all_match(g => AtomicInt.compare_and_exchange(ref i, 0, 1)).value );

		// empty
		seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		assert( (!)seq.all_match(g => false).value );

		// short-circuiting
		seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.all_match(g => false).value );
	}

	private void test_any_match (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(4);

		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		assert( (!)seq.any_match(g => true).value );

		seq = Seq.of_iterator<G>(iters[1], __length, true);
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.any_match(g => false).value );

		assert(__length > 1);
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		G? pick = iter_pick_random<G>(iters[3], __length);
		assert( (!)seq.any_match(g => equal(g, pick)).value );

		// empty
		seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.any_match(g => true).value );

		// short-circuiting
		seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		assert( (!)seq.any_match(g => true).value );
	}

	private void test_none_match (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(4);

		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.none_match(g => true).value );

		seq = Seq.of_iterator<G>(iters[1], __length, true);
		if (parallel) seq = seq.parallel();
		assert( (!)seq.none_match(g => false).value );

		assert(__length > 1);
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		G? pick = iter_pick_random<G>(iters[3], __length);
		assert( !(!)seq.none_match(g => equal(g, pick)).value );

		// empty
		seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		assert( (!)seq.none_match(g => true).value );

		// short-circuiting
		seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		assert( !(!)seq.none_match(g => true).value );
	}

	private void test_find_any (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(4);

		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		assert( seq.find_any(g => true).value.is_present );

		seq = Seq.of_iterator<G>(iters[1], __length, true);
		if (parallel) seq = seq.parallel();
		assert( !seq.find_any(g => false).value.is_present );

		assert(__length > 1);
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		G? pick = iter_pick_random<G>(iters[3], __length);
		assert( equal(seq.find_any(g => equal(g, pick)).value.value, pick) );

		// empty
		seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		assert( !seq.find_any(g => true).value.is_present );

		// short-circuiting
		seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		assert( seq.find_any(g => true).value.is_present );
	}

	private void test_find_first (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(4);

		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		assert( seq.find_first(g => true).value.is_present );

		seq = Seq.of_iterator<G>(iters[1], __length, true);
		if (parallel) seq = seq.parallel();
		assert( !seq.find_first(g => false).value.is_present );

		assert(__length > 1);
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		G? pick = iter_pick_random<G>(iters[3], __length);
		assert( equal(seq.find_first(g => equal(g, pick)).value.value, pick) );

		// empty
		seq = Seq.empty<G>();
		if (parallel) seq = seq.parallel();
		assert( !seq.find_first(g => true).value.is_present );

		// short-circuiting
		seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		assert( seq.find_first(g => true).value.is_present );

		// encounter order
		assert(__length > 1);
		Iterator<G> iter = create_distinct_iter(__length);
		int64 idx0 = 0;
		int64 idx1 = 0;
		G? pick0 = null;
		G? pick1 = null;
		G? first = null;
		while (idx0 == idx1) {
			iters = iter.tee(3);
			pick0 = iter_pick_random<G>(iters[0], __length, out idx0);
			pick1 = iter_pick_random<G>(iters[1], __length, out idx1);
			first = idx0 <= idx1 ? pick0 : pick1;
		}
		seq = Seq.of_iterator<G>(iters[2], __length, true);
		if (parallel) seq = seq.parallel();
		Optional<G> result = seq.find_first(g => {
			return equal(g, pick0) || equal(g, pick1);
		}).value;
		assert( equal(result.value, first) );
	}

	private void test_skip (bool parallel, int64 skip) {
		Iterator<G> iter = create_rand_iter(__length);
		Seq<G> seq = Seq.of_iterator<G>(iter, __length, true);
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.skip(skip).count().value;
		int64 validation = skip < __length ? __length - skip : 0;
		assert(result == validation);
	}

	private void test_limit (bool parallel, int64 limit) {
		Iterator<G> iter = create_rand_iter(__length);
		Seq<G> seq = Seq.of_iterator<G>(iter, __length, true);
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.limit(limit).count().value;
		int64 validation = limit > __length ? __length : limit;
		assert(result == validation);
	}

	private void test_limit_short_circuiting (bool parallel) {
		Seq<G> seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.limit(__limit).count().value;
		assert(result == __limit);
	}

	private void test_chop (bool parallel, int64 skip, int64 limit) {
		Iterator<G> iter = create_rand_iter(__length);
		Seq<G> seq = Seq.of_iterator<G>(iter, __length, true);
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.chop(skip, limit).count().value;
		int64 s = skip > __length ? __length : skip;
		int64 validation = limit < 0 ? __length - s : int64.min(limit, __length - s);
		assert(result == validation);
	}

	private void test_chop_short_circuiting (bool parallel) {
		Seq<G> seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.chop(__skip, __limit).count().value;
		assert(result == __limit);
	}

	private void test_skip_ordered (bool parallel, int64 skip) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		Iterator<G> result = seq.skip_ordered(skip).iterator();
		int64 s = skip > __length ? __length : skip;
		if (s == __length) {
			assert( !result.valid && !result.has_next() );
			return;
		}
		for (int64 i = 0; i < s+1; i++) { iters[1].next(); }
		assert_iter_equals(iters[1], result, equal);
	}

	private void test_limit_ordered (bool parallel, int64 limit) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		Iterator<G> result = seq.limit_ordered(limit).iterator();
		Iterator<G> validation = new LimitedIterator<G>(iters[1], limit);
		assert_iter_equals(validation, result, equal);
	}

	private void test_limit_ordered_short_circuiting (bool parallel) {
		Seq<G> seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.limit_ordered(__limit).count().value;
		assert(result == __limit);
	}

	private void test_chop_ordered (bool parallel, int64 skip, int64 limit) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		Iterator<G> result = seq.chop_ordered(skip, limit).iterator();
		int64 s = skip > __length ? __length : skip;
		if (s == __length) {
			assert( !result.valid && !result.has_next() );
			return;
		}
		for (int64 i = 0; i < s+1; i++) { iters[1].next(); }
		Iterator<G> validation = new LimitedIterator<G>(iters[1], limit);
		assert_iter_equals<G>(validation, result, equal);
	}

	private void test_chop_ordered_short_circuiting (bool parallel) {
		Seq<G> seq = create_rand_seq();
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.chop_ordered(__skip, __limit).count().value;
		assert(result == __limit);
	}

	private void test_filter () {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Iterator<G> result = Seq.of_iterator<G>(iters[0], __length, true)
				.filter((g) => filter(g))
				.iterator();

		while (iters[1].next()) {
			if ( filter(iters[1].get()) ) {
				assert( result.next() );
				assert( equal(iters[1].get(), result.get()) );
			}
		}
		assert( !iters[1].has_next() );
		assert( !result.has_next() );
	}

	private void test_fold (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		G result = seq.fold<G>(
				(a, b) => { return combine(a, b); },
				(a, b) => { return combine(a, b); },
				identity() ).value;

		G validation = identity();
		while (iters[1].next()) {
			validation = combine(iters[1].get(), validation);
		}
		assert( equal(result, validation) );
	}

	private void test_reduce (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		G result = seq.reduce((a, b) => { return combine(a, b); }).value.value;

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				validation = combine(iters[1].get(), validation);
			}
		}
		assert(found);
		assert( equal(result, validation) );
	}

	private void test_map () {
		Iterator<G>[] iters = create_rand_iter(__length).tee(4);
		Iterator<string>[] validations = new MappedIterator<string,G>(iters[0], map_to_str).tee(3);

		Iterator<string> result = Seq.of_iterator<G>(iters[1], __length, true)
				.map<string>((g) => map_to_str(g))
				.iterator();
		assert_iter_equals<string>(validations[0], result, (a, b) => str_equal(a, b));

		try {
			Iterator<string> v = validations[1];
			Seq.of_iterator<G>(iters[2], __length, true)
					.map<string>((g) => map_to_str(g))
					.spliterator()
					.each(g => {
						assert( v.next() );
						assert( str_equal(v.get(), g) );
					});
			assert( !v.has_next() );

			v = validations[2];
			Seq.of_iterator<G>(iters[3], __length, true)
					.map<string>((g) => map_to_str(g))
					.spliterator()
					.each_chunk(chunk => {
						for (int i = 0; i < chunk.length; i++) {
							assert( v.next() );
							assert( str_equal(v.get(), chunk[i]) );
						}
						return true;
					});
			assert( !v.has_next() );
		} catch (Error err) {
			error("%s", err.message);
		}
	}

	private void test_flat_map () {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(4);
		GenericArray<G> validation = new GenericArray<G>(len);
		while (iters[0].next()) {
			Iterator<G> els = flat_map( iters[0].get() );
			els.foreach(g => {
				validation.add(g);
				return true;
			});
		}

		Iterator<G> result = Seq.of_iterator<G>(iters[1], len, true)
				.flat_map<G>((g) => flat_map(g))
				.iterator();
		GenericArray<G> result_array = iter_to_generic_array<G>(result);
		assert_array_equals<G>(validation.data, result_array.data, equal);

		try {
			result_array = new GenericArray<G>(len);
			Seq.of_iterator<G>(iters[2], len, true)
					.flat_map<G>((g) => flat_map(g))
					.spliterator()
					.each(g => result_array.add(g));
			assert_array_equals<G>(validation.data, result_array.data, equal);

			result_array = new GenericArray<G>(len);
			Seq.of_iterator<G>(iters[3], len, true)
					.flat_map<G>((g) => flat_map(g))
					.spliterator()
					.each_chunk(chunk => {
						for (int i = 0; i < chunk.length; i++) {
							result_array.add(chunk[i]);
						}
						return true;
					});
			assert_array_equals<G>(validation.data, result_array.data, equal);
		} catch (Error err) {
			error("%s", err.message);
		}
	}

	private void test_max (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		Optional<G> result = seq.max((a, b) => compare(a, b)).value;

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				if ( compare(iters[1].get(), validation) >= 0 ) {
					validation = iters[1].get();
				}
			}
		}
		assert(found);
		assert( equal(result.value, validation) );
	}

	private void test_min (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		Optional<G> result = seq.min((a, b) => compare(a, b)).value;

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				if ( compare(iters[1].get(), validation) <= 0 ) {
					validation = iters[1].get();
				}
			}
		}
		assert(found);
		assert( equal(result.value, validation) );
	}

	private void test_order_by (bool parallel) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		GenericArray<G> array = iter_to_generic_array<G>(create_rand_iter(len), len);
		Seq<G> seq = Seq.of_generic_array<G>(array);
		if (parallel) seq = seq.parallel();
		GenericArray<G> result = iter_to_generic_array<G>(
			seq.order_by((a, b) => compare(a, b)).iterator(), len);

		assert_sorted<G>(result.data, compare);
		array.sort_with_data(compare);
		assert_array_equals<G>(array.data, result.data, equal);
	}

	private void test_stable_order_by (bool parallel) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		var array = new GenericArray<Wrapper<G>>(len);
		for (int i = 0; i < len; i++) {
			array.add( new Wrapper<G>(random()) );
		}

		var seq = Seq.of_generic_array<Wrapper<G>>(array);
		if (parallel) seq = seq.parallel();
		var result_iter = seq.order_by((a, b) => compare(a.value, b.value)).iterator();
		var result = iter_to_generic_array<Wrapper<G>>(result_iter, len);

		// g_ptr_array_sort_with_data is guaranteed to be a stable sort since glib 2.32
		array.sort_with_data((a, b) => compare(a.value, b.value));
		assert_array_equals<Wrapper<G>>(array.data, result.data, (a, b) => a == b);
	}

	private void test_foreach (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		int result = 0;
		seq.foreach( g => wrap_atomic_int_add(ref result, map_to_int(g)) ).value;

		int validation = 0;
		while (iters[1].next()) {
			validation = wrap_int_add(validation, map_to_int(iters[1].get()));
		}
		assert(result == validation);
	}

	private void test_collect (bool parallel) {
		test_collector_to_generic_array(parallel);
	}

	private void test_collect_ordered (bool parallel) {
		test_collector_to_generic_array(parallel, true);
	}

	private void test_complex_fold (bool parallel) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		GenericArray<G> array = iter_to_generic_array<G>(create_rand_iter(len), len);
		Seq<G> seq = Seq.of_generic_array<G>(array);
		if (parallel) seq = seq.parallel();
		int result = seq
			.filter((g) => filter(g))
			.distinct(hash, equal)
			.order_by((a, b) => compare(a, b))
			.chop_ordered(__skip, __limit)
			.map<int>((g) => map_to_int(g))
			.fold<int>((g, a) => wrap_int_add(g, a), (a, b) => wrap_int_add(a, b), 0).value;
		int validation = get_complex_fold_validation(array);
		assert(result == validation);
	}

	private int get_complex_fold_validation (GenericArray<G> array) {
		GenericArray<G> filtered = new GenericArray<G>();
		for (int i = 0; i < array.length; i++) {
			if ( filter(array[i]) ) filtered.add(array[i]);
		}

		GenericArray<G> distinct = new GenericArray<G>();
		Set<G> seen = new HashSet<G>(hash, equal);
		for (int i = 0; i < filtered.length; i++) {
			if (!seen.contains(filtered[i])) {
				seen.add(filtered[i]);
				distinct.add(filtered[i]);
			}
		}
		distinct.sort_with_data(compare);

		int sum = 0;
		int skip = __skip <= int.MAX ? (int)__skip : int.MAX;
		if (skip < distinct.length) {
			int limit = (__skip + __limit) <= distinct.length ? (int)(__skip + __limit) : distinct.length;
			for (int i = skip; i < limit; i++) {
				sum = wrap_int_add(sum, map_to_int(distinct[i]));
			}
		}
		return sum;
	}

	private void test_collector_to_generic_array (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		GenericArray<G> array = iter_to_generic_array<G>(create_rand_iter(len), len);
		Seq<G> seq = Seq.of_generic_array<G>(array);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_generic_array<G>();
		GenericArray<G> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}
		assert_array_equals<G>(array.data, result.data, equal);
	}

	private void test_collector_to_collection (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_collection<G>(
				Supplier.from_func<Gee.List<G>>(() => new ArrayList<G>()) );
		Gee.List<G> list;
		if (ordered) {
			list = (Gee.List<G>) seq.collect_ordered(collector).value;
		} else {
			list = (Gee.List<G>) seq.collect(collector).value;
		}
		assert_iter_equals<G>(iters[1], list.iterator(), equal);
	}

	private void test_collector_to_list (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_list<G>();
		Gee.List<G> list;
		if (ordered) {
			list = seq.collect_ordered(collector).value;
		} else {
			list = seq.collect(collector).value;
		}
		assert_iter_equals<G>(iters[1], list.iterator(), equal);
	}

	/*
	private void test_collector_to_concurrent_list (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		// Don't use Traversable.tee here!
		uint32 seed = Random.next_int();
		Iterator<G>[] iters = {
			create_rand_iter(len, seed),
			create_rand_iter(len, seed)
		};
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_concurrent_list<G>();
		Gee.List<G> list;
		if (ordered) {
			list = seq.collect_ordered(collector).value;
		} else {
			list = seq.collect(collector).value;
		}

		if (!parallel || ordered) {
			assert_iter_equals<G>(iters[1], list.iterator(), equal);
		} else {
			GenericArray<G> validation = iter_to_generic_array<G>(iters[1], len);
			GenericArray<G> result = list_to_generic_array<G>(list);
			// g_ptr_array_sort_with_data is guaranteed to be a stable sort since glib 2.32
			validation.sort_with_data(compare);
			result.sort_with_data(compare);
			assert_array_equals<G>(validation.data, result.data, equal);
		}
	}
	*/
	
	private void test_collector_to_set (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_set<G>(hash, equal);
		Set<G> s;
		if (ordered) {
			s = seq.collect_ordered(collector).value;
		} else {
			s = seq.collect(collector).value;
		}

		while (iters[1].next()) {
			assert( s.contains(iters[1].get()) );
		}
	}

	private void test_collector_to_map (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;

		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.to_map<uint,G,G>(
				g => hash(g), g => { return g; }, (a, b) => { return a; },
				null, null, equal);
		Map<uint,G> map;
		if (ordered) {
			map = seq.collect_ordered(collector).value;
		} else {
			map = seq.collect(collector).value;
		}

		var validation = new HashMap<uint,G>();
		while (iters[1].next()) {
			G val = iters[1].get();
			uint key = hash(val);
			if ( !validation.has_key(key) ) {
				validation[key] = val;
			}
		}
		assert_map_equals<uint,G>(validation, map, equal);
	}

	private void test_collector_sum_int (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		int result = seq.collect( Collectors.sum_int<G>((g) => map_to_int(g)) ).value;
		int validation = 0;
		while (iters[1].next()) {
			validation = wrap_int_add( validation, map_to_int(iters[1].get()) );
		}
		assert(result == validation);
	}

	private void test_collector_sum_uint (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		uint result = seq.collect( Collectors.sum_uint<G>(g => (uint)map_to_int(g)) ).value;
		uint validation = 0;
		while (iters[1].next()) {
			validation += (uint) map_to_int(iters[1].get());
		}
		assert(result == validation);
	}

	private void test_collector_sum_long (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		long result = seq.collect( Collectors.sum_long<G>(g => (long)map_to_int(g)) ).value;
		long validation = 0;
		while (iters[1].next()) {
			validation = wrap_long_add( validation, (long) map_to_int(iters[1].get()) );
		}
		assert(result == validation);
	}

	private void test_collector_sum_ulong (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		ulong result = seq.collect( Collectors.sum_ulong<G>(g => (ulong)map_to_int(g)) ).value;
		ulong validation = 0;
		while (iters[1].next()) {
			validation += (ulong) map_to_int(iters[1].get());
		}
		assert(result == validation);
	}

	private void test_collector_sum_int32 (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		int32 result = seq.collect( Collectors.sum_int32<G>(g => (int32)map_to_int(g)) ).value;
		int32 validation = 0;
		while (iters[1].next()) {
			validation = wrap_int32_add( validation, (int32) map_to_int(iters[1].get()) );
		}
		assert(result == validation);
	}

	private void test_collector_sum_uint32 (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		uint32 result = seq.collect( Collectors.sum_uint32<G>(g => (uint32)map_to_int(g)) ).value;
		uint32 validation = 0;
		while (iters[1].next()) {
			validation += (uint32) map_to_int(iters[1].get());
		}
		assert(result == validation);
	}

	private void test_collector_sum_int64 (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		int64 result = (!) seq.collect( Collectors.sum_int64<G>(g => (int64)map_to_int(g)) ).value;
		int64 validation = 0;
		while (iters[1].next()) {
			validation = wrap_int64_add( validation, (int64) map_to_int(iters[1].get()) );
		}
		assert(result == validation);
	}

	private void test_collector_sum_uint64 (bool parallel) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();
		uint64 result = (!) seq.collect( Collectors.sum_uint64<G>(g => (uint64)map_to_int(g)) ).value;
		uint64 validation = 0;
		while (iters[1].next()) {
			validation += (uint64) map_to_int(iters[1].get());
		}
		assert(result == validation);
	}

	private void test_collector_group_by (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;
		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.group_by<bool,G>(g => filter(g));
		Map<bool,Gee.List<G>> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		var validation = new HashMap<bool,Gee.List<G>>();
		while (iters[1].next()) {
			G val = iters[1].get();
			bool key = filter(val);
			if ( !validation.has_key(key) ) {
				validation[key] = new ArrayList<G>();
			}
			validation[key].add(val);
		}
		assert_map_equals<bool,Gee.List<G>>(validation, result, (a, b) => {
			assert_iter_equals<G>( ((Iterable<G>)a).iterator(), ((Iterable<G>)b).iterator(), equal );
			return true;
		});
	}

	private void test_collector_partition (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;
		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.partition<G>(g => filter(g));
		Map<bool,Gee.List<G>> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		var validation = new HashMap<bool,Gee.List<G>>();
		while (iters[1].next()) {
			G val = iters[1].get();
			bool key = filter(val);
			if ( !validation.has_key(key) ) {
				validation[key] = new ArrayList<G>();
			}
			validation[key].add(val);
		}
		assert_map_equals<bool,Gee.List<G>>(validation, result, (a, b) => {
			assert_iter_equals<G>( ((Iterable<G>)a).iterator(), ((Iterable<G>)b).iterator(), equal );
			return true;
		});
	}

	private void test_collector_max (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.max<G>((a, b) => compare(a, b));
		Optional<G> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				if ( compare(iters[1].get(), validation) >= 0 ) {
					validation = iters[1].get();
				}
			}
		}
		assert(found);
		assert( equal(result.value, validation) );
	}

	private void test_collector_min (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.min<G>((a, b) => compare(a, b));
		Optional<G> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				if ( compare(iters[1].get(), validation) <= 0 ) {
					validation = iters[1].get();
				}
			}
		}
		assert(found);
		assert( equal(result.value, validation) );
	}

	private void test_collector_count (bool parallel, bool ordered = false) {
		Seq<G> seq = Seq.of_iterator<G>(create_rand_iter(__length), __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.count<G>();
		int64 result;
		if (ordered) {
			result = (!) seq.collect_ordered(collector).value;
		} else {
			result = (!) seq.collect(collector).value;
		}
		assert(result == __length);
	}

	private void test_collector_fold (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.fold<G,G>(
				(a, b) => { return combine(a, b); },
				(a, b) => { return combine(a, b); },
				identity() );
		G result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		G validation = identity();
		while (iters[1].next()) {
			validation = combine(iters[1].get(), validation);
		}
		assert( equal(result, validation) );
	}

	private void test_collector_reduce (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.reduce<G>((a, b) => { return combine(a, b); });
		G result;
		if (ordered) {
			result = seq.collect_ordered(collector).value.value;
		} else {
			result = seq.collect(collector).value.value;
		}

		G? validation = null;
		bool found = false;
		while (iters[1].next()) {
			if (!found) {
				validation = iters[1].get();
				found = true;
			} else {
				validation = combine(iters[1].get(), validation);
			}
		}
		assert(found);
		assert( equal(result, validation) );
	}

	private void test_collector_filter (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;
		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.filter<Gee.List<G>,G>(
				(g) => filter(g), Collectors.to_list<G>() );
		Iterator<G> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value.iterator();
		} else {
			result = seq.collect(collector).value.iterator();
		}

		while (iters[1].next()) {
			if ( filter(iters[1].get()) ) {
				assert( result.next() );
				assert( equal(iters[1].get(), result.get()) );
			}
		}
		assert( !iters[1].has_next() );
		assert( !result.has_next() );
	}

	private void test_collector_tee (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.tee<Gee.List<int64?>,G>(
			{
				Collectors.wrap<int64?,G>( Collectors.sum_int64<G>(g => map_to_int(g)) ),
				Collectors.wrap<int64?,G>( Collectors.count<G>() )
			},
			results => {
				var list = new ArrayList<int64?>();
				list.add( ((Wrapper<int64?>)results[0]).value );
				list.add( ((Wrapper<int64?>)results[1]).value );
				return list;
			});
		Gee.List<int64?> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		int64 sum = 0;
		while ( iters[1].next() ) {
			sum = wrap_int64_add(sum, map_to_int(iters[1].get()));
		}
		assert(result[0] == sum);
		assert(result[1] == __length);
	}

	private void test_collector_map (bool parallel, bool ordered = false) {
		int len = __length <= int.MAX ? (int)__length : int.MAX;
		Iterator<G>[] iters = create_rand_iter(len).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], len, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.map<Gee.List<string>,string,G>(
				(g) => map_to_str(g), Collectors.to_list<string>() );
		Gee.List<string> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		Gee.List<string> validation = new ArrayList<string>();
		while (iters[1].next()) {
			validation.add( map_to_str(iters[1].get()) );
		}
		assert_iter_equals<string>(
				validation.iterator(), result.iterator(),
				(a, b) => str_equal(a, b) );
	}

	private void test_collector_wrap (bool parallel, bool ordered = false) {
		Iterator<G>[] iters = create_rand_iter(__length).tee(2);
		Seq<G> seq = Seq.of_iterator<G>(iters[0], __length, true);
		if (parallel) seq = seq.parallel();

		var collector = Collectors.wrap<int64?,G>(
				Collectors.sum_int64<G>(g => map_to_int(g)) );
		Wrapper<int64?> result;
		if (ordered) {
			result = seq.collect_ordered(collector).value;
		} else {
			result = seq.collect(collector).value;
		}

		int64 sum = 0;
		while ( iters[1].next() ) {
			sum = wrap_int64_add(sum, map_to_int(iters[1].get()));
		}
		assert(result.value == sum);
	}
}
