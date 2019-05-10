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
	 * A {@link ForkJoinThread} have its own {@link QueueBalancer}. so, the
	 * balancers can declare and use member variables to store data per thread.
	 *
	 * All methods are called in the owner {@link ForkJoinThread} thread.
	 *
	 * loop flow:
	 *
	 *  i. {@link tick} : every loop start
	 *  i. try obtaining a task in the queue of the current thread
	 *    * if obtained, the thread computes it. and => {@link computed}
	 *      * at this step, if join == true, the loop ends
	 *    * if not obtained (no tasks exist in the queue)
	 *      i. {@link no_tasks}
	 *      i. at this step, if join == false, the thread may be deactivated by pool
	 *      i. {@link scan}
	 */
	internal interface QueueBalancer : Object {
		/**
		 * Will be called at every loop start.
		 * @param thread the fork-join thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void tick (ForkJoinThread thread, bool join);

		/**
		 * Will be called after the thread obtained a task and has computed it.
		 * @param thread the fork-join thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void computed (ForkJoinThread thread, bool join);

		/**
		 * Will be called after the thread failed to obtain a task.
		 * @param thread the fork-join thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void no_tasks (ForkJoinThread thread, bool join);

		/**
		 * Finds and takes tasks from other threads' work queue and the
		 * submission queue.
		 *
		 * This method must take at least one task, if possible -- at least one
		 * task exists in other threads' work queue or the submission queue.
		 *
		 * @param thread the fork-join thread
		 * @param join whether or not current loop is joining loop of a task
		 */
		public abstract void scan (ForkJoinThread thread, bool join);
	}
}
