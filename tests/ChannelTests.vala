/* ChannelTests.vala
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

public abstract class ChannelTests<G> : Gpseq.TestSuite {
	private const ulong SECONDS = 1000000; // microseconds in one second
	private const uint64 TIMEOUT = 2 * SECONDS;
	private const int THREADS = 32;
	private const int ITER_PER_THREAD = 100;

	private int _capacity;
	private int _key;

	protected ChannelTests (string name, int capacity) {
		base(name);
		_capacity = capacity;
		_key = (int) Random.next_int();
		register_tests();
	}

	private void register_tests () {
		add_test("close", test_close);
		add_test("capacity", test_capacity);
		add_test("length", test_length);
		add_test("send-recv", test_send_recv);
		add_test("send-recv-timeout", test_send_recv_timeout);
		add_test("try-send-recv", test_try_send_recv);
		add_test("recv-after-closed", test_recv_after_closed);
		add_test("parallel-send", test_parallel_send);
		add_test("parallel-recv", test_parallel_recv);
		add_test("parallel-send-recv", test_parallel_send_recv);
	}

	protected abstract Channel<G> create_channel (int cap);
	protected abstract bool equal (G a, G b);
	protected abstract G gen (int key);

	private void test_close () {
		var chan = create_channel(_capacity);
		new Thread<void*>("channel-test", () => {
			Thread.usleep(2 * SECONDS);
			chan.close();
			return null;
		});
		Result<G> result = chan.recv();
		assert(result.exception is ChannelError.CLOSED);
		Result<void*> result2 = chan.send( gen(_key) );
		assert(result2.exception is ChannelError.CLOSED);
	}

	private void test_capacity () {
		var chan = create_channel(_capacity);
		Optional<int64?> cap = chan.capacity;
		if (_capacity > 0) {
			assert(!cap.is_present || cap.value >= _capacity);
		} else {
			assert(cap.is_present && (!)cap.value == 0);
		}

		if (_capacity > 0 && cap.is_present) {
			for (int i = 1; i < 10; ++i) {
				chan = create_channel(i);
				assert(chan.capacity.value >= i);
			}
		}
	}

	private void test_length () {
		var chan = create_channel(_capacity);
		assert(chan.length == 0);
		if (_capacity == 0) return;
		int64 cap = chan.capacity.is_present ? (!)chan.capacity.value : (int64)_capacity;
		for (int64 i = 0; i < cap; i++) {
			var res = chan.send( gen(_key) );
			assert(res.exception == null);
			assert(chan.length == i+1);
		}
		if (chan.capacity.is_present) {
			assert( chan.try_send(gen(_key)).exception is ChannelError.TRY_FAILED );
		}
		assert(chan.length == cap);
		for (int64 i = 0; i < cap; i++) {
			chan.recv();
			assert(chan.length == cap-i-1);
		}
		assert( chan.try_recv().exception is ChannelError.TRY_FAILED );
		assert(chan.length == 0);
	}

	private void test_send_recv () {
		var chan = create_channel(_capacity);
		new Thread<void*>("channel-test", () => {
			chan.send( gen(_key) );
			return null;
		});
		Result<G> result = chan.recv();
		assert(result.exception == null);
		assert( equal(result.value, gen(_key)) );

		if (_capacity > 0) {
			for (int i = 0; i < _capacity; i++) {
				chan.send( gen(i) );
			}
			for (int i = 0; i < _capacity; i++) {
				var res = chan.recv();
				assert(res.exception == null);
				assert( equal(res.value, gen(i)) );
			}
		}
	}

	private void test_send_recv_timeout () {
		var chan = create_channel(_capacity);
		var recv_res = chan.recv_until( get_monotonic_time() + (int64)TIMEOUT );
		assert(recv_res.exception is ChannelError.TIMEOUT);

		new Thread<void*>("channel-test", () => {
			var send_res = chan.send( gen(_key) );
			assert(send_res.exception == null);
			return null;
		});
		recv_res = chan.recv_until( get_monotonic_time() + (int64)TIMEOUT );
		assert(recv_res.exception == null);
		assert( equal(recv_res.value, gen(_key)) );

		if (chan.capacity.is_present) {
			for (int i = 0; i < _capacity; i++) {
				var send_res = chan.send( gen(_key) );
				assert(send_res.exception == null);
			}
			var send_res = chan.send_until(gen(_key), get_monotonic_time() + (int64)TIMEOUT);
			assert(send_res.exception is ChannelError.TIMEOUT);
		}
	}

	private void test_try_send_recv () {
		var chan = create_channel(_capacity);
		Result<G> result = chan.try_recv();
		assert(result.exception is ChannelError.TRY_FAILED);

		if (_capacity == 0) {
			var thread = new Thread<void*>("channel-test", () => {
				Thread.usleep(2 * SECONDS);
				Result<void*> res = chan.try_send( gen(_key) );
				assert(res.exception == null);
				return null;
			});
			result = chan.recv();
			thread.join();
		} else {
			chan.try_send( gen(_key) );
			result = chan.try_recv();
		}
		assert( result.exception == null && equal(result.value, gen(_key)) );
		result = chan.try_recv();
		assert(result.exception is ChannelError.TRY_FAILED);
	}

	private void test_recv_after_closed () {
		var chan = create_channel(_capacity);
		chan.close();
		assert(chan.recv().exception is ChannelError.CLOSED);

		if (_capacity > 0) {
			chan = create_channel(_capacity);
			for (int i = 0; i < _capacity; i++) {
				var res = chan.send( gen(i) );
				assert(res.exception == null);
			}
			chan.close();
			for (int i = 0; i < _capacity; i++) {
				var res = chan.recv();
				assert(res.exception == null);
				assert( equal(res.value, gen(i)) );
			}
			assert(chan.recv().exception is ChannelError.CLOSED);
		}
	}

	private void test_parallel_send () {
		Thread<void*>[] threads = new Thread<void*>[THREADS];
		var chan = create_channel(_capacity);
		for (int i = 0; i < THREADS; i++) {
			threads[i] = new Thread<void*>("channel-test-" + i.to_string(), () => {
				for (int j = 0; j < ITER_PER_THREAD; j++) {
					var res = chan.send( gen(_key) );
					assert(res.exception == null);
				}
				return null;
			});
		}

		for (int i = 0; i < THREADS*ITER_PER_THREAD; i++) {
			var res = chan.recv();
			assert(res.exception == null);
			assert( equal(res.value, gen(_key)) );
		}

		assert(chan.length == 0);
		assert(chan.try_recv().exception is ChannelError.TRY_FAILED);

		for (int i = 0; i < THREADS; i++) {
			threads[i].join();
		}

		assert(chan.length == 0);
		assert(chan.try_recv().exception is ChannelError.TRY_FAILED);
	}

	private void test_parallel_recv () {
		Thread<void*>[] threads = new Thread<void*>[THREADS];
		var chan = create_channel(_capacity);
		for (int i = 0; i < THREADS; i++) {
			threads[i] = new Thread<void*>("channel-test-" + i.to_string(), () => {
				for (int j = 0; j < ITER_PER_THREAD; j++) {
					var res = chan.recv();
					assert(res.exception == null);
					assert( equal(res.value, gen(_key)) );
				}
				return null;
			});
		}

		for (int i = 0; i < THREADS*ITER_PER_THREAD; i++) {
			var res = chan.send( gen(_key) );
			assert(res.exception == null);
		}

		for (int i = 0; i < THREADS; i++) {
			threads[i].join();
		}

		assert(chan.length == 0);
		assert(chan.try_recv().exception is ChannelError.TRY_FAILED);
	}

	private void test_parallel_send_recv () {
		Thread<void*>[] senders = new Thread<void*>[THREADS];
		Thread<void*>[] receivers = new Thread<void*>[THREADS];
		var chan = create_channel(_capacity);
		for (int i = 0; i < THREADS; i++) {
			senders[i] = new Thread<void*>("channel-test-sender-" + i.to_string(), () => {
				for (int j = 0; j < ITER_PER_THREAD; j++) {
					var res = chan.send( gen(_key) );
					assert(res.exception == null);
				}
				return null;
			});
			receivers[i] = new Thread<void*>("channel-test-receiver-" + i.to_string(), () => {
				for (int j = 0; j < ITER_PER_THREAD; j++) {
					var res = chan.recv();
					assert(res.exception == null);
					assert( equal(res.value, gen(_key)) );
				}
				return null;
			});
		}

		for (int i = 0; i < THREADS; i++) {
			senders[i].join();
			receivers[i].join();
		}

		assert(chan.length == 0);
		assert(chan.try_recv().exception is ChannelError.TRY_FAILED);
	}
}
