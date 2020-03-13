/* BlockingTests.vala
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

public class BlockingTests : Gpseq.TestSuite {
	private const ulong SECONDS = 1000000; // microseconds in one second
	private const int MAX_THREADS = 1000;

	public BlockingTests () {
		base("blocking");
		add_test("blocking-tasks", test_blocking_tasks);
	}

	public override void set_up () {
		TaskEnv env = TaskEnv.get_common_task_env();
		WorkerPool pool = (WorkerPool) env.executor;
		pool.max_threads = int.max(pool.parallels, MAX_THREADS);
	}

	private void test_blocking_tasks () {
		Future<void*> future = Future.of<void*>(null);
		for (int i = 0; i < 100; i++) {
			var f = task<void*>(() => {
				blocking(() => {
					Thread.usleep(1 * SECONDS);
				});
				return null;
			});
			future = (Future<void*>) future.flat_map<void*>(g => f);
		}
		try {
			assert( future.wait_until(get_monotonic_time() + 8*SECONDS) );
		} catch (Error err) {
			assert_not_reached();
		}
	}
}
