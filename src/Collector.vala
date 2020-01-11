/* Collector.vala
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

namespace Gpseq {
	/**
	 * An object for mutable reduction operation that accumulates input
	 * elements into a mutable accumulator, and transforms it into a final
	 * result.
	 *
	 * A collector implements four methods: {@link create_accumulator},
	 * {@link accumulate}, {@link combine}, and {@link finish}.
	 *
	 *  i. create_accumulator() - creates a new accumulator, such as {@link Gee.Collection}.
	 *  i. accumulate() - incorporates a new element into a accumulator.
	 *  i. combine() - combines two accumulators into one.
	 *  i. finish() - transforms the accumulator into a final result.
	 *
	 * The methods must satisfy an //identity// and an //associativity//
	 * constraints. The identity constraint means that combining any accumulator
	 * with an empty accumulator must produce an equivalent result. i.e. an
	 * accumulator //a// must be equivalent to
	 * //collector.accumulate(a, collector.create_accumulator())//
	 *
	 * The associativity constraint means that splitting the computation must
	 * produce an equivalent result. i.e.:
	 *
	 * {{{
	 * // the two computations below must be equivalent.
	 * // collector: a collector
	 * // g0, g1: elements
	 *
	 * A a0 = collector.create_accumulator();
	 * collector.accumulate(g0, a0);
	 * collector.accumulate(g1, a0);
	 * A r0 = collector.finish(a0);
	 *
	 * A a1 = collector.create_accumulator();
	 * collector.accumulate(g0, a1);
	 * A a2 = collector.create_accumulator();
	 * collector.accumulate(g1, a2);
	 * A r1 = collector.finish( collector.combine(a1, a2) );
	 * }}}
	 *
	 * Collectors also have a property, {@link features}. it provides hints
	 * that can be used to optimize the operation.
	 *
	 * @see Seq.collect
	 * @see Seq.collect_ordered
	 * @see Collectors
	 * @see CollectorFeatures
	 */
	public interface Collector<R,A,G> : Object {
		/**
		 * Hints that can be used to optimize collect operations.
		 */
		public abstract CollectorFeatures features { get; }
		/**
		 * Creates a new accumulator.
		 */
		public abstract A create_accumulator () throws Error;
		/**
		 * Accumulates a element into a accumulator.
		 *
		 * This method must be //associative//, //non-interfering//, and
		 * //stateless//.
		 *
		 * @param g element
		 * @param a accumulator
		 */
		public abstract void accumulate (G g, A a) throws Error;
		/**
		 * Combines two accumulators into one.
		 *
		 * This method must be //associative//, //non-interfering//, and
		 * //stateless//.
		 *
		 * @return combined accumulator.
		 */
		public abstract A combine (A a, A b) throws Error;
		/**
		 * Transforms an accumulator into a final result.
		 * @return the final result
		 */
		public abstract R finish (A a) throws Error;
	}
}
