/* SubArrayTests.vala
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
using TestUtils;

public class SubArrayTests : Gpseq.TestSuite {
	private const int LENGTH = 32;

	public SubArrayTests () {
		base("sub-array");
		add_test("constructor;get_data;get;size", test_constructor);
		add_test("set", test_set);
		add_test("foreach", test_foreach);
		add_test("sort", test_sort);
		add_test("sort:default-func", test_sort_default_func);
		add_test("copy", test_copy);
		add_test("copy_array", test_copy_array);
		add_test("sub_array", test_sub_array);
		add_test("iterator", test_iterator);
	}

	private GenericArray<int> create_rand_generic_array (int length) {
		var array = new GenericArray<int>(length);
		for (int i = 0; i < LENGTH; i++) {
			array.add( (int) Random.next_int() );
		}
		return array;
	}

	private void test_constructor () {
		string[] array = {"one", "two", "three", "four", "five"};
		var sub = new SubArray<string>(array);
		var sub2 = new SubArray<string>.from_sub_array(sub, 0, sub.size);
		assert(array.length == sub.size && sub.size == sub2.size);
		assert(array.length == sub.get_data().length && sub.get_data().length == sub2.get_data().length);
		for (int i = 0; i < array.length; i++) {
			assert(array[i] == sub[i] && sub[i] == sub2[i]);
			assert(array[i] == sub.get_data()[i] && sub.get_data()[i] == sub2.get_data()[i]);
		}
	}

	private void test_set () {
		string[] array = new string[5];
		var sub = new SubArray<string>(array);
		string[] validation = {"one", "two", "three", "four", "five"};
		for (int i = 0; i < 5; i++) {
			sub[i] = validation[i];
			assert(sub[i] == validation[i]);
		}
	}

	private void test_foreach () {
		var array = create_rand_generic_array(LENGTH);
		var sub = new SubArray<int>(array.data);
		var result = new GenericArray<int>(LENGTH / 2);
		int i = 0;
		sub.foreach(g => {
			result.add(g);
			if (++i == LENGTH / 2) return false;
			else return true;
		});
		assert(result.length == LENGTH / 2);
		for (int j = 0, n = LENGTH / 2; j < n; j++) {
			assert(result[j] == array[j]);
		}
	}

	private void test_sort () {
		var array = create_rand_generic_array(LENGTH);
		var sub = new SubArray<int>(array.data);
		CompareDataFunc<int> cmp = (a, b) => a < b ? -1 : (a == b ? 0 : 1);
		sub.sort((a, b) => cmp(a, b));
		assert_sorted<int>(sub.get_data(), (a, b) => cmp(a, b));
	}

	private void test_sort_default_func () {
		var array = create_rand_generic_array(LENGTH);
		var sub = new SubArray<int>(array.data);
		sub.sort();
		assert_sorted<int>(sub.get_data());
	}

	private void test_copy () {
		string[] array = {"one", "two", "three", "four", "five"};
		var sub = new SubArray<string>(array);
		string[] array2 = new string[5];
		var sub2 = new SubArray<string>(array2);
		sub2.copy(0, sub, 0, 5);
		assert_array_equals<string>(array, array2);
		assert_array_equals<string>(sub.get_data(), sub2.get_data());
	}

	private void test_copy_array () {
		string[] array = new string[5];
		var sub = new SubArray<string>(array);
		string[] array2 = {"one", "two", "three", "four", "five"};
		sub.copy_array(0, array2, 0, 5);
		assert_array_equals<string>(array, array2);
		assert_array_equals<string>(sub.get_data(), array2);
	}

	private void test_sub_array () {
		var array = create_rand_generic_array(LENGTH);
		var sub = new SubArray<int>(array.data);
		var sub2 = sub.sub_array(0, LENGTH / 2);
		assert(sub2.size == LENGTH / 2);
		for (int i = 0, n = LENGTH / 2; i < n; i++) {
			assert(sub[i] == sub2[i]);
		}
	}

	private void test_iterator () {
		string[] array = {"one", "two"};
		var sub = new SubArray<string>(array);
		assert(sub.size == 2);
		assert(sub[0] == "one");
		assert(sub[1] == "two");

		var iterator = sub.iterator();
		bool one_found = false;
		bool two_found = false;
		while ( iterator.next() ) {
			assert(iterator.valid);
			switch ( iterator.get() ) {
			case "one":
				assert(!one_found);
				one_found = true;
				break;
			case "two":
				assert(!two_found);
				two_found = true;
				break;
			default:
				assert_not_reached();
			}
		}
		assert(one_found);
		assert(two_found);
		assert( !iterator.has_next() );
		assert( !iterator.next() );

		iterator = sub.iterator();
		assert( iterator.has_next() );
		assert( iterator.next() );

		assert(sub.size == 2);
		assert(sub[0] == "one");
		assert(sub[1] == "two");
	}
}
