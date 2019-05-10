/* Container.vala
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
	 * An object that contains elements, of which seq pipelines consist.
	 *
	 * Implementation note. {@link Spliterator.try_advance},
	 * {@link Spliterator.each}, and {@link Spliterator.each_chunk}:
	 *
	 * If a container has a parent, given consumer function to the methods could
	 * be ignored on some elements depending on underlying implementation.
	 * Otherwise, the container must not ignore any elements for the consumer
	 * function.
	 *
	 * If some elements could be ignored, {@link Spliterator.is_size_known} must
	 * be false. If it is guaranteed that the container doesn't ignore any
	 * elements, is_size_known could be true even though the container has a
	 * parent.
	 */
	internal interface Container<G,P> : Spliterator<G> {
		/**
		 * The parent of this container.
		 */
		public abstract Container<P,void*>? parent { get; }

		/**
		 * Will be called once before traversal of the input is started.
		 *
		 * All methods overriding this method must call the parent's start()
		 * before their implementation if the container has a parent.
		 */
		public abstract void start (Seq seq);
	}
}
