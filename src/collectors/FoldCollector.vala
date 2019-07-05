/* FoldCollector.vala
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

private class Gpseq.Collectors.FoldCollector<A,G> : Object, Collector<A,Accumulator<A>,G> {
	private FoldFunc<A,G> _accumulator;
	private CombineFunc<A> _combiner;
	private A _identity;

	public FoldCollector (
			owned FoldFunc<A,G> accumulator, owned CombineFunc<A> combiner, A identity) {
		_accumulator = (owned) accumulator;
		_combiner = (owned) combiner;
		_identity = identity;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator<A> create_accumulator () throws Error {
		return new Accumulator<A>(_identity);
	}

	public void accumulate (G g, Accumulator<A> a) throws Error {
		a.val = _accumulator(g, a.val);
	}

	public Accumulator<A> combine (Accumulator<A> a, Accumulator<A> b) throws Error {
		a.val = _combiner(a.val, b.val);
		return a;
	}

	public A finish (Accumulator<A> a) throws Error {
		return a.val;
	}

	public class Accumulator<A> : Object {
		public A val;

		public Accumulator (A val) {
			this.val = val;
		}
	}
}
