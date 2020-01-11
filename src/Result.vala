/* Result.vala
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
	 * A result object that holds a value or an error.
	 *
	 * @see Future
	 * @see Optional
	 */
	[Version (since="0.3.0")]
	[GenericAccessors]
	public interface Result<G> : Gee.Hashable<Result<G>> {
		public delegate Result<A> TransformFunc<A,G> (Result<G> result);
		public delegate Result<A> FlatMapFunc<A,G> (G value);
		public delegate A MapFunc<A,G> (G value) throws Error;
		public delegate Error MapErrorFunc (owned Error err);
		public delegate unowned A LightMapFunc<A,G> (G value) throws Error;
		public delegate C ZipFunc<A,B,C> (A a, B b) throws Error;

		/**
		 * Creates a result holds the given value.
		 *
		 * @return the result
		 */
		public static Result<G> of<G> (owned G value) {
			return new ResultImpl<G>.of((owned) value);
		}

		/**
		 * Creates a result holds the given error.
		 *
		 * @param exception an error
		 * @return the result
		 */
		public static Result<G> err<G> (owned Error exception) {
			return new ResultImpl<G>.err((owned) exception);
		}

		public Type value_type {
			get {
				return typeof(G);
			}
		}

		/**
		 * The value of this result.
		 *
		 * If the result is a failed result, the getting value fails with
		 * {@link GLib.error}.
		 *
		 * ''{@link Future} implementation:'' If value is not ready, getting
		 * value will block until value is ready.
		 */
		public G value {
			get {
				try {
					return get();
				} catch (Error err) {
					error("%s", err.message);
				}
			}
		}

		/**
		 * The error of this result, or null if the result is a succeeded
		 * result.
		 *
		 * ''{@link Future} implementation:'' If the future is not yet
		 * completed, getting exception will block until the future is
		 * completed.
		 */
		public Error? exception {
			owned get {
				try {
					get();
					return null;
				} catch (Error err) {
					return err;
				}
			}
		}

		/**
		 * Whether or not this result holds an error.
		 */
		public bool is_err {
			get {
				return exception != null;
			}
		}

		/**
		 * Returns a {@link Future} version of this result.
		 *
		 * ''{@link Result} implementation:'' Creates a future completed with
		 * this result.
		 *
		 * ''{@link Future} implementation:'' Returns this.
		 *
		 * @return the future
		 */
		public virtual Future<G> future () {
			return Future<G>.done(this);
		}

		/**
		 * Gets the value or throws the exception.
		 *
		 * ''{@link Future} implementation:'' Waits until the future is
		 * completed. It is an alias for {@link Future.wait}.
		 *
		 * @return the value if this result holds a value
		 *
		 * @throws Error if this result holds an exception, the exception will
		 * be thrown
		 */
		public abstract unowned G get () throws Error;

		/**
		 * Creates a new result by applying the given function to this result.
		 *
		 * The returned object of the function may or may not be directly used.
		 * Depending on the internal implementation, A new result object will
		 * be created with the value or exception of it and returned, instead
		 * of returning it directly.
		 *
		 * ''{@link Future} implementation:'' Creates a new future by applying
		 * the given function to this future, ''in future'' -- when this future
		 * is completed.
		 *
		 * ''{@link Future} implementation:'' If the function returns not a
		 * Future but a Result, the result is mapped to a future.
		 *
		 * @param func a function applied to this result
		 * @return the new result (''{@link Future} implementation:''
		 * [Future<A>] the new future)
		 */
		public abstract Result<A> transform<A> (owned TransformFunc<A,G> func);

		/**
		 * Maps the value to another result by applying the given function to
		 * the value.
		 *
		 * If this result holds an exception, the returned result holds the
		 * exception too.
		 *
		 * The returned object of the function may or may not be directly used.
		 * Depending on the internal implementation, A new result object will
		 * be created with the value or exception of it and returned, instead
		 * of returning it directly.
		 *
		 * @param func a function applied to value
		 * @return the new result
		 */
		public virtual Result<A> flat_map<A> (owned FlatMapFunc<A,G> func) {
			return transform<A>(result => {
				if (result.exception == null) {
					return func(result.value);
				} else {
					return err<A>(result.exception);
				}
			});
		}

		/**
		 * Maps the value to another value by applying the given function to
		 * the value.
		 *
		 * If this result holds or the function throws an exception, the
		 * returned result holds the exception.
		 *
		 * @param func a function applied to value
		 * @return the mapped result
		 */
		public virtual Result<A> map<A> (owned MapFunc<A,G> func) {
			return transform<A>(result => {
				if (result.exception == null) {
					try {
						return of<A>( func(result.value) );
					} catch (Error error) {
						return err<A>((owned) error);
					}
				} else {
					return err<A>(result.exception);
				}
			});
		}

		/**
		 * If this result holds an exception, maps the exception to another
		 * exception by applying the given function to the exception, otherwise
		 * the returned result holds the value of this result.
		 *
		 * @param func a function applied to exception
		 * @return the mapped result
		 */
		public virtual Result<G> map_err (owned MapErrorFunc func) {
			return transform<G>(result => {
				if (result.exception == null) {
					return result;
				} else {
					return err<G>( func(result.exception) );
				}
			});
		}

		/**
		 * Combines the values of two results using the given function.
		 *
		 * If two results hold or the function throws an exception, the
		 * returned result holds the exception.
		 *
		 * @param zip_func a function applied to values
		 * @param second another result
		 * @return the combined result
		 */
		public virtual Result<B> zip<A,B> (owned ZipFunc<G,A,B> zip_func, Result<A> second) {
			return transform<B>(result => {
				if (result.exception != null) {
					return err<B>(result.exception);
				} else if (second.exception != null) {
					return err<B>(second.exception);
				} else {
					try {
						return of<B>( zip_func(result.value, second.value) );
					} catch (Error error) {
						return err<B>((owned) error);
					}
				}
			});
		}

		/**
		 * Runs the function with this result.
		 *
		 * @param func a function called
		 * @return the result
		 */
		public virtual Result<G> then (owned GLib.Func<Result<G>> func) {
			return transform<G>(result => {
				func(result);
				return result;
			});
		}

		/**
		 * Runs the function with the value if this result holds a value.
		 *
		 * If this result holds or the function throws an exception, the
		 * returned result holds the exception.
		 *
		 * @param func a function called
		 * @return the result
		 */
		public virtual Result<G> and_then (owned Func<G> func) {
			return transform<G>(result => {
				if (result.exception == null) {
					try {
						func(result.value);
					} catch (Error error) {
						return err<G>((owned) error);
					}
				}
				return result;
			});
		}
	}
}
