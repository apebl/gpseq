/* UnboundedChannel.vala
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
	/**
	 * Unbounded channel implementation based on Michael and Scott's lock-free
	 * queue, but using hazard pointers instead of DCAS:
	 *
	 * [[https://www.cs.rochester.edu/~scott/papers/1996_PODC_queues.pdf]]
	 */
	internal class UnboundedChannel<G> : Object, ChannelBase, Sender<G>,
			Gee.Traversable<G>, Receiver<G>, Channel<G> {
		private Queue<G> _queue;
		private AtomicBoolVal _closed;

		public UnboundedChannel () {
			_queue = new Queue<G>();
			_closed = new AtomicBoolVal();
		}

		public Optional<int64?> capacity {
			owned get {
				return new Optional<int64?>.empty();
			}
		}

		public int64 length {
			get {
				return _queue.length;
			}
		}

		public bool is_empty {
			get {
				return _queue.is_empty;
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
			if (_closed.val) {
				return Result.err<void*>(new ChannelError.CLOSED("Channel closed"));
			}
			_queue.offer((owned) data);
			return Result.of<void*>(null);
		}

		public Result<void*> send_until (owned G data, int64 end_time) {
			return send((owned) data);
		}

		public Result<void*> try_send (owned G data) {
			return send((owned) data);
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

		private class Queue<G> : Object {
			private CacheLinePad _pad0;
			private Node<G>* _head;
			private CacheLinePad _pad1;
			private Node<G>* _tail;
			private CacheLinePad _pad2;

			public Queue () {
				_head = new Node<G>(null);
				_tail = _head;
				_suppress_warnings();
			}

			~Queue () {
				HazardPointer.Context ctx = new HazardPointer.Context();
				_suppress_unused(ctx);
				while (true) {
					HazardPointer<Node<G>*>? h = HazardPointer.get_hazard_pointer<Node<G>*>(&_head);
					if (h == null) break;
					Node<G>* next = h.get()->get_next();
					if (h.get() != get_head()) continue;
					while ( !cas_head(h.get(), next) );
					free_node(h);
				}
			}

			private void _suppress_warnings () {
				_pad0 = _pad1 = _pad2;
			}

			private void _suppress_unused (HazardPointer.Context ctx) {
			}

			/**
			 * Counts the number of the elements.
			 *
			 * If the queue contains more than {@link int64.MAX} elements,
			 * returns {@link int64.MAX}.
			 */
			public int64 length {
				get {
					HazardPointer.Context ctx = new HazardPointer.Context();
					_suppress_unused(ctx);
					while (true) {
						HazardPointer<Node<G>*> h = HazardPointer.get_hazard_pointer<Node<G>*>(&_head);
						Node<G>* t = get_tail();
						Node<G>* f = h.get()->get_next();
						if ( h.get() == get_head() ) {
							if (h.get() == t) {
								if (f == null) {
									return 0;
								} else {
									cas_tail(t, f);
								}
							} else {
								int64 len = 0;
								while (f != null) {
									if (++len == int64.MAX) {
										break;
									}
									f = f->get_next();
								}
								return len;
							}
						}
					}
				}
			}

			public bool is_empty {
				get {
					return first == null;
				}
			}

			private Node<G>* first {
				get {
					HazardPointer.Context ctx = new HazardPointer.Context();
					_suppress_unused(ctx);
					while (true) {
						HazardPointer<Node<G>*> h = HazardPointer.get_hazard_pointer<Node<G>*>(&_head);
						Node<G>* t = get_tail();
						Node<G>* f = h.get()->get_next();
						if ( h.get() == get_head() ) {
							if (h.get() == t) {
								if (f == null) {
									return null;
								} else {
									cas_tail(t, f);
								}
							} else {
								return f;
							}
						}
					}
				}
			}

			public void offer (owned G value) {
				HazardPointer.Context ctx = new HazardPointer.Context();
				_suppress_unused(ctx);
				Node<G>* node = new Node<G>((owned) value);
				while (true) {
					HazardPointer<Node<G>*> t = HazardPointer.get_hazard_pointer<Node<G>*>(&_tail);
					Node<G>* next = t.get()->get_next();
					if ( t.get() == get_tail() ) {
						if (next == null) {
							if ( t.get()->cas_next(next, node) ) {
								cas_tail(t.get(), node);
								return;
							}
						} else {
							cas_tail(t.get(), next);
						}
					}
				}
			}

			public Optional<G> poll () {
				HazardPointer.Context ctx = new HazardPointer.Context();
				_suppress_unused(ctx);
				while (true) {
					HazardPointer<Node<G>*> h = HazardPointer.get_hazard_pointer<Node<G>*>(&_head);
					Node<G>* t = get_tail();
					Node<G>* next = h.get()->get_next();
					if ( h.get() == get_head() ) {
						if (h.get() == t) {
							if (next == null) {
								return new Optional<G>.empty();
							}
							cas_tail(t, next);
						} else if ( cas_head(h.get(), next) ) {
							G? val = (owned) next->value;
							free_node(h);
							return new Optional<G>.of((owned) val);
						}
					}
				}
			}

			private void free_node (HazardPointer<Node<G>*> hp) {
				hp.release(ptr => {
					Node<G>* p = (Node<G>*) ptr;
					delete p;
				});
			}

			private Node<G>* get_tail () { // non-null
				return (Node<G>*) AtomicPointer.get(&_tail);
			}

			private Node<G>* get_head () { // non-null
				return (Node<G>*) AtomicPointer.get(&_head);
			}

			private bool cas_head (Node<G>* oldval, Node<G>* newval) { // non-null
				return AtomicPointer.compare_and_exchange(&_head, oldval, newval);
			}

			private bool cas_tail (Node<G>* oldval, Node<G>* newval) { // non-null
				return AtomicPointer.compare_and_exchange(&_tail, oldval, newval);
			}
		}

		[Compact]
		private class Node<G> {
			public G? value;
			public Node<G>* next;

			public Node (owned G? value) {
				this.value = value;
			}

			~Node () {
				value = null;
			}

			public Node<G>* get_next () { // nullable
				return (Node<G>*) AtomicPointer.get(&next);
			}

			public bool cas_next (Node<G>* oldval, Node<G>* newval) { // nullable
				return AtomicPointer.compare_and_exchange(&next, oldval, newval);
			}
		}
	}
}
