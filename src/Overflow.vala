/* Overflow.vala
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

namespace Gpseq.Overflow {
	/**
	 * Performs an operation that adds //a// and //b// and returns the result,
	 * with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int_add")]
	public extern bool int_add (int a, int b, out int result = null);

	/**
	 * Performs an operation that subtracts //b// from //a// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int_sub")]
	public extern bool int_sub (int a, int b, out int result = null);

	/**
	 * Performs an operation that multiplies //a// and //b// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int_mul")]
	public extern bool int_mul (int a, int b, out int result = null);

	/**
	 * Performs an operation that adds //a// and //b// and returns the result,
	 * with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_long_add")]
	public extern bool long_add (long a, long b, out long result = null);

	/**
	 * Performs an operation that subtracts //b// from //a// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_long_sub")]
	public extern bool long_sub (long a, long b, out long result = null);

	/**
	 * Performs an operation that multiplies //a// and //b// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_long_mul")]
	public extern bool long_mul (long a, long b, out long result = null);

	/**
	 * Performs an operation that adds //a// and //b// and returns the result,
	 * with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int32_add")]
	public extern bool int32_add (int32 a, int32 b, out int32 result = null);

	/**
	 * Performs an operation that subtracts //b// from //a// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int32_sub")]
	public extern bool int32_sub (int32 a, int32 b, out int32 result = null);

	/**
	 * Performs an operation that multiplies //a// and //b// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int32_mul")]
	public extern bool int32_mul (int32 a, int32 b, out int32 result = null);

	/**
	 * Performs an operation that adds //a// and //b// and returns the result,
	 * with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int64_add")]
	public extern bool int64_add (int64 a, int64 b, out int64 result = null);

	/**
	 * Performs an operation that subtracts //b// from //a// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int64_sub")]
	public extern bool int64_sub (int64 a, int64 b, out int64 result = null);

	/**
	 * Performs an operation that multiplies //a// and //b// and returns the
	 * result, with checking whether the operation overflowed.
	 *
	 * If the operation not overflowed, sets //result// to the result of the
	 * operation and returns false. If the operation overflowed, set //result//
	 * to the operation result wrapped around and returns true.
	 *
	 * @param a an integer
	 * @param b an integer
	 * @param result returns the result of the arithmetic operation
	 * @return true if the operation overflowed, and false otherwise
	 **/
	[CCode (cname="gpseq_overflow_int64_mul")]
	public extern bool int64_mul (int64 a, int64 b, out int64 result = null);
}
