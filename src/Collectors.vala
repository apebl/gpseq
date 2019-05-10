/* Collectors.vala
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
	 * Various collector implementations.
	 */
	namespace Collectors {
		/**
		 * Returns a collector that accumulates the elements into a new generic
		 * array, in encounter order.
		 *
		 * @return the collector implementation
		 */
		public Collector<GenericArray<G>,Object,G> to_generic_array<G> () {
			return new GenericArrayCollector<G>();
		}

		/**
		 * Returns a collector that accumulates the elements into a new
		 * collection, in encounter order.
		 *
		 * @param factory a supplier which supplies a new empty collection
		 * @return the collector implementation
		 */
		public Collector<Collection<G>,Object,G> to_collection<G> (Supplier<Collection<G>> factory) {
			return new CollectionCollector<G>(factory, 0);
		}

		/**
		 * Returns a collector that accumulates the elements into a new list,
		 * in encounter order.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the list.
		 *
		 * @return the collector implementation
		 */
		public Collector<Gee.List<G>,Object,G> to_list<G> () {
			return (Collector<Gee.List<G>,Object,G>) to_collection<G>(
				Supplier.from_func<Gee.List<G>>(() => new ArrayList<G>()) );
		}

		/**
		 * Returns a collector that accumulates the elements into a new
		 * concurrent list. The list is thread-safe.
		 *
		 * There are no guarantees on the type or mutability of the list.
		 *
		 * @return the collector implementation
		 */
		/* XXX Gee.ConcurrentList doesn't unref its elements (a bug?)
		public Collector<Gee.List<G>,Object,G> to_concurrent_list<G> () {
			return (Collector<Gee.List<G>,Object,G>) new CollectionCollector<G>(
				Supplier.from_func<Gee.List<G>>(() => new ConcurrentList<G>()),
				CollectorFeatures.CONCURRENT
			);
		}
		*/

		/**
		 * Returns a collector that accumulates the elements into a new set.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the set.
		 *
		 * @param hash a hash function. if not specified,
		 * {@link Gee.Functions.get_hash_func_for} is used to get a proper
		 * function
		 * @param equal an equal function. if not specified,
		 * {@link Gee.Functions.get_equal_func_for} is used to get a proper
		 * function
		 * @return the collector implementation
		 */
		public Collector<Set<G>,Object,G> to_set<G> (
				owned HashDataFunc<G>? hash = null,
				owned EqualDataFunc<G>? equal = null) {
			if (hash == null) hash = Functions.get_hash_func_for(typeof(G));
			if (equal == null) equal = Functions.get_equal_func_for(typeof(G));
			return (Collector<Set<G>,Object,G>) new CollectionCollector<G>(
				Supplier.from_func<Set<G>>( () => new HashSet<G>(v => hash(v), (a, b) => equal(a,b)) ),
				CollectorFeatures.UNORDERED
			);
		}

		/**
		 * Returns a collector that accumulates the elements into a new map.
		 *
		 * If there are key duplications, the values are merged using the //merger// function.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the map.
		 *
		 * @param key_mapper a mapping function for keys
		 * @param val_mapper a mapping function for values
		 * @param merger a function used to resolve key collisions
		 * @param key_hash a hash function for keys. if not specified,
		 * {@link Gee.Functions.get_hash_func_for} is used to get a proper
		 * function
		 * @param key_equal an equal function for keys. if not specified,
		 * {@link Gee.Functions.get_equal_func_for} is used to get a proper
		 * function
		 * @param value_equal an equal function for values. if not specified,
		 * {@link Gee.Functions.get_equal_func_for} is used to get a proper
		 * function
		 * @return the collector implementation
		 */
		public Collector<Map<K,V>,Object,G> to_map<K,V,G> (
				owned MapFunc<K,G> key_mapper, owned MapFunc<V,G> val_mapper,
				owned CombineFunc<V> merger,
				owned HashDataFunc<K>? key_hash = null,
				owned EqualDataFunc<K>? key_equal = null,
				owned EqualDataFunc<V>? value_equal = null) {
			return new MapCollector<K,V,G>(
					(owned)key_mapper, (owned)val_mapper, (owned)merger,
					(owned)key_hash, (owned)key_equal, (owned)value_equal );
		}

		/* TODO
		public Collector<Map<K,V>,Object,G> to_concurrent_map<K,V,G> (
				owned MapFunc<K,G> key_mapper, owned MapFunc<V,G> val_mapper,
				owned CombineFunc<V> merger,
				owned HashDataFunc<K>? key_hash = null,
				owned EqualDataFunc<K>? key_equal = null,
				owned EqualDataFunc<V>? value_equal = null)
		*/

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<int,Object,G> sum_int<G> (owned MapFunc<int,G> mapper) {
			return new SumIntCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<uint,Object,G> sum_uint<G> (owned MapFunc<uint,G> mapper) {
			return new SumUintCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<long,Object,G> sum_long<G> (owned MapFunc<long,G> mapper) {
			return new SumLongCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<ulong,Object,G> sum_ulong<G> (owned MapFunc<ulong,G> mapper) {
			return new SumUlongCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The result can vary because of accumulated rounding error.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<float?,Object,G> sum_float<G> (owned MapFunc<float?,G> mapper) {
			return new SumFloatCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The result can vary because of accumulated rounding error.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<double?,Object,G> sum_double<G> (owned MapFunc<double?,G> mapper) {
			return new SumDoubleCollector<G>((owned) mapper);

		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<int32,Object,G> sum_int32<G> (owned MapFunc<int32,G> mapper) {
			return new SumInt32Collector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<uint32,Object,G> sum_uint32<G> (owned MapFunc<uint32,G> mapper) {
			return new SumUint32Collector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<int64?,Object,G> sum_int64<G> (owned MapFunc<int64?,G> mapper) {
			return new SumInt64Collector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the sum of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<uint64?,Object,G> sum_uint64<G> (owned MapFunc<uint64?,G> mapper) {
			return new SumUint64Collector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the arithmetic mean of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<float?,Object,G> average_float<G> (owned MapFunc<float?,G> mapper) {
			return new AverageFloatCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that produces the arithmetic mean of the given function
		 * applied to the elements. If there are no elements, the result is 0.
		 *
		 * The //mapper// function must not return null.
		 *
		 * @param mapper a mapping function
		 * @return the collector implementation
		 */
		public Collector<double?,Object,G> average_double<G> (owned MapFunc<double?,G> mapper) {
			return new AverageDoubleCollector<G>((owned) mapper);
		}

		/**
		 * Returns a collector that groups the elements based on the
		 * //classifier// function.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map and list.
		 *
		 * @param classifier a classifier function mapping elements to keys
		 * @return the collector implementation
		 */
		public Collector<Map<K,Gee.List<G>>,Object,G> group_by<K,G> (owned MapFunc<K,G> classifier) {
			return group_by_with<K,Gee.List<G>,G>((owned) classifier, to_list<G>());
		}

		/**
		 * Returns a collector that groups the elements based on the
		 * //classifier// function, and performs a reduction operation on the
		 * values of each key using the //downstream// collector.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map.
		 *
		 * @param classifier a classifier function mapping elements to keys
		 * @param downstream a downstream collector
		 * @return the collector implementation
		 */
		public Collector<Map<K,V>,Object,G> group_by_with<K,V,G> (
				owned MapFunc<K,G> classifier, Collector<V,Object,G> downstream) {
			return new GroupByCollector<K,V,G>((owned) classifier, downstream);
		}

		/* TODO
		public Collector<Map<K,Gee.List<G>>,Object,G> concurrent_group_by<K,G> (
				owned MapFunc<K,G> classifier)
		*/

		/* TODO
		public Collector<Map<K,V>,Object,G> concurrent_group_by_with<K,V,G> (
				owned MapFunc<K,G> classifier, Collector<V,Object,G> downstream)
		*/

		/**
		 * Returns a collector that partitions the elements based on the
		 * //pred// function.
		 *
		 * The result map always contains lists for both true and false keys.
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map and list.
		 *
		 * @param pred a predicate function
		 * @return the collector implementation
		 */
		public Collector<Map<bool,Gee.List<G>>,Object,G> partition<G> (owned Predicate<G> pred) {
			return partition_with<Gee.List<G>,G>((owned) pred, to_list<G>());
		}

		/**
		 * Returns a collector that partitions the elements based on the
		 * //pred// function, and performs a reduction operation on the
		 * values of each partition using the //downstream// collector.
		 *
		 * The result map always contains mappings for both true and false keys.
		 * If a partition has no elements, its value will be obtained from the
		 * //downstream.create_accumulator// and the //downstream.finish//
		 * function applied.
		 *
		 * There are no guarantees on the type, mutability, or thread-safety of
		 * the returned map.
		 *
		 * @param pred a predicate function
		 * @param downstream a downstream collector
		 * @return the collector implementation
		 */
		public Collector<Map<bool,V>,Object,G> partition_with<V,G> (
				owned Predicate<G> pred, Collector<V,Object,G> downstream) {
			return new PartitionCollector<G,V>((owned) pred, downstream);
		}

		/**
		 * Returns a collector that produces the maximum element based on the
		 * given compare function.
		 *
		 * @param compare a compare function. if not specified,
		 * {@link Gee.Functions.get_compare_func_for} is used to get a proper
		 * function.
		 * @return the collector implementation
		 */
		public Collector<Optional<G>,Object,G> max<G> (owned CompareDataFunc<G>? compare = null) {
			if (compare == null) compare = Functions.get_compare_func_for(typeof(G));
			return reduce((a, b) => { return compare(a, b) >= 0 ? a : b; });
		}

		/**
		 * Returns a collector that produces the minimum element based on the
		 * given compare function.
		 *
		 * @param compare a compare function. if not specified,
		 * {@link Gee.Functions.get_compare_func_for} is used to get a proper
		 * function.
		 * @return the collector implementation
		 */
		public Collector<Optional<G>,Object,G> min<G> (owned CompareDataFunc<G>? compare = null) {
			if (compare == null) compare = Functions.get_compare_func_for(typeof(G));
			return reduce((a, b) => { return compare(a, b) <= 0 ? a : b; });
		}

		/**
		 * Returns a collector that counts the number of elements.
		 *
		 * @return the collector implementation
		 */
		public Collector<int64?,Object,G> count<G> () {
			return fold<int64?,G>((g, a) => a + 1, (a, b) => a + b, 0);
		}

		/**
		 * Returns a collector that performs a reduction operation on the
		 * elements.
		 *
		 * @param accumulator an accumulate function
		 * @param combiner a combine function
		 * @param identity an identity value
		 * @return the collector implementation
		 * @see Seq.fold
		 */
		public Collector<A,Object,G> fold<A,G> (
				owned FoldFunc<A,G> accumulator, owned CombineFunc<A> combiner, A identity) {
			return new FoldCollector<A,G>((owned) accumulator, (owned) combiner, identity);
		}

		/**
		 * Returns a collector that performs a reduction operation on the
		 * elements.
		 *
		 * @param accumulator an accumulate function
		 * @return the collector implementation
		 * @see Seq.reduce
		 */
		public Collector<Optional<G>,Object,G> reduce<G> (owned CombineFunc<G> accumulator) {
			return new ReduceCollector<G>((owned) accumulator);
		}

		/**
		 * Returns a collector that concatenates the elements into a string, in
		 * encounter order.
		 *
		 * @param delimiter a delimiter
		 * @return the collector implementation
		 */
		public Collector<string,Object,string> join (owned string delimiter = "") {
			return new JoinCollector((owned) delimiter);
		}

		/**
		 * Returns a collector that only accumulates the elements matching the
		 * given predicate.
		 *
		 * @param pred a predicate function
		 * @param downstream a downstream collector
		 * @return the collector implementation
		 */
		public Collector<A,Object,G> filter<A,G> (owned Predicate<G> pred,
				Collector<A,Object,G> downstream) {
			return new FilterCollector<A,G>((owned) pred, downstream);
		}

		/**
		 * Returns a collector that consists of multiple downstream collectors.
		 * The elements are processed by all the downstream collectors, and
		 * then their results are merged using the //merger// function into the
		 * final result.
		 *
		 * The {@link Collector.features} of the returned collector is
		 * intersection of the downstream collectors' features.
		 *
		 * @param downstreams an array of the downstream collectors -- must
		 * have at least one collector
		 * @param merger the merge function
		 * @return the collector implementation
		 */
		public Collector<A,Object,G> tee<A,G> (
				owned Collector<Object,Object,G>[] downstreams,
				owned TeeMergeFunc<A> merger) {
			return new TeeCollector<A,G>((owned) downstreams, (owned) merger);
		}

		/**
		 * Returns a collector that applies the given mapper function to the
		 * elements, and performs a reduction operation on the results using
		 * the //downstream// collector.
		 *
		 * @param mapper a mapper function
		 * @param downstream a downstream collector
		 * @return the collector implementation
		 */
		public Collector<R,Object,G> map<R,A,G> (
				owned MapFunc<A,G> mapper, Collector<R,Object,A> downstream) {
			return new MappingCollector<R,A,G>((owned) mapper, downstream);
		}

		/**
		 * Returns a collector wrapping the given collector. The returned
		 * collector will produce a wrapper object containing the result of the
		 * given collector.
		 *
		 * @param collector a collector
		 * @return the collector implementation
		 */
		public Collector<Wrapper<A>,Object,G> wrap<A,G> (Collector<A,Object,G> collector) {
			return new WrapCollector<A,G>(collector);
		}
	}
}
