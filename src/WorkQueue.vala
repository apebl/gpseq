/* WorkQueue.vala
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
	 * A lock-free work stealing queue.
	 */
	internal class WorkQueue : Object {
		/**
		 * must be >= 2 (because of bitwise AND)
		 */
		private static int initial_queue_log_capacity;
		private const int TRY_INITIAL_QUEUE_LOG_CAPACITY = 10;

		/**
		 * Gets the initial size of queue arrays.
		 * @return the initial size of queue arrays
		 */
		private static int get_initial_queue_log_capacity () {
			/* no synchronization required for this method;
			 * the method always returns the same value on the same device
			 */
			if (initial_queue_log_capacity == 0) {
				initial_queue_log_capacity = int.min(TRY_INITIAL_QUEUE_LOG_CAPACITY, get_max_queue_log_capacity());
			}
			return initial_queue_log_capacity;
		}

		/**
		 * Must be //>= 2 && <= (bit size of int - 1 - width of array entry)// to ensure lack of
		 * wraparound of index calculations.
		 */
		private static int max_queue_log_capacity;
		/**
		 * A value to define 'max_queue_log_capacity' a bit less than
		 * //(bit size of int - 1 - width of array entry)//
		 */
		private const int QUEUE_LOG_CAPACITY_MARGIN = 1;

		/**
		 * Gets the maximum size of queue arrays.
		 * @return the maximum size of queue arrays
		 */
		private static int get_max_queue_log_capacity () {
			/* no synchronization required for this method;
			 * the method always returns the same value on the same device
			 */
			if (max_queue_log_capacity == 0) {
				double psize = (double) sizeof(void*); // size of gpointer
				int isize = ((int) sizeof(int)) * 8 - 1; // at least 15 in C lang
				int log_psize = (int) Math.log2(psize);
				int result = isize - log_psize - QUEUE_LOG_CAPACITY_MARGIN;
				max_queue_log_capacity = int.max(result, 2);
			}
			return max_queue_log_capacity;
		}

		private CircularArray<Task> _array;
		private int _head; // AtomicInt
		private int _tail;

		public WorkQueue () {
			_array = new CircularArray<Task>( get_initial_queue_log_capacity() );
		}

		public bool is_empty {
			get {
				/* The order is important! */
				int head = AtomicInt.get(ref _head); // never decreases
				int tail = _tail;
				return (tail <= head);
			}
		}

		public int size {
			get {
				/* The order is important! */
				int head = AtomicInt.get(ref _head);
				int tail = _tail;
				int size = tail - head;
				return (size < 0) ? 0 : size;
			}
		}

		private void grow_array (CircularArray<Task> current, int tail, int head) {
			int new_log_len = current.log_length + 1;
			if (new_log_len > get_max_queue_log_capacity()) {
				error( "Queue capacity exceeded: %d > %d",
						(1 << new_log_len),
						(1 << get_max_queue_log_capacity()) );
			}

			CircularArray<Task> new_array = new CircularArray<Task>(new_log_len);
			for (int i = head; i < tail; i++) {
				Task cmp = current[i];
				if (compare_and_exchange(current, i, cmp, null)) {
					new_array[i] = cmp;
					cmp.unref();
				}
			}
			_array = new_array;
		}

		/**
		 * Note. Called by owner thread
		 */
		public void offer_tail (Task item) {
			int old_tail = _tail;
			int old_head = AtomicInt.get(ref _head);
			CircularArray<Task> cur_array = _array;

			// resize
			int size = old_tail - old_head;
			if (size >= cur_array.length-1) {
				grow_array(cur_array, old_tail, old_head);
			}

			_array[old_tail] = item;
			_tail = old_tail + 1;
		}

		/**
		 * Note. Called by owner thread
		 */
		public Task? poll_tail () {
			CircularArray<Task> cur_array = _array;
			int t = _tail - 1;
			int old_head = AtomicInt.get(ref _head);

			int size = t - old_head;
			if (size < 0) {
				return null;
			}

			Task* oldval = (Task*) *cur_array.get_pointer(t);
			if (oldval != null) {
				if (compare_and_exchange(cur_array, t, oldval, null)) {
					_tail = t;
					Task? result = (Task?) oldval;
					result.unref();
					return result;
				}
			}
			return null;
		}

		/**
		 * Note. Called by non-owner threads
		 */
		public Task? poll_head () {
			int old_head = AtomicInt.get(ref _head); // never decreases
			int old_tail = _tail;
			CircularArray<Task> cur_array = _array;

			int size = old_tail - old_head;
			if (size <= 0) return null;

			Task* oldval = (Task*) *cur_array.get_pointer(old_head);
			if (oldval != null) {
				if (compare_and_exchange(cur_array, old_head, oldval, null)) {
					AtomicInt.set(ref _head, old_head + 1);
					Task? result = (Task?) oldval;
					result.unref();
					return result;
				}
			}
			return null;
		}

		private bool compare_and_exchange (CircularArray<Task> array,
				int idx, Task* oldval, Task* newval) {
			return AtomicPointer.compare_and_exchange(array.get_pointer(idx), oldval, newval);
		}

		private class CircularArray<G> : Object {
			private G[] _array;
			private int _log_length;

			/**
			 * Creates a new circular array.
			 * @param log_length log₂ of length. the length of the new array
			 * will be //1 << log_length//
			 */
			public CircularArray (int log_length)
					requires (log_length >= 2) // (because of bitwise AND)
			{
				_array = new G[1 << log_length];
				_log_length = log_length;
			}

			public int log_length {
				get {
					return _log_length;
				}
			}

			public int length {
				get {
					return _array.length;
				}
			}

			public new G @get (int idx) {
				// equivalent of '_array[idx % length]' (if length >= 4)
				// e.g.
				// let l is (256 - 1) = 255 = 0xff = 11111111₂
				// l & 0 = 0
				// l & 255 = 255
				// l & 256 = 0
				// l & 258 = 2
				return _array[(length-1) & idx];
			}

			public G** get_pointer (int idx) {
				return &_array[(length-1) & idx];
			}

			public new void @set (int idx, G item) {
				_array[(length-1) & idx] = item;
			}
		}
	}
}
