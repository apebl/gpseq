/* Receiver.vala
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
	 * The receiver side of a channel.
	 *
	 * @see Channel
	 * @see Sender
	 */
	[Version (since="0.3.0")]
	public interface Receiver<G> : ChannelBase, Gee.Traversable<G> {
		/**
		 * Receives a value from the channel. This method blocks the thread
		 * until a value is received or the channel is closed and has no more
		 * data.
		 *
		 * If the channel is empty, not unbuffered, and not closed, blocks
		 * until there is a value in the channel.
		 *
		 * If the channel is unbuffered, waits for a send operation.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed and no more data.
		 *
		 * @return the result which hold a value if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<G> recv ();

		/**
		 * Receives a value from the channel. This method blocks the thread
		 * until a value is received, the channel is closed and has no more
		 * data, or //end_time// has passed.
		 *
		 * This method is the same as {@link recv} except there is a timeout.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed and no more data.
		 *
		 *  * ChannelError.TIMEOUT
		 *
		 * If //end_time// has passed.
		 *
		 * @param end_time the monotonic time to wait until
		 * @return the result which hold a value if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<G> recv_until (int64 end_time);

		/**
		 * Attempts to receive a value from the channel. This method doesn't
		 * block the thread and returns immediately, regardless of success.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed and no more data.
		 *
		 *  * ChannelError.TRY_FAILED
		 *
		 * If the channel is empty (bufferd or unbounded channel), or there are
		 * no send operations waiting for receive operations (unbuffered
		 * channel).
		 *
		 * @return the result which hold a value if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<G> try_recv ();
	}
}
