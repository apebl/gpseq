/* TeeCollector.vala
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

private class Gpseq.Collectors.TeeCollector<A,G> : Object, Collector<A,Accumulator<G>,G> {
	private Collector<Object,Object,G>[] _downstreams;
	private TeeMergeFunc<A> _merger;

	public TeeCollector (
			owned Collector<Object,Object,G>[] downstreams,
			owned TeeMergeFunc<A> merger) {
		assert(downstreams.length > 0);
		_downstreams = (owned) downstreams;
		_merger = (owned) merger;
	}

	public CollectorFeatures features {
		get {
			CollectorFeatures result = _downstreams[0].features;
			for (int i = 1; i < _downstreams.length; i++) {
				result &= _downstreams[i].features;
			}
			return result;
		}
	}

	public Accumulator<G> create_accumulator () {
		return new Accumulator<G>(_downstreams);
	}

	public void accumulate (G g, Accumulator<G> a) {
		for (int i = 0; i < _downstreams.length; i++) {
			_downstreams[i].accumulate(g, a.list[i]);
		}
	}

	public Accumulator<G> combine (Accumulator<G> a, Accumulator<G> b) {
		for (int i = 0; i < _downstreams.length; i++) {
			a.list[i] = _downstreams[i].combine(a.list[i], b.list[i]);
		}
		return a;
	}

	public A finish (Accumulator<G> a) {
		for (int i = 0; i < _downstreams.length; i++) {
			a.list[i] = _downstreams[i].finish(a.list[i]);
		}
		return _merger(a.list);
	}

	public class Accumulator<G> : Object {
		public Object[] list;

		public Accumulator (Collector<Object,Object,G>[] downstreams) {
			list = new Object[downstreams.length];
			for (int i = 0; i < list.length; i++) {
				list[i] = downstreams[i].create_accumulator();
			}
		}
	}
}
