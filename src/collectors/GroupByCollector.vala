/* GroupByCollector.vala
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

private class Gpseq.Collectors.GroupByCollector<K,V,G> : Object, Collector<Map<K,V>,Map<K,Object>,G> {
	private MapFunc<K,G> _classifier;
	private Collector<V,Object,G> _downstream;

	public GroupByCollector (owned MapFunc<K,G> classifier, Collector<V,Object,G> downstream) {
		_classifier = (owned) classifier;
		_downstream = downstream;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Map<K,Object> create_accumulator () {
		return new HashMap<K,Object>();
	}

	public void accumulate (G g, Map<K,Object> a) {
		K key = _classifier(g);
		Object container = getContainer(a, key);
		_downstream.accumulate(g, container);
	}

	public Map<K,Object> combine (Map<K,Object> a, Map<K,Object> b) {
		foreach (K key in b.keys) {
			Object container = getContainer(a, key);
			a[key] = _downstream.combine(container, b[key]);
		}
		return a;
	}

	public Map<K,V> finish (Map<K,Object> a) {
		foreach (Map.Entry<K,Object> e in a.entries) {
			e.value = (Object)_downstream.finish(e.value);
		}
		return (Map<K,V>)a;
	}

	private Object getContainer (Map<K,Object> accumulator, K key) {
		if (accumulator.has_key(key)) {
			return accumulator[key];
		} else {
			Object container = _downstream.create_accumulator();
			accumulator[key] = container;
			return container;
		}
	}
}
