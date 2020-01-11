/* DefaultQueueBalancer.vala
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
	 * Default queue balancer implementation.
	 */
	internal class DefaultQueueBalancer : Object, QueueBalancer {
		/**
		 * The capacity to drain submissions at once.
		 */
		private const int DRAIN_CAPACITY = 256; // 1 << 8

		private Rand _rand;

		public DefaultQueueBalancer () {
			_rand = new Rand();
		}

		public void no_tasks (WorkerContext context) {
			Thread.yield();
		}

		public void scan (WorkerContext context) {
			if (!try_steal(context)) try_drain_submissions(context);
		}

		/**
		 * @return whether or not tasks are taken successfully
		 */
		private bool try_steal (WorkerContext context) {
			int size = context.pool.parallels;
			if (size <= 1) return false;
			int start = _rand.int_range(0, size);
			return do_steal(context, start);
		}

		private bool do_steal (WorkerContext stealer, int search_start) {
			WorkQueue sq = stealer.work_queue;
			Gee.List<WorkerContext> contexts = stealer.pool.contexts;
			int len = contexts.size;
			for (long i = search_start, n = search_start + len; i < n; i++) {
				int idx = (int) (i % len);
				WorkerContext victim = contexts[idx];
				WorkQueue vq = victim.work_queue;
				int size = vq.size;
				if (size > 1) size = size >> 1;
				bool taken = false;
				while (size > 0) {
					Task? task = vq.poll_head();
					if (task == null) break;
					sq.offer_tail(task);
					size--;
					taken = true;
				}
				if (taken) return true;
			}
			return false;
		}

		private void try_drain_submissions (WorkerContext context) {
			WorkerPool pool = context.pool;
			for (int i = 0; i < DRAIN_CAPACITY; i++) {
				Task? task = pool.submission_queue.poll_head();
				if (task == null) break;
				context.work_queue.offer_tail(task);
			}
		}
	}
}
