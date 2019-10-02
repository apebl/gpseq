/* Promise.vala
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
	 * A promise allows to set a value or an exception with an associated
	 * future.
	 *
	 * @see Future
	 */
	public class Promise<G> {
		private Future<G> _future;

		public Promise () {
			_future = new Future<G>();
		}

		/**
		 * The future of this promise.
		 */
		public Gpseq.Future<G> future {
			get {
				return _future;
			}
		}

		/**
		 * Sets the value to the associated future.
		 *
		 * @param value a value
		 */
		public void set_value (owned G value) {
			_future.set_value((owned) value);
		}

		/**
		 * Sets the exception to the associated future.
		 *
		 * @param exception an exception
		 */
		public void set_exception (owned Error exception) {
			_future.set_exception((owned) exception);
		}

		private class Future<G> : Object, Gpseq.Future<G> {
			private Mutex _mutex;
			private Cond _cond;
			private State _state;
			private G? _value;
			private Error? _exception;
			private CallbackFuncObject[]? _callbacks;

			public Future () {
				_mutex = Mutex();
				_cond = Cond();
				_state = State.INIT;
				_callbacks = new CallbackFuncObject[0];
			}

			public bool ready {
				get {
					_mutex.lock();
					bool result = _state != State.INIT;
					_mutex.unlock();
					return result;
				}
			}

			public Error? exception {
				get {
					return _exception;
				}
			}

			public unowned G wait () throws Error {
				_mutex.lock();
				switch (_state) {
				case State.READY:
					unowned G result = _value;
					_mutex.unlock();
					return result;
				case State.EXCEPTION:
					unowned Error result = _exception;
					_mutex.unlock();
					throw result;
				case State.INIT:
					while (_state == State.INIT) {
						_cond.wait(_mutex);
					}
					_mutex.unlock();
					return wait();
				default:
					assert_not_reached();
				}
			}

			public bool wait_until (int64 end_time, out unowned G? value = null) throws Error {
				_mutex.lock();
				switch (_state) {
				case State.READY:
					value = _value;
					_mutex.unlock();
					return true;
				case State.EXCEPTION:
					value = null;
					unowned Error result = _exception;
					_mutex.unlock();
					throw result;
				case State.INIT:
					while (_state == State.INIT) {
						if ( !_cond.wait_until(_mutex, end_time) ) {
							value = null;
							_mutex.unlock();
							return false;
						}
					}
					_mutex.unlock();
					return wait_until(end_time, out value);
				default:
					assert_not_reached();
				}
			}

			public Gpseq.Future<A> transform<A> (owned Gpseq.Future.TransformFunc<A,G> func) {
				_mutex.lock();
				switch (_state) {
				case State.READY:
				case State.EXCEPTION:
					_mutex.unlock();
					Gpseq.Future<A> result = func(this);
					return result;
				case State.INIT:
					var promise = new Promise<A>();
					_callbacks += CallbackFuncObject(() => {
						Gpseq.Future<A> result = func(this);
						result.then(future => {
							try {
								promise.set_value( result.wait() );
							} catch (Error err) {
								promise.set_exception((owned) err);
							}
						});
					});
					_mutex.unlock();
					return promise.future;
				default:
					assert_not_reached();
				}
			}

			public void set_value (owned G value) {
				_mutex.lock();
				assert(_state == State.INIT);
				_state = State.READY;
				_value = (owned) value;
				CallbackFuncObject[] callbacks = (owned) _callbacks;
				_cond.broadcast();
				_mutex.unlock();
				for (int i = 0; i < callbacks.length; i++) {
					callbacks[i].func();
				}
			}

			public void set_exception (owned Error exception) {
				_mutex.lock();
				assert(_state == State.INIT);
				_state = State.EXCEPTION;
				_exception = (owned) exception;
				CallbackFuncObject[] callbacks = (owned) _callbacks;
				_cond.broadcast();
				_mutex.unlock();
				for (int i = 0; i < callbacks.length; i++) {
					callbacks[i].func();
				}
			}

			private enum State {
				INIT,
				READY,
				EXCEPTION
			}

			private delegate void CallbackFunc ();

			private struct CallbackFuncObject {
				public CallbackFunc func;

				public CallbackFuncObject (owned CallbackFunc func) {
					this.func = (owned) func;
				}
			}
		}
	}
}
