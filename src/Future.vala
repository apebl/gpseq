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
	 * Futures are thread-safe.
	 *
	 * @see Promise
	 */
	public abstract class Future<G> : Object, Gee.Hashable<Result<G>>, Result<G> {
		/**
		 * Creates a future completed with the given value.
		 *
		 * @return the future completed with the given value
		 */
		public static Future<G> of<G> (owned G value) {
			var promise = new Promise<G>();
			promise.set_value((owned) value);
			return promise.future;
		}

		/**
		 * Creates a future completed with the given exception.
		 *
		 * @param exception an error
		 * @return the future completed with the given exception
		 */
		[Version (since="0.2.0-beta")]
		public static Future<G> err<G> (owned Error exception) {
			var promise = new Promise<G>();
			promise.set_exception((owned) exception);
			return promise.future;
		}

		/**
		 * Creates a future completed with the given result.
		 *
		 * @param result a result
		 * @return the future
		 */
		[Version (since="0.3.0")]
		public static Future<G> done<G> (Result<G> result) {
			if (result.exception == null) {
				return of<G>(result.value);
			} else {
				return err<G>(result.exception);
			}
		}

		/**
		 * Whether or not the future had already been completed with a value or
		 * an exception.
		 */
		public abstract bool ready { get; }

		[Version (since="0.3.0")]
		public Future<G> future () {
			return this;
		}

		/**
		 * Waits until the future is completed and gets ths result.
		 *
		 * It is an alias for {@link wait}.
		 *
		 * @return the value associated with the future if the future is
		 * completed with a value
		 *
		 * @throws Error if the future is completed with an exception, the
		 * exception will be thrown
		 */
		[Version (since="0.3.0")]
		public new unowned G get () throws Error {
			return wait();
		}

		/**
		 * Waits until the future is completed and gets ths result.
		 *
		 * @return the value associated with the future if the future is
		 * completed with a value
		 *
		 * @throws Error if the future is completed with an exception, the
		 * exception will be thrown
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
		 * exception will be thrown
		 */
		public abstract bool wait_until (int64 end_time, out unowned G? value = null) throws Error;

		/**
		 * Creates a new future by applying the given function to this future,
		 * in future -- when this future is completed.
		 *
		 * The returned object of the function may or may not be directly used.
		 * Depending on the internal implementation, A new future object will
		 * be created with the value or exception of it and returned, instead
		 * of returning it directly.
		 *
		 * If the function returns not a Future but a Result, the result is
		 * mapped to a future.
		 *
		 * @param func a function applied to this result
		 * @return [Future<A>] the new future
		 */
		public abstract Result<A> transform<A> (owned Result.TransformFunc<A,G> func);

		/**
		 * Maps the value to another future by applying the given function to
		 * the value, in future.
		 *
		 * If this future is completed with an exception, the result future is
		 * completed with the exception.
		 *
		 * The returned object of the function may or may not be directly used.
		 * Depending on the internal implementation, A new future object will
		 * be created with the value or exception of it and returned, instead
		 * of returning it directly.
		 *
		 * @param func a function applied to value
		 * @return [Future<A>] the new future
		 */
		public Result<A> flat_map<A> (owned Result.FlatMapFunc<A,G> func) {
			return transform<A>(future => {
				try {
					return func( ((Future<G>)future).wait() );
				} catch (Error err) {
					var promise = new Promise<A>();
					promise.set_exception((owned) err);
					return promise.future;
				}
			});
		}

		/**
		 * Maps the value to another value by applying the given function to
		 * the value, in future.
		 *
		 * If this future is completed with or the function throws an exception,
		 * the result future is completed with the exception.
		 *
		 * @param func a function applied to value
		 * @return [Future<A>] the mapped future
		 */
		public Result<A> map<A> (owned Result.MapFunc<A,G> func) {
			return transform<A>(future => {
				var promise = new Promise<A>();
				try {
					A newval = func( ((Future<G>)future).wait() );
					promise.set_value((owned) newval);
				} catch (Error err) {
					promise.set_exception((owned) err);
				}
				return promise.future;
			});
		}

		/**
		 * If this future is completed with an exception, maps the exception to
		 * another exception by applying the given function to the exception in
		 * future, otherwise the result future just uses the value of this
		 * future.
		 *
		 * @param func a function applied to exception
		 * @return [Future<G>] the mapped future
		 */
		[Version (since="0.2.0-beta")]
		public Result<G> map_err (owned Result.MapErrorFunc func) {
			return transform<G>(future => {
				var promise = new Promise<G>();
				try {
					G newval = ((Future<G>)future).wait();
					promise.set_value((owned) newval);
				} catch (Error err) {
					Error newerr = func((owned) err);
					promise.set_exception((owned) newerr);
				}
				return promise.future;
			});
		}

		/**
		 * Combines the values of two results using the given function.
		 *
		 * If two results hold or the function throws an exception, the
		 * returned future holds the exception.
		 *
		 * @param zip_func a function applied to values
		 * @param second another result
		 * @return [Future<B>] the combined future
		 */
		public Result<B> zip<A,B> (owned Result.ZipFunc<G,A,B> zip_func, Result<A> second) {
			return transform<B>(future => {
				return second.transform<B>(future2 => {
					var promise = new Promise<B>();
					try {
						B newval = zip_func( ((Future<G>)future).wait(), ((Future<A>)future2).wait() );
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
		 * @return [Future<G>] the future
		 */
		public Result<G> then (owned GLib.Func<Result<G>> func) {
			return transform<G>(future => {
				func(future);
				return future;
			});
		}

		/**
		 * Runs the function with the value in future -- when this future is
		 * completed with a value.
		 *
		 * If this future is completed with or the function throws an exception,
		 * the result future is completed with the exception.
		 *
		 * @param func a function called in future
		 * @return [Future<G>] the future
		 */
		public Result<G> and_then (owned Func<G> func) {
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

		[Version (since="0.3.0")]
		public bool equal_to (Result<G> object) {
			var exp = exception;
			var objexp = object.exception;
			if (exp == null && objexp == null) {
				Gee.EqualDataFunc func = Gee.Functions.get_equal_func_for(typeof(G));
				return func(value, object.value);
			} else if (exp != null && objexp != null) {
				return exp.domain == objexp.domain
					&& exp.code == objexp.code;
			} else {
				return false;
			}
		}

		[Version (since="0.3.0")]
		public uint hash () {
			var exp = exception;
			Gee.HashDataFunc func = Gee.Functions.get_hash_func_for(typeof(G));
			uint result = 1;
			result = 31*result + func(value);
			result = 31*result + exp.code;
			result = 31*result + exp.domain;
			return result;
		}
	}
}
