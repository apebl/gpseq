/* Task.vala
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
	 * A task that will be executed by a {@link Executor}.
	 *
	 * Note. Tasks are not reusable.
	 */
	public interface Task<G> : Object {
		/**
		 * The future result of this task.
		 */
		public abstract Future<G> future { get; }

		/**
		 * Computes the task and sets a value or an error to the
		 * {@link Task.future}.
		 */
		public abstract void compute ();

		/**
		 * Immediately performs the task computation.
		 *
		 * @throws Error an error occurred in the {@link future}
		 */
		public void invoke () throws Error {
			compute();
			Error? err = future.exception;
			if (err != null) throw err;
		}
	}
}
