/* Consumer.vala
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
	 * An object that provides a wrapper function of a consumer function,
	 * which is used to traverse source input in seq pipelines.
	 */
	internal class Consumer<G> : Object {
		/**
		 * Returns a consumer function wrapping the given function
		 * @see is_identity_function
		 */
		public virtual Func<G> function (owned Func<G> f) {
			return (owned) f;
		}

		/**
		 * Whether or not {@link Consumer.function} is an identity function.
		 * if true, returned function of function() is identical with given
		 * argument.
		 */
		public virtual bool is_identity_function {
			get {
				return true;
			}
		}
	}
}
