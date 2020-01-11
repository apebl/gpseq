/* ResultTests.vala
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

using Gpseq;

public class ResultTests : Gpseq.TestSuite {
	public ResultTests () {
		base("result");
		add_test("of", test_of);
		add_test("err", test_err);
		add_test("future", test_future);
		add_test("get", test_get);
		add_test("transform", test_transform);
		add_test("flat_map", test_flat_map);
		add_test("map", test_map);
		add_test("map_err", test_map_err);
		add_test("zip", test_zip);
		add_test("then", test_then);
		add_test("and_then", test_and_then);
	}

	private void test_of () {
		var result = Result.of<int>(726);
		assert(result.value == 726);
		assert(result.exception == null);
	}

	private void test_err () {
		var result = Result.err<int>( new OptionalError.NOT_PRESENT("An error") );
		assert(result.exception != null);
	}

	private void test_future () {
		var result = Result.of<int>(726);
		var future = result.future();
		assert(future.ready);
		assert(future.value == 726);
		assert(future.exception == null);
	}

	private void test_get () {
		var result = Result.of<int>(726);
		try {
			assert(result.get() == 726);
		} catch (Error err) {
			error("%s", err.message);
		}

		result = Result.err<int>( new OptionalError.NOT_PRESENT("An error") );
		try {
			result.get();
			assert_not_reached();
		} catch (Error err) {
		}
	}

	private void test_transform () {
		var result = Result.of<int>(726).transform<string>(f => {
			assert(f.value == 726 && f.exception == null);
			return Result.of<string>( f.value.to_string() );
		});
		assert(result.value == "726");
		assert(result.exception == null);
	}

	private void test_flat_map () {
		var result = Result.of<int>(726).flat_map<string>(val => {
			assert(val == 726);
			return Result.of<string>( val.to_string() );
		});
		assert(result.value == "726");
		assert(result.exception == null);
	}

	private void test_map () {
		var result = Result.of<int>(726).map<string>(val => {
			assert(val == 726);
			return val.to_string();
		});
		assert(result.value == "726");
		assert(result.exception == null);
	}

	private void test_map_err () {
		var error = new OptionalError.NOT_PRESENT("An error");
		var result = Result.err<int>(error).map_err(err => {
			return new OptionalError.NOT_PRESENT("An error!!");
		});
		assert(result.exception.message == "An error!!");
		result = Result.of<int>(726).map_err(err => {
			return error;
		});
		assert(result.value == 726);
		assert(result.exception == null);
	}

	private void test_zip () {
		var result = Result.of<int>(726);
		var result2 = Result.of<int>(10);
		var zip = result.zip<int,int>((a, b) => a * b, result2);
		assert(zip.value == 7260);
		assert(zip.exception == null);

		result = Result.of<int>(726);
		result2 = Result.err<int>( new OptionalError.NOT_PRESENT("An error") );
		zip = result.zip<int,int>((a, b) => a * b, result2);
		assert(zip.exception != null);
	}

	private void test_then () {
		var result = Result.of<int>(726);
		bool chk = false;
		result.then(res => {
			chk = true;
		});
		assert(chk);

		result = Result.err<int>( new OptionalError.NOT_PRESENT("An error") );
		chk = false;
		result.then(res => {
			chk = true;
		});
		assert(chk);
	}

	private void test_and_then () {
		var result = Result.of<int>(726);
		bool chk = false;
		result.and_then(res => {
			chk = true;
		});
		assert(chk);

		result = Result.err<int>( new OptionalError.NOT_PRESENT("An error") );
		chk = false;
		result.and_then(res => {
			chk = true;
		});
		assert(!chk);
	}
}
