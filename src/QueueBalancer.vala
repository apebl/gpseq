/* QueueBalancer.vala
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
	 * An object that performs load balancing of work queues.
	 *
	 * A {@link WorkerThread} have its own {@link QueueBalancer}. so, the
	 * balancers can declare and use member variables to store data per thread.
	 *
	 * All methods are called in the owner {@link WorkerThread} thread.
	 */
	internal interface QueueBalancer : Object {
		/**
		 * Will be called after the thread failed to obtain a task.
		 *
		 * @param thread the worker thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void no_tasks (WorkerThread thread, bool join);

		/**
		 * Finds and takes tasks from other threads' work queue and the
		 * submission queue.
		 *
		 * This method must take at least one task, if possible -- at least one
		 * task exists in other threads' work queue or the submission queue.
		 *
		 * @param thread the worker thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void scan (WorkerThread thread, bool join);
	}
}
