/* DefaultTaskEnv.vala
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

namespace Gpseq {
	/**
	 * Default task env implementation.
	 */
	internal class DefaultTaskEnv : TaskEnv {
		private const int64 MIN_THRESHOLD = 32768; // 1 << 15
		private const int64 THRESHOLD_UNKNOWN = 4194304; // 1 << 22

		private Executor _executor;

		public DefaultTaskEnv () {
			try {
				_executor = new WorkerPool.with_defaults();
			} catch (Error err) {
				error(err.message);
			}
		}

		public override Executor executor {
			get {
				return _executor;
			}
		}

		public override int64 resolve_threshold (int64 elements, int threads) {
			if (threads == 1) return elements;
			if (elements < 0) return THRESHOLD_UNKNOWN;
			int64 t = threads;
			t = elements / t*2;
			return int64.max(t, MIN_THRESHOLD);
		}

		public override int resolve_max_depth (int64 elements, int threads) {
			if (threads == 1) return 0;

			int n;
			bool ovf = Overflow.int_mul(threads, 8, out n);
			if (ovf) ovf = Overflow.int_mul(threads, 4, out n);
			if (ovf) n = threads;

			int v = 1, i = 0;
			while (v < n) {
				ovf = Overflow.int_add(v, v, out v);
				i++;
				if (ovf) break;
			}
			return i;
		}
	}
}
