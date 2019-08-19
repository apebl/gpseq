/* WorkerContext.vala
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

using Gee;

namespace Gpseq {
	internal class WorkerContext : Object {
		private unowned WorkerPool _pool;
		private WorkQueue _work_queue;
		private QueueBalancer _balancer;

		public WorkerContext (WorkerPool pool) {
			_pool = pool;
			_work_queue = new WorkQueue();
			_balancer = new DefaultQueueBalancer();
		}

		public WorkerPool pool {
			get {
				return _pool;
			}
		}

		/**
		 * The work queue of this context.
		 */
		internal WorkQueue work_queue {
			get {
				return _work_queue;
			}
		}

		/**
		 * The queue balancer of this context.
		 */
		internal QueueBalancer balancer {
			get {
				return _balancer;
			}
		}
	}
}
