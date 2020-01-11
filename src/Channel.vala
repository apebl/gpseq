/* Channel.vala
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
	 * Multi-producer multi-consumer channels. Channels are the pipes that
	 * provide communication between threads.
	 *
	 * @see Sender
	 * @see Receiver
	 */
	[Version (since="0.3.0")]
	public interface Channel<G> : Sender<G>, Receiver<G> {
		/**
		 * Creates a bounded channel.
		 *
		 * If //proposed_capacity// == 0, returns an unbuffered channel of
		 * which capacity is zero. It is a symmetric rendezvous queue and has
		 * no buffer to hold data, but its send and receive operations are done
		 * symmetrically, i.e., wait for one another.
		 *
		 * If //proposed_capacity// > 0, returns a buffered channel of which
		 * capacity is ''at least'' //proposed_capacity//, i.e, the actual
		 * capacity could be greater than //proposed_capacity//. It can hold
		 * data up to the capacity.
		 *
		 * @param proposed_capacity a proposed capacity.
		 * @return a bounded channel
		 */
		public static Channel<G> bounded<G> (int proposed_capacity)
			requires (proposed_capacity >= 0)
		{
			if (proposed_capacity == 0) {
				return new UnbufferedChannel<G>();
			} else {
				return new BufferedChannel<G>(proposed_capacity);
			}
		}

		/**
		 * Creates an unbounded channel that has no capacity limit. It can hold
		 * any number of data.
		 *
		 * @return an unbounded channel
		 */
		public static Channel<G> unbounded<G> () {
			return new UnboundedChannel<G>();
		}
	}
}
