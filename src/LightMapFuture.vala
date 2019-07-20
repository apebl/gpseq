/* LightMapFuture.vala
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
	internal class LightMapFuture<A,G> : Object, Future<A> {
		private Future<G> _base;
		private Future.LightMapFunc<A,G> _func;

		public LightMapFuture (
				Future<G> base_future, owned Future.LightMapFunc<A,G> func) {
			_base = base_future;
			_func = (owned) func;
		}

		public bool ready {
			get {
				return _base.ready;
			}
		}

		public Error? exception {
			get {
				return _base.exception;
			}
		}

		public unowned A wait () throws Error {
			return _func( _base.wait() );
		}

		public bool wait_until (int64 end_time, out unowned A? value = null) throws Error {
			unowned A arg;
			bool result = _base.wait_until(end_time, out arg);
			value = null;
			if (result) {
				value = _func(arg);
			}
			return result;
		}

		public Future<R> transform<R> (owned Future.TransformFunc<R,A> func) {
			return _base.transform<R>(future => {
				var promise = new Promise<A>();
				try {
					promise.set_value( _func(future.wait()) );
				} catch (Error err) {
					promise.set_exception((owned) err);
				}
				return func(promise.future);
			});
		}
	}
}
