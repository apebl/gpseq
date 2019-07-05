/* PartitionCollector.vala
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

private class Gpseq.Collectors.PartitionCollector<V,G> : Object, Collector<Map<bool,V>,Map<bool,Object>,G> {
	private Predicate<G> _pred;
	private Collector<V,Object,G> _downstream;

	public PartitionCollector (owned Predicate<G> pred, Collector<V,Object,G> downstream) {
		_pred = (owned) pred;
		_downstream = downstream;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Map<bool,Object> create_accumulator () {
		var map = new HashMap<bool,Object>();
		map.set(true, _downstream.create_accumulator());
		map.set(false, _downstream.create_accumulator());
		return map;
	}

	public void accumulate (G g, Map<bool,Object> a) {
		_downstream.accumulate(g, a[_pred(g)]);
	}

	public Map<bool,Object> combine (Map<bool,Object> a, Map<bool,Object> b) {
		a[true] = _downstream.combine(a[true], b[true]);
		a[false] = _downstream.combine(a[false], b[false]);
		return a;
	}

	public Map<bool,V> finish (Map<bool,Object> a) throws Error {
		var map = new HashMap<bool,V>();
		map[true] = _downstream.finish(a[true]);
		map[false] = _downstream.finish(a[false]);
		return map;
	}
}
