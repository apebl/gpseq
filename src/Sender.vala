/* Sender.vala
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
	 * The sender side of a channel.
	 *
	 * @see Channel
	 * @see Receiver
	 */
	[Version (since="0.3.0-alpha")]
	public interface Sender<G> : ChannelBase {
		/**
		 * Sends a value into the channel. This method blocks the thread until
		 * the value is sent or the channel is closed.
		 *
		 * If the channel is full, not unbuffered, and not closed, blocks until
		 * the channel has a space to hold the value.
		 *
		 * If the channel is unbuffered, waits for a receive operation.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed.
		 *
		 * @param data a value
		 * @return the result which hold null if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<void*> send (owned G data);

		/**
		 * Sends a value into the channel. This method blocks the thread until
		 * the value is sent, the channel is closed, or //end_time// has passed.
		 *
		 * This method is the same as {@link send} except there is a timeout.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed.
		 *
		 *  * ChannelError.TIMEOUT
		 *
		 * If //end_time// has passed.
		 *
		 * @param data a value
		 * @param end_time the monotonic time to wait until
		 * @return the result which hold null if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<void*> send_until (owned G data, int64 end_time);

		/**
		 * Attempts to send a value into the channel. This method doesn't block
		 * the thread and returns immediately, regardless of success.
		 *
		 * Errors:
		 *
		 *  * ChannelError.CLOSED
		 *
		 * If the channel has been closed.
		 *
		 *  * ChannelError.TRY_FAILED
		 *
		 * If the channel is full (bufferd channel), or there are no receive
		 * operations waiting for send operations (unbuffered channel).
		 *
		 * @param data a value
		 * @return the result which hold null if succeeded, or an error if
		 * failed.
		 */
		public abstract Result<void*> try_send (owned G data);
	}
}
