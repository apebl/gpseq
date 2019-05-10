/* AtomicTests.vala
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

public class AtomicTests : Gpseq.TestSuite {
	private const int THREADS = 12;
	private const int ROUNDS = 777;

	public AtomicTests () {
		base("atomic");
		add_test("int64-op", test_int64_op);
		add_test("int64-atomicity", test_atomicity);
	}

	private void test_int64_op () {
		int64 atomic = 0;

		atomic_int64_set(ref atomic, 10);
		assert(atomic == 10);
		assert(atomic == atomic_int64_get(ref atomic));

		atomic_int64_inc(ref atomic);
		assert(atomic == 11);

		for (int i = 0; i < 10; i++) {
			assert( !atomic_int64_dec_and_test(ref atomic) );
		}
		assert( atomic_int64_dec_and_test(ref atomic) );

		assert( atomic_int64_compare_and_exchange(ref atomic, 0, 77) );
		assert(atomic == 77);
		assert( atomic_int64_compare_and_exchange(ref atomic, 77, 10) );
		assert(atomic == 10);
		assert( !atomic_int64_compare_and_exchange(ref atomic, 11, 1) );
		assert(atomic == 10);

		assert(atomic_int64_add(ref atomic, 2) == 10);
		assert(atomic == 12);

		uint64 uatomic = 10;
		assert(atomic_int64_and(ref uatomic, 2) == 10);
		assert(uatomic == 2);
		assert(atomic_int64_or(ref uatomic, 12) == 2);
		assert(uatomic == 14);
		assert(atomic_int64_xor(ref uatomic, 7) == 14);
		assert(uatomic == 9);
	}

	private void test_atomicity () {
		Thread<void*>[] threads = new Thread<void*>[THREADS];
		int64 atomic = 0;
		for (int i = 0; i < THREADS; i++) {
			threads[i] = new Thread<void*>("atomicity-test-" + i.to_string(), () => {
				for (int j = 0; j < ROUNDS; j++) {
					atomic_int64_add(ref atomic, 7);
					Thread.yield();
				}
				return null;
			});
		}
		for (int i = 0; i < THREADS; i++) {
			threads[i].join();
		}
		assert(atomic == THREADS * ROUNDS * 7);
	}
}
