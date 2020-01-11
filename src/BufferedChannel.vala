/* BufferedChannel.vala
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
	 * Buffered channel implementation based on Dmitry Vyukov's bounded MPMC
	 * queue:
	 *
	 * [[http://www.1024cores.net/home/lock-free-algorithms/queues/bounded-mpmc-queue]]
	 */
	internal class BufferedChannel<G> : Object, ChannelBase, Sender<G>,
			Gee.Traversable<G>, Receiver<G>, Channel<G> {
		private Queue<G> _queue;
		private AtomicBoolVal _closed;

		public BufferedChannel (int proposed_capacity)
			requires (proposed_capacity > 0)
		{
			if (proposed_capacity > int64.MAX) error("Capacity exceeds limit");
			int capacity = find_pot(proposed_capacity);
			if (capacity < 0) error("Capacity exceeds limit");
			_queue = new Queue<G>(capacity);
			_closed = new AtomicBoolVal();
		}

		private int find_pot (int64 n) {
			--n;
			n |= n >> 1;
			n |= n >> 2;
			n |= n >> 4;
			n |= n >> 8;
			n |= n >> 16;
			n |= n >> 32;
			return (n > int.MAX - 1) ? -1 : ((int)n)+1;
		}

		public Optional<int64?> capacity {
			owned get {
				return new Optional<int64?>.of(_queue.capacity);
			}
		}

		public int64 length {
			get {
				return _queue.length;
			}
		}

		public void close () {
			if ( _closed.compare_and_exchange(false, true) ) {
				// nothing
			}
		}

		private void sleep () {
			Thread.usleep(1);
		}

		public Result<void*> send (owned G data) {
			while (true) {
				if (_closed.val) {
					return Result.err<void*>(new ChannelError.CLOSED("Channel closed"));
				}
				bool succeeded = _queue.offer(data); // not '(owned)'
				if (succeeded) {
					return Result.of<void*>(null);
				}
				sleep();
			}
		}

		public Result<void*> send_until (owned G data, int64 end_time) {
			while (true) {
				if (_closed.val) {
					return Result.err<void*>(new ChannelError.CLOSED("Channel closed"));
				}
				bool succeeded = _queue.offer(data); // not '(owned)'
				if (succeeded) {
					return Result.of<void*>(null);
				}
				if (get_monotonic_time() > end_time) {
					return Result.err<G>(new ChannelError.TIMEOUT("Sending data timeout"));
				}
				sleep();
			}
		}

		public Result<void*> try_send (owned G data) {
			if (_closed.val) {
				return Result.err<void*>(new ChannelError.CLOSED("Channel closed"));
			}
			bool succeeded = _queue.offer(data); // not '(owned)'
			if (succeeded) {
				return Result.of<void*>(null);
			} else {
				return Result.err<void*>(new ChannelError.TRY_FAILED("Channel is full"));
			}
		}

		public Result<G> recv () {
			while (true) {
				Optional<G> item = _queue.poll();
				if (item.is_present) {
					return Result.of<G>(item.value);
				} else if (_closed.val) {
					return Result.err<G>(new ChannelError.CLOSED("Channel closed and no more data"));
				}
				sleep();
			}
		}

		public Result<G> recv_until (int64 end_time) {
			while (true) {
				Optional<G> item = _queue.poll();
				if (item.is_present) {
					return Result.of<G>(item.value);
				} else if (_closed.val) {
					return Result.err<G>(new ChannelError.CLOSED("Channel closed and no more data"));
				}
				if (get_monotonic_time() > end_time) {
					return Result.err<G>(new ChannelError.TIMEOUT("Receiving data timeout"));
				}
				sleep();
			}
		}

		public Result<G> try_recv () {
			Optional<G> item = _queue.poll();
			if (item.is_present) {
				return Result.of<G>(item.value);
			} else if (_closed.val) {
				return Result.err<G>(new ChannelError.CLOSED("Channel closed and no more data"));
			} else {
				return Result.err<G>(new ChannelError.TRY_FAILED("Channel is empty"));
			}
		}

		public bool @foreach (Gee.ForallFunc<G> f) {
			while (true) {
				Result<G> result = recv();
				if (result.exception != null) {
					return true;
				} else if ( !f(result.value) ) {
					return false;
				}
			}
		}

		private class Queue<G> {
			private CacheLinePad _pad0;
			private Cell<G>[] _buffer;
			private CacheLinePad _pad1;
			private uint _enq;
			private CacheLinePad _pad2;
			private uint _deq;
			private CacheLinePad _pad3;

			public Queue (int capacity) {
				assert(capacity >= 2);
				assert((capacity & (capacity - 1)) == 0); // power of 2
				_buffer = new Cell<G>[capacity];
				for (int i = 0; i < capacity; ++i) {
					atomic_uint_set(ref _buffer[i].sequence, i);
				}
				_suppress_warnings();
			}

			~Queue () {
				for (uint i = 0; i < _buffer.length; ++i) {
					_buffer[i].data = null;
				}
			}

			private void _suppress_warnings () {
				_pad0 = _pad1 = _pad2 = _pad3;
			}

			public int capacity {
				get {
					return _buffer.length;
				}
			}

			public uint length {
				get {
					uint mask = buffer_mask();
					while (true) {
						uint enq = atomic_uint_get(ref _enq);
						uint deq = atomic_uint_get(ref _deq);
						if (atomic_uint_get(ref _enq) == enq) {
							uint enq_idx = enq & mask;
							uint deq_idx = deq & mask;
							if (enq_idx > deq_idx) {
								return enq_idx - deq_idx;
							} else if (enq_idx < deq_idx) {
								return enq_idx + (_buffer.length - deq_idx);
							} else if ( (enq / _buffer.length) == (deq / _buffer.length) ) {
								return 0;
							} else {
								return _buffer.length;
							}
						}
					}
				}
			}

			public bool offer (owned G data) {
				Cell* cell;
				uint pos = atomic_uint_get(ref _enq);
				while (true) {
					cell = &_buffer[pos & buffer_mask()];
					uint seq = atomic_uint_get(ref cell->sequence);
					if (seq == pos) {
						if ( atomic_uint_compare_and_exchange(ref _enq, pos, pos+1) ) {
							break;
						}
					} else if (seq < pos) {
						return false;
					} else {
						pos = atomic_uint_get(ref _enq);
					}
				}
				cell->data = (owned) data;
				atomic_uint_set(ref cell->sequence, pos+1);
				return true;
			}

			public Optional<G> poll () {
				Cell* cell;
				uint pos = atomic_uint_get(ref _deq);
				uint mask = buffer_mask();
				while (true) {
					cell = &_buffer[pos & mask];
					uint seq = atomic_uint_get(ref cell->sequence);
					if (seq == pos+1) {
						if ( atomic_uint_compare_and_exchange(ref _deq, pos, pos+1) ) {
							break;
						}
					} else if (seq < pos+1) {
						return new Optional<G>.empty();
					} else {
						pos = atomic_uint_get(ref _deq);
					}
				}
				G data = (owned) cell->data;
				atomic_uint_set(ref cell->sequence, pos + mask + 1);
				return new Optional<G>.of((owned) data);
			}

			private inline uint buffer_mask () {
				return _buffer.length - 1;
			}

			private struct Cell<G> {
				public uint sequence;
				public G? data;
			}
		}
	}
}
