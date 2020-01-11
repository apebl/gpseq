/* ChannelBase.vala
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
	 * A base interface for senders and receivers.
	 */
	[Version (since="0.3.0")]
	public interface ChannelBase : Object {
		/**
		 * The capacity of the channel.
		 *
		 * If the channel is unbounded, the capacity is not present.
		 */
		public abstract Optional<int64?> capacity { owned get; }

		/**
		 * The current number of data in the channel.
		 *
		 * Unbuffered channels are always zero-length.
		 *
		 * If the channel is unbounded and contains more than {@link int64.MAX}
		 * elements, returns {@link int64.MAX}.
		 */
		public abstract int64 length { get; }

		/**
		 * Whether or not the channel is full.
		 *
		 * Unbuffered channels are always full.
		 */
		public virtual bool is_full {
			get {
				var cap = capacity;
				return cap.is_present && (!)cap.value == length;
			}
		}

		/**
		 * Whether or not the channel is empty.
		 *
		 * Unbuffered channels are always empty.
		 */
		public virtual bool is_empty {
			get {
				return length == 0;
			}
		}

		/**
		 * Closes the channel.
		 *
		 * If the channel has already been closed, this method does nothing.
		 *
		 * Channels are automatically closed when they are freed.
		 */
		public abstract void close ();
	}
}
