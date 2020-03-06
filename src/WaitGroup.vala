/* WaitGroup.vala
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
	[Version (since="0.3.0-alpha")]
	public class WaitGroup : Object {
		private Mutex _mutex;
		private Cond _cond;
		private int _count;

		public WaitGroup () {
			_mutex = Mutex();
			_cond = Cond();
		}

		/**
		 * Adds //delta// to the counter.
		 *
		 * All threads blocked on wait()/wait_until() are awakened if the
		 * counter becomes zero.
		 *
		 * If the counter becomes negative, fails with {@link GLib.error}.
		 *
		 * @param delta a delta which may be negative
		 */
		public void add (int delta = 1) {
			_mutex.lock();
			int sum;
			bool ovf = Overflow.int_add(_count, delta, out sum);
			if (ovf) error("WaitGroup counter overflowed");
			if (sum < 0) error("Negative WaitGroup counter");
			_count = sum;
			if (_count == 0) _cond.broadcast();
			_mutex.unlock();
		}

		/**
		 * Decreases the counter by one.
		 *
		 * All threads blocked on wait()/wait_until() are awakened if the
		 * counter becomes zero.
		 *
		 * If the counter becomes negative, fails with {@link GLib.error}.
		 */
		public void done () {
			add(-1);
		}

		/**
		 * Increases the counter by one and schedules the given function to
		 * execute. Next, decreases the counter by one after the function is
		 * executed.
		 *
		 * This is equivalent to:
		 *
		 * {{{
		 * waitgroup.add();
		 * return Gpseq.task<G>(() => {
		 *     try {
		 *         G result = func();
		 *         return (owned) result;
		 *     } catch (Error err) {
		 *         throw err;
		 *     } finally {
		 *         waitgroup.done();
		 *     }
		 * });
		 * }}}
		 *
		 * @param func a task function to execute
		 * @return a future of the execution
		 *
		 * @see Gpseq.task
		 */
		[Version (since="0.4.0-alpha")]
		public Future<G> task<G> (owned TaskFunc<G> func) {
			add();
			return Gpseq.task<G>(() => {
				try {
					G result = func();
					return (owned) result;
				} catch (Error err) {
					throw err;
				} finally {
					done();
				}
			});
		}

		/**
		 * Increases the counter by one and schedules the given function to
		 * execute. Next, decreases the counter by one after the function is
		 * executed.
		 *
		 * This is equivalent to:
		 *
		 * {{{
		 * waitgroup.add();
		 * return Gpseq.run(() => {
		 *     try {
		 *         func();
		 *     } catch (Error err) {
		 *         throw err;
		 *     } finally {
		 *         waitgroup.done();
		 *     }
		 * });
		 * }}}
		 *
		 * @param func a task function to execute
		 * @return a future of the execution
		 *
		 * @see Gpseq.run
		 */
		[Version (since="0.4.0-alpha")]
		public Future<void*> run (owned VoidTaskFunc func) {
			add();
			return Gpseq.run(() => {
				try {
					func();
				} catch (Error err) {
					throw err;
				} finally {
					done();
				}
			});
		}

		/**
		 * Waits until the counter is zero.
		 */
		public void wait () {
			_mutex.lock();
			while (_count != 0) {
				_cond.wait(_mutex);
			}
			_mutex.unlock();
		}

		/**
		 * Waits until the counter is zero or //end_time// has passed.
		 *
		 * @return false on a timeout, true otherwise
		 */
		public bool wait_until (int64 end_time) {
			_mutex.lock();
			while (_count != 0) {
				if ( !_cond.wait_until(_mutex, end_time) ) {
					_mutex.unlock();
					return false;
				}
			}
			_mutex.unlock();
			return true;
		}
	}
}
