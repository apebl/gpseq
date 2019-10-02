/* FutureTests.vala
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

public class FutureTests : Gpseq.TestSuite {
	private const ulong SECONDS = 1000000; // microseconds in one second

	public FutureTests () {
		base("future");
		add_test("promise", test_promise);
		add_test("future-of", test_future_of);
		add_test("wait", test_wait);
		add_test("wait_until:completed", () => test_wait_until(true));
		add_test("wait_until:time-out", () => test_wait_until(false));
		add_test("transform", test_transform);
		add_test("zip", test_zip);
	}

	private void test_promise () {
		var promise = new Promise<int>();
		var future = promise.future;
		assert(!future.ready);
		promise.set_value(726);
		assert(future.ready);
		assert(future.value == 726);
		assert(future.exception == null);

		promise = new Promise<int>();
		future = promise.future;
		assert(!future.ready);
		promise.set_exception( new OptionalError.NOT_PRESENT("An error") );
		assert(future.ready);
		assert(future.exception != null);
	}

	private void test_future_of () {
		var future = Future.of<int>(726);
		assert(future.ready);
		assert(future.value == 726);
		assert(future.exception == null);
	}

	private void test_wait () {
		var promise = new Promise<int>();
		var future = promise.future;
		new Thread<void*>("future-test", () => {
			Thread.usleep(1 * SECONDS);
			promise.set_value(726);
			return null;
		});
		try {
			int result = future.wait();
			assert(result == 726);
			assert(future.ready);
		} catch (Error err) {
			assert_not_reached();
		}
	}

	private void test_wait_until (bool complete) {
		var promise = new Promise<int>();
		var future = promise.future;
		if (complete) {
			new Thread<void*>("future-test", () => {
				Thread.usleep(1 * SECONDS);
				promise.set_value(726);
				return null;
			});
		}
		try {
			int value;
			bool result = future.wait_until(
					get_monotonic_time() + 3*SECONDS, out value);
			assert(result == complete);
			if (complete) {
				assert(future.ready);
				assert(value == 726);
			} else {
				assert(!future.ready);
			}
		} catch (Error err) {
			assert_not_reached();
		}
	}

	private void test_transform () {
		var promise = new Promise<int>();
		var future = promise.future.transform<string>(f => {
			assert(f.future().ready && f.exception == null);
			return Future.of<string>( f.value.to_string() );
		});
		promise.set_value(726);
		assert(future.future().ready);
		assert(future.value == "726");
		assert(future.exception == null);
	}

	private void test_zip () {
		var promise = new Promise<int>();
		var promise2 = new Promise<int>();
		var future = promise.future.zip<int,int>((a, b) => {
			return a * b;
		}, promise2.future);
		promise.set_value(726);
		promise2.set_value(10);
		assert(future.future().ready);
		assert(future.value == 7260);
		assert(future.exception == null);

		promise = new Promise<int>();
		promise2 = new Promise<int>();
		future = promise.future.zip<int,int>((a, b) => {
			return a * b;
		}, promise2.future);
		promise.set_exception( new OptionalError.NOT_PRESENT("An error") );
		promise2.set_value(10);
		assert(future.future().ready);
		assert(future.exception != null);
	}
}
