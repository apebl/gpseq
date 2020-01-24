/* Optional.vala
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

using Gee;

namespace Gpseq {
	/**
	 * A container object which may or may not contain a value.
	 */
	public class Optional<G> : Object {
		private G? _value;
		private bool _is_present;

		/**
		 * Creates an empty optional instance.
		 */
		public Optional.empty () {}

		/**
		 * Creates an optional instance with the given value present.
		 *
		 * @param value the value to be present, which can be null if nullable
		 * type
		 */
		public Optional.of (owned G value) {
			_value = (owned) value;
			_is_present = true;
		}

		/**
		 * The type of the value.
		 */
		public Type value_type {
			get {
				return typeof(G);
			}
		}

		/**
		 * The value held by this optional.
		 *
		 * If a value is present in this optional, returns the value, otherwise
		 * (assertion) fails.
		 */
		public G value {
			get {
				assert(_is_present);
				return _value;
			}
		}

		/**
		 * Whether or not there is a value present.
		 */
		public bool is_present {
			get {
				return _is_present;
			}
		}

		public string to_string () {
			if (_is_present) {
				return "Optional[%p]".printf(_value);
			} else {
				return "Optional.empty";
			}
		}

		/**
		 * If a value is present, performs the given consumer function with the
		 * value.
		 *
		 * @param consumer a function that will be executed if a value is
		 * present
		 */
		public void if_present (GLib.Func<G> consumer) {
			if (_is_present) {
				consumer(_value);
			}
		}

		/**
		 * If a value is present, returns the value, otherwise returns the given
		 * other.
		 *
		 * @param other other value that will be returned if no value is present
		 * @return the value if present, otherwise the given other.
		 */
		public G or_else (G other) {
			return _is_present ? _value : other;
		}

		/**
		 * If a value is present, returns the value, otherwise returns the
		 * result produced by the supply function.
		 *
		 * @param supplier the supply function
		 * @return the value if present, otherwise the result produced by the
		 * supply function
		 */
		public G or_else_get (SupplyFunc<G> supplier) {
			return _is_present ? _value : supplier();
		}

		/**
		 * If a value is present, returns the value, otherwise throws an error
		 * produced by the supply function -- or an
		 * {@link OptionalError.NOT_PRESENT} error if the function is not
		 * specified.
		 *
		 * @param error_supplier the supply function
		 * @return the value if present
		 *
		 * @throws Error an error produced by the supply function if no value
		 * is present
		 */
		public G or_else_throw (SupplyFunc<Error>? error_supplier = null) throws Error {
			if (_is_present) {
				return _value;
			} else {
				throw error_supplier != null
					? error_supplier()
					: new OptionalError.NOT_PRESENT("No value present");
			}
		}

		/**
		 * If a value is present, returns the value, otherwise fails with
		 * {@link GLib.error}.
		 *
		 * @return the value if present
		 */
		public G or_else_fail () {
			if (_is_present) {
				return _value;
			} else {
				error("Optional: No value present");
			}
		}

		/**
		 * If a value is present and matches the given predicate, returns an
		 * optional containing the value, otherwise returns an empty optional.
		 *
		 * @return an optional containing the value if a value is present,
		 * otherwise an empty optional
		 */
		public Optional<G> filter (Gee.Predicate<G> pred) {
			if (_is_present) {
				return pred(_value) ? this : new Optional<G>.empty();
			} else {
				return this;
			}
		}

		/**
		 * If a value is present, performs the mapper function with the value,
		 * and returns the result. Otherwise returns an empty optional.
		 *
		 * The given mapper function must not return null.
		 *
		 * @param mapper a mapper function that will be performed with the value
		 * if a value is present
		 * @return the result of the mapper function if a value is present,
		 * otherwise an empty optional
		 */
		public Optional<A> map<A> (Gee.MapFunc<Optional<A>,G> mapper) {
			if (_is_present) {
				Optional<A> result = mapper(_value);
				assert(result != null);
				return result;
			} else {
				return new Optional<A>.empty();
			}
		}
	}
}
