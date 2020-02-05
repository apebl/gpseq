/* TestUtilsTests.vala
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

using Test;
using Gpseq;
using TestUtils;

public class TestUtilsTests : Gpseq.TestSuite {
	private const uint64 TRAP_TIMEOUT = 10000000; // 10s
	private const TestSubprocessFlags TRAP_FLAGS = TestSubprocessFlags.STDOUT;

	public TestUtilsTests () {
		base("test-utils");

		add_test("assert_sorted", test_assert_sorted);
		add_subprocess("assert_sorted/subprocess", subprocess_assert_sorted);
		add_subprocess("assert_sorted/subprocess2", subprocess_assert_sorted2);
		add_subprocess("assert_sorted/subprocess3", subprocess_assert_sorted3);

		add_test("assert_all_elements", test_assert_all_elements);
		add_subprocess("assert_all_elements/subprocess", subprocess_assert_all_elements);
		add_subprocess("assert_all_elements/subprocess2", subprocess_assert_all_elements2);
	}

	private static GenericArray<int> int_array_to_generic_array (int[] array) {
		GenericArray<int> result = new GenericArray<int>(array.length);
		for (int i = 0; i < array.length; i++) {
			result.add(array[i]);
		}
		return result;
	}

	private void test_assert_sorted () {
		trap("assert_sorted/subprocess", TRAP_TIMEOUT, TRAP_FLAGS);
		trap_assert_passed();
		trap("assert_sorted/subprocess2", TRAP_TIMEOUT, TRAP_FLAGS);
		trap_assert_failed();
		trap("assert_sorted/subprocess3", TRAP_TIMEOUT, TRAP_FLAGS);
		trap_assert_failed();
	}

	private static void subprocess_assert_sorted () {
		var array = int_array_to_generic_array({1, 2, 3, 4, 5});
		assert_sorted<int>(array.data);
	}

	private static void subprocess_assert_sorted2 () {
		var array = int_array_to_generic_array({5, 4, 3, 2, 1});
		assert_sorted<int>(array.data);
	}

	private static void subprocess_assert_sorted3 () {
		var array = int_array_to_generic_array({1, 4, 3, 2, 5});
		assert_sorted<int>(array.data);
	}

	private void test_assert_all_elements () {
		trap("assert_all_elements/subprocess", TRAP_TIMEOUT, TRAP_FLAGS);
		trap_assert_passed();
		trap("assert_all_elements/subprocess2", TRAP_TIMEOUT, TRAP_FLAGS);
		trap_assert_failed();
	}

	private static void subprocess_assert_all_elements () {
		var array = int_array_to_generic_array({1, 2, 3, 4, 5});
		assert_all_elements<int>(array.data, g => g < 10);
	}

	private static void subprocess_assert_all_elements2 () {
		var array = int_array_to_generic_array({1, 2, 3, 4, 5});
		assert_all_elements<int>(array.data, g => g % 2 == 0);
	}
}
