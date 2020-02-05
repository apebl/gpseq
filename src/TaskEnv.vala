/* TaskEnv.vala
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
	 * An object to configure the environment of execution of tasks
	 */
	public abstract class TaskEnv : Object {
		private static TaskEnv? default_task_env;
		private static Gee.ArrayQueue<TaskEnv> stack;

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
		 * Gets the common task environment.
		 *
		 * If //task env stack// is not empty, returns the top of the stack. If
		 * empty, returns the default task environment.
		 *
		 * @return the common task environment
		 * @see get_default_task_env
		 * @see push
		 * @see pop
		 */
		[Version (since="0.2.0-alpha")]
		public static TaskEnv get_common_task_env () {
			lock (stack) {
				if (stack == null) {
					stack = new Gee.ArrayQueue<TaskEnv>();
				}
				return stack.is_empty ? get_default_task_env() : stack.peek_head();
			}
		}

		/**
		 * Pushs the given task environment into //task env stack//.
		 *
		 * @param task_env a task environment
		 * @see pop
		 * @see get_common_task_env
		 */
		[Version (since="0.2.0-alpha")]
		public static void push (TaskEnv task_env) {
			lock (stack) {
				if (stack == null) {
					stack = new Gee.ArrayQueue<TaskEnv>();
				}
				stack.offer_head(task_env);
			}
		}

		/**
		 * Remove an element from the top of //task env stack//.
		 *
		 * @see push
		 * @see get_common_task_env
		 */
		[Version (since="0.2.0-alpha")]
		public static void pop () {
			lock (stack) {
				if (stack == null) {
					stack = new Gee.ArrayQueue<TaskEnv>();
				}
				assert(!stack.is_empty);
				stack.poll_head();
			}
		}

		/**
		 * Runs the function with the given task environment as the common task
		 * environment.
		 *
		 * This is equivalent to:
		 *
		 * {{{
		 * TaskEnv.push(task_env);
		 * func();
		 * TaskEnv.pop();
		 * }}}
		 *
		 * @see get_common_task_env
		 * @see push
		 * @see pop
		 */
		[Version (since="0.2.0-alpha")]
		public static void apply (TaskEnv task_env, VoidFunc func) {
			push(task_env);
			func();
			pop();
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
