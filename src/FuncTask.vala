/* FuncTask.vala
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
	 * A function task.
	 */
	public class FuncTask<G> : Object, Task<G> {
		private TaskFunc<G> _func;
		private Promise<G> _promise;

		/**
		 * Creates a new func task.
		 *
		 * @param func a task function
		 */
		public FuncTask (owned TaskFunc<G> func) {
			_func = (owned) func;
			_promise = new Promise<G>();
		}

		public Future<G> future {
			get {
				return _promise.future;
			}
		}

		public void compute () {
			try {
				_promise.set_value(_func());
			} catch (Error err) {
				_promise.set_exception((owned) err);
			}
		}
	}
}
