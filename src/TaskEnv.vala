/* TaskEnv.vala
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

namespace Gpseq {
	/**
	 * An object to configure the environment of execution of tasks
	 */
	public abstract class TaskEnv : Object {
		private static TaskEnv? default_task_env;

		/**
		 * Gets the default task environment.
		 *
		 * The default task environment is constructed when this method is
		 * called initially, if has not yet been set.
		 *
		 * @return the default task environment
		 */
		public static TaskEnv get_default_task_env () {
			lock (default_task_env) {
				if (default_task_env == null) {
					default_task_env = new DefaultTaskEnv();
				}
				return default_task_env;
			}
		}

		/**
		 * Sets the default task environment.
		 * @param task_env a task environment
		 */
		public static void set_default_task_env (TaskEnv task_env) {
			lock (default_task_env) {
				default_task_env = task_env;
			}
		}

		/**
		 * The executor for parallel tasks.
		 */
		public abstract Executor executor {
			get;
		}

		/**
		 * Calculates the proper threshold.
		 *
		 * @param elements an estimate of the number of elements. it is negative
		 * if infinite or unknown.
		 * @param threads the number of threads (always >= 1)
		 * @return threshold (must be >= 1)
		 * @see ForkJoinTask.threshold
		 */
		public abstract int64 resolve_threshold (int64 elements, int threads);

		/**
		 * Calculates the proper max depth.
		 *
		 * @param elements an estimate of the number of elements. it is negative
		 * if infinite or unknown.
		 * @param threads the number of threads (always >= 1)
		 * @return max depth. 0: no split, 1: one split, 2: two split, ... (a
		 * split may generate one or more child nodes). unlimited if negative
		 * @see ForkJoinTask.max_depth
		 */
		public abstract int resolve_max_depth (int64 elements, int threads);
	}
}
