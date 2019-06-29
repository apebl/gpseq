/* TestUtils.vala
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
using Gpseq;

namespace TestUtils {
	public void assert_sorted<G> (G[] array, owned CompareDataFunc<G>? compare = null) {
		if (compare == null) compare = Gee.Functions.get_compare_func_for(typeof(G));
		for (int i = 0; i < array.length - 1; i++) {
			assert( compare(array[i], array[i+1]) <= 0 );
		}
	}

	public void assert_all_elements<G> (G[] array, Gee.Predicate<G> pred) {
		for (int i = 0; i < array.length; i++) {
			assert( pred(array[i]) );
		}
	}

	public void assert_iter_equals<G> (Iterator<G> a, Iterator<G> b, owned EqualDataFunc<G>? equal = null) {
		assert( (a.valid || a.has_next()) == (b.valid || b.has_next()) );
		if (!a.valid && !a.has_next()) return;
		if (!a.valid) a.next();
		if (!b.valid) b.next();
		if (equal == null) equal = Gee.Functions.get_equal_func_for(typeof(G));
		assert( equal(a.get(), b.get()) );
		while (true) {
			bool a_next = a.next();
			assert( a_next == b.next() );
			if (a_next) {
				assert( equal(a.get(), b.get()) );
			} else {
				break;
			}
		}
	}

	public void assert_array_equals<G> (G[] array, G[] array2, owned EqualDataFunc<G>? equal = null) {
		assert(array.length == array2.length);
		if (equal == null) equal = Gee.Functions.get_equal_func_for(typeof(G));
		for (int i = 0; i < array.length; i++) {
			assert( equal(array[i], array2[i]) );
		}
	}

	public void assert_map_equals<K,V> (Map<K,V> a, Map<K,V> b, owned EqualDataFunc<V>? equal = null) {
		assert(a.size == b.size);
		if (equal == null) equal = Gee.Functions.get_equal_func_for(typeof(V));
		foreach (K key in a.keys) {
			assert( b.has_key(key) );
			assert( equal(a[key], b[key]) );
		}
	}

	public int compare_nullable_int (int? a, int? b) {
		if (a == b) return 0;
		else if (a == null) return -1;
		else if (b == null) return 1;
		else return a < b ? -1 : (a == b ? 0 : 1);
	}

	public GenericArray<G> iter_to_generic_array<G> (Iterator<G> iter, uint reserved_size = 0) {
		GenericArray<G> array = new GenericArray<G>(reserved_size);
		iter.foreach(g => {
			array.add(g);
			return true;
		});
		return array;
	}

	public GenericArray<G> list_to_generic_array<G> (Gee.List<G> list) {
		GenericArray<G> array = new GenericArray<G>(list.size);
		// Don't traverse the list by index -- consider the case where the list is a linked list
		Iterator<G> iter = list.iterator();
		while ( iter.next() ) {
			array.add( iter.get() );
		}
		return array;
	}

	public G? iter_pick_random<G> (Iterator<G> iter, int64 len, out int64? index = null) {
		int64 i = 0;
		int64 pick = Random.int_range(0, (int32)int64.min(len, int32.MAX));
		while (iter.next()) {
			if (i++ == pick) {
				index = i;
				return iter.get();
			}
		}
		return null;
	}

	public string random_str (int length, Rand? rand = null) {
		StringBuilder buf = new StringBuilder.sized(length);
		for (int i = 0; i < length; i++) {
			buf.append_c( random_char(48, 126, rand) );
		}
		return buf.str;
	}

	private char random_char (char from, char to, Rand? rand = null) {
		return rand == null ? (char)Random.int_range(from, to + 1) : (char)rand.int_range(from, to + 1);
	}

	public class FiniteSupplyIterator<G> : Object, Traversable<G>, Iterator<G> {
		private SupplyFunc<G> _func;
		private G? _item;
		private int64 _length;
		private int64 _cur;

		public FiniteSupplyIterator (owned SupplyFunc<G> func, int64 length) {
			_func = (owned) func;
			_length = length;
		}

		public bool @foreach (ForallFunc<G> f) {
			while (_cur < _length) {
				_cur++;
				_item = _func();
				if ( !f(_item) ) return false;
			}
			return true;
		}

		public bool read_only {
			get {
				return true;
			}
		}

		public bool valid {
			get {
				return _cur > 0;
			}
		}

		public new G @get () {
			assert(_cur > 0);
			return _item;
		}

		public bool has_next () {
			return _cur < _length;
		}

		public bool next () {
			if (_cur < _length) {
				_cur++;
				_item = _func();
				return true;
			} else {
				return false;
			}
		}

		public void remove () {
			error("read-only iterator");
		}
	}

	public class LimitedIterator<G> : Object, Traversable<G>, Iterator<G> {
		private Iterator<G> _iter;
		private int64 _limit;
		private bool _unlimited;

		public LimitedIterator (Iterator<G> iter, int64 limit) {
			_iter = iter;
			_limit = limit > 0 ? limit : -1;
			if (_iter.valid && _limit > 0) _limit--;
			_unlimited = limit < 0;
		}

		public bool @foreach (ForallFunc<G> f) {
			bool result = true;
			if (_iter.valid) _limit++;
			_iter.foreach(g => {
				if (_limit > 0 || _unlimited) {
					_limit--;
					result = f(g);
					return result;
				} else {
					return false;
				}
			});
			return result;
		}

		public bool read_only {
			get {
				return true;
			}
		}

		public bool valid {
			get {
				return (_limit >= 0 || _unlimited) && _iter.valid;
			}
		}

		public new G @get () {
			assert(_limit >= 0 || _unlimited);
			return _iter.@get();
		}

		public bool has_next () {
			return (_limit > 0 || _unlimited) && _iter.has_next();
		}

		public bool next () {
			if ( has_next() ) {
				_limit--;
				return _iter.next();
			} else {
				return false;
			}
		}

		public void remove () {
			error("read-only iterator");
		}
	}

	public class MappedIterator<R,G> : Object, Traversable<R>, Iterator<R> {
		private Iterator<G> _iter;
		private Gee.MapFunc<R,G> _func;

		public MappedIterator (Iterator<G> iter, owned Gee.MapFunc<R,G> func) {
			_iter = iter;
			_func = (owned) func;
		}

		public bool @foreach (ForallFunc<R> f) {
			return _iter.foreach(g => {
				return f( _func(g) );
			});
		}

		public bool read_only {
			get {
				return _iter.read_only;
			}
		}

		public bool valid {
			get {
				return _iter.valid;
			}
		}

		public new R @get () {
			return _func( _iter.@get() );
		}

		public bool has_next () {
			return _iter.has_next();
		}

		public bool next () {
			return _iter.next();
		}

		public void remove () {
			_iter.remove();
		}
	}
}
