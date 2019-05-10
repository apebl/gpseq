/* TestTaskEnv.vala
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

public class TestTaskEnv : TaskEnv {
	private const int64 MIN_THRESHOLD = 1024; // 1 << 10
	private const int64 THRESHOLD_UNKNOWN = 8192; // 1 << 13

	private static TestTaskEnv? instance;

	public static TestTaskEnv get_instance () {
		if (instance == null) instance = new TestTaskEnv();
		return instance;
	}

	private Executor _executor;

	private TestTaskEnv () {
		_executor = new ForkJoinPool.with_defaults();
	}

	public override Executor executor {
		get {
			return _executor;
		}
	}

	public override int64 resolve_threshold (int64 elements, int threads) {
		if (threads == 1) return elements;
		if (elements < 0) return THRESHOLD_UNKNOWN;
		int64 t = elements / (threads * 2);
		return int64.max(t, MIN_THRESHOLD);
	}

	public override int resolve_max_depth (int64 elements, int threads) {
		if (threads == 1) return 0;
		int n = int.max(threads * 4, threads * 8);
		n = int.max(threads, n);
		int v = 1, i = 0;
		while (v < n) {
			v = v << 1;
			i++;
		}
		return i;
	}
}
