/* MapCollector.vala
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

private class Gpseq.Collectors.MapCollector<K,V,G> : Object, Collector<Map<K,V>,Map<K,V>,G> {
	private MapFunc<K,G> _key_mapper;
	private MapFunc<V,G> _val_mapper;
	private CombineFunc<V> _merger;
	private HashDataFunc<K>? _key_hash;
	private EqualDataFunc<K>? _key_equal;
	private EqualDataFunc<V>? _value_equal;

	public MapCollector (
			owned MapFunc<K,G> key_mapper, owned MapFunc<V,G> val_mapper,
			owned CombineFunc<V> merger,
			owned HashDataFunc<K>? key_hash = null,
			owned EqualDataFunc<K>? key_equal = null,
			owned EqualDataFunc<V>? value_equal = null) {
		if (key_hash == null) key_hash = Functions.get_hash_func_for(typeof(K));
		if (key_equal == null) key_equal = Functions.get_equal_func_for(typeof(K));
		if (value_equal == null) value_equal = Functions.get_equal_func_for(typeof(V));
		_key_mapper = (owned) key_mapper;
		_val_mapper = (owned) val_mapper;
		_merger = (owned) merger;
		_key_hash = (owned) key_hash;
		_key_equal = (owned) key_equal;
		_value_equal = (owned) value_equal;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Map<K,V> create_accumulator () throws Error {
		return new HashMap<K,V>(
			(v) => _key_hash(v),
			(a, b) => _key_equal(a, b),
			(a, b) => _value_equal(a, b) );
	}

	public void accumulate (G g, Map<K,V> a) throws Error {
		K key = _key_mapper(g);
		V val = _val_mapper(g);
		if (a.has_key(key)) {
			a[key] = _merger(a[key], val);
		} else {
			a[key] = val;
		}
	}

	public Map<K,V> combine (Map<K,V> a, Map<K,V> b) throws Error {
		foreach (K key in b.keys) {
			if (a.has_key(key)) {
				a[key] = _merger(a[key], b[key]);
			} else {
				a[key] = b[key];
			}
		}
		return a;
	}

	public Map<K,V> finish (Map<K,V> a) throws Error {
		return a;
	}
}
