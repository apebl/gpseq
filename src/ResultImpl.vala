/* ResultImpl.vala
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
	internal class ResultImpl<G> : Object, Gee.Hashable<Result<G>>, Result<G> {
		private G? _value;
		private Error? _exception;

		public ResultImpl.of (owned G value) {
			_value = (owned) value;
		}

		public ResultImpl.err (owned Error exception) {
			_exception = (owned) exception;
		}

		public new unowned G get () throws Error {
			if (_exception == null) {
				return _value;
			} else {
				throw _exception;
			}
		}

		public Result<A> transform<A> (owned Result.TransformFunc<A,G> func) {
			return func(this);
		}

		public bool equal_to (Result<G> object) {
			var objexp = object.exception;
			if (_exception == null && objexp == null) {
				Gee.EqualDataFunc func = Gee.Functions.get_equal_func_for(typeof(G));
				return func(_value, object.value);
			} else if (_exception != null && objexp != null) {
				return _exception.domain == objexp.domain
					&& _exception.code == objexp.code;
			} else {
				return false;
			}
		}

		public uint hash () {
			Gee.HashDataFunc func = Gee.Functions.get_hash_func_for(typeof(G));
			uint result = 1;
			result = 31*result + func(_value);
			result = 31*result + _exception.code;
			result = 31*result + _exception.domain;
			return result;
		}
	}
}
