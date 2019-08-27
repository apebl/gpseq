/* Future.vala
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
	 * A value which might not yet be available, but will be available at some
	 * point.
	 *
	 * Futures must be thread-safe.
	 *
	 * @see Promise
	 */
	[GenericAccessors]
	public interface Future<G> : Object {
		public delegate Future<A> TransformFunc<A,G> (Future<G> future);
		public delegate Future<A> FlatMapFunc<A,G> (G value);
		public delegate A MapFunc<A,G> (G value) throws Error;
		public delegate unowned A LightMapFunc<A,G> (G value) throws Error;
		public delegate C ZipFunc<A,B,C> (A a, B b) throws Error;

		public static Future<G> of<G> (owned G value) {
			var promise = new Promise<G>();
			promise.set_value((owned) value);
			return promise.future;
		}

		[Version (since="0.2.0-beta")]
		public static Future<G> err<G> (owned Error exception) {
			var promise = new Promise<G>();
			promise.set_exception((owned) exception);
			return promise.future;
		}

		/**
		 * Whether or not the future had already been completed with a value or
		 * an exception.
		 */
		public abstract bool ready { get; }

		/**
		 * The value of the future. If value is not ready, getting value will
		 * block until value is ready.
		 *
		 * If the future is completed with an exception, the getting value
		 * fails with {@link GLib.error}.
		 */
		public G value {
			get {
				try {
					return wait();
				} catch (Error err) {
					error("%s", err.message);
				}
			}
		}

		/**
		 * The exception of the future, or null if the future is not yet
		 * completed or successfully completed with a value.
		 */
		public abstract Error? exception { get; }

		/**
		 * Waits until the future is completed.
		 *
		 * @throws Error if the future is completed with an exception, the
		 * error will be thrown
		 */
		public abstract unowned G wait () throws Error;

		/**
		 * Waits until the future is completed or deadline have passed.
		 *
		 * @param end_time the monotonic time to wait until, in microseconds
		 * @param value the value associated with the future if the wait was
		 * successful
		 * @return true if the future was completed within deadline, or false
		 * otherwise
		 *
		 * @throws Error if the future is completed with an exception, the
		 * error will be thrown
		 */
		public abstract bool wait_until (int64 end_time, out unowned G? value = null) throws Error;

		/**
		 * Creates a new future by applying the given function to this future,
		 * in future -- when this future is completed.
		 *
		 * The result future object of the function may or may not be directly
		 * used. Depending on the internal implementation, A new future object
		 * will be created with the value or exception of the result future and
		 * returned, instead of returning the result future directly.
		 *
		 * @param func a function applied to this future
		 * @return the new future
		 */
		public abstract Future<A> transform<A> (owned TransformFunc<A,G> func);

		/**
		 * Maps a future value to another future by applying the given function
		 * to the value in future.
		 *
		 * If this future is completed with an exception, the result future is
		 * completed with the exception.
		 *
		 * The result future object of the function may or may not be directly
		 * used. Depending on the internal implementation, A new future object
		 * will be created with the value or exception of the result future and
		 * returned, instead of returning the result future directly.
		 *
		 * @param func a function applied to value
		 * @return the new future
		 */
		public Future<A> flat_map<A> (owned FlatMapFunc<A,G> func) {
			return transform<A>(future => {
				try {
					return func( future.wait() );
				} catch (Error err) {
					var promise = new Promise<A>();
					promise.set_exception((owned) err);
					return promise.future;
				}
			});
		}

		/**
		 * Maps a future value to another value by applying the given function
		 * to the value in future.
		 *
		 * If this future is completed with an exception or the function throws
		 * an exception, the result future is completed with the exception.
		 *
		 * @param func a function applied to value
		 * @return the mapped future
		 */
		public Future<A> map<A> (owned MapFunc<A,G> func) {
			return transform<A>(future => {
				var promise = new Promise<A>();
				try {
					A newval = func( future.wait() );
					promise.set_value((owned) newval);
				} catch (Error err) {
					promise.set_exception((owned) err);
				}
				return promise.future;
			});
		}

		/**
		 * Maps a future value to another value by applying the given function
		 * to the value in future.
		 *
		 * If this future is completed with an exception or the function throws
		 * an exception, the result future is completed with the exception.
		 *
		 * The function may be re-evaluated at any time.
		 *
		 * @param func a function applied to value
		 * @return the mapped future
		 */
		public Future<A> light_map<A> (owned LightMapFunc<A,G> func) {
			return new LightMapFuture<A,G>(this, (owned) func);
		}

		/**
		 * Combines values of two futures using the given function which
		 * returns the combined value in future.
		 *
		 * If this future is completed with an exception or the function throws
		 * an exception, the result future is completed with the exception.
		 *
		 * @param func a function applied to values
		 * @return the combined future
		 */
		public Future<B> zip<A,B> (owned ZipFunc<G,A,B> zip_func, Future<A> second) {
			return transform<B>(future => {
				return second.transform<B>(future2 => {
					var promise = new Promise<B>();
					try {
						B newval = zip_func( future.wait(), future2.wait() );
						promise.set_value((owned) newval);
					} catch (Error err) {
						promise.set_exception((owned) err);
					}
					return promise.future;
				});
			});
		}

		/**
		 * Runs the function with this future in future -- when this future is
		 * completed with a value or an exception.
		 *
		 * @param func a function called in future
		 * @return the future
		 */
		public Future<G> then (owned GLib.Func<Future<G>> func) {
			return transform<G>(future => {
				func(future);
				return future;
			});
		}

		/**
		 * Runs the function with the future value in future -- when this
		 * future is completed with a value.
		 *
		 * If this future is completed with an exception or the function throws
		 * an exception, the result future is completed with the exception.
		 *
		 * @param func a function called in future
		 * @return the future
		 */
		public Future<G> and_then (owned Func<G> func) {
			return transform<G>(future => {
				if (future.exception == null) {
					try {
						func(future.value);
						return future;
					} catch (Error err) {
						var promise = new Promise<G>();
						promise.set_exception((owned) err);
						return promise.future;
					}
				} else {
					return future;
				}
			});
		}
	}
}
