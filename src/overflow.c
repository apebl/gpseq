/* overflow.c
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

#include <glib.h>

/**
 * gpseq_overflow_int_add:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that adds @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int_add (gint a, gint b, gint *result);

/**
 * gpseq_overflow_int_sub:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that subtracts @b from @a and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int_sub (gint a, gint b, gint *result);

/**
 * gpseq_overflow_int_mul:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that multiplies @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int_mul (gint a, gint b, gint *result);

/**
 * gpseq_overflow_long_add:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that adds @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_long_add (glong a, glong b, glong *result);

/**
 * gpseq_overflow_long_sub:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that subtracts @b from @a and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_long_sub (glong a, glong b, glong *result);

/**
 * gpseq_overflow_long_mul:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that multiplies @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_long_mul (glong a, glong b, glong *result);

/**
 * gpseq_overflow_int32_add:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that adds @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int32_add (gint32 a, gint32 b, gint32 *result);

/**
 * gpseq_overflow_int32_sub:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that subtracts @b from @a and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int32_sub (gint32 a, gint32 b, gint32 *result);

/**
 * gpseq_overflow_int32_mul:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that multiplies @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int32_mul (gint32 a, gint32 b, gint32 *result);

/**
 * gpseq_overflow_int64_add:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that adds @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int64_add (gint64 a, gint64 b, gint64 *result);

/**
 * gpseq_overflow_int64_sub:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that subtracts @b from @a and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int64_sub (gint64 a, gint64 b, gint64 *result);

/**
 * gpseq_overflow_int64_mul:
 * @a: an integer
 * @b: an integer
 * @result: (nullable): returns the result of the arithmetic operation
 *
 * Performs an operation that multiplies @a and @b and returns the result, with
 * checking whether the operation overflowed.
 *
 * If the operation not overflowed, sets @result to the result of the operation
 * and returns FALSE. If the operation overflowed, set @result to the operation
 * result wrapped around and returns TRUE.
 *
 * Returns: TRUE if the operation overflowed, and FALSE otherwise
 **/
gboolean gpseq_overflow_int64_mul (gint64 a, gint64 b, gint64 *result);

#ifndef __has_builtin
#define __has_builtin(x) 0
#endif

#if __GNUC__ >= 5 || __has_builtin(__builtin_add_overflow)

gboolean gpseq_overflow_int_add (gint a, gint b, gint *result) {
	return __builtin_add_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int_sub (gint a, gint b, gint *result) {
	return __builtin_sub_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int_mul (gint a, gint b, gint *result) {
	return __builtin_mul_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_long_add (glong a, glong b, glong *result) {
	return __builtin_add_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_long_sub (glong a, glong b, glong *result) {
	return __builtin_sub_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_long_mul (glong a, glong b, glong *result) {
	return __builtin_mul_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int32_add (gint32 a, gint32 b, gint32 *result) {
	return __builtin_add_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int32_sub (gint32 a, gint32 b, gint32 *result) {
	return __builtin_sub_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int32_mul (gint32 a, gint32 b, gint32 *result) {
	return __builtin_mul_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int64_add (gint64 a, gint64 b, gint64 *result) {
	return __builtin_add_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int64_sub (gint64 a, gint64 b, gint64 *result) {
	return __builtin_sub_overflow(a, b, result == NULL ? &a : result);
}

gboolean gpseq_overflow_int64_mul (gint64 a, gint64 b, gint64 *result) {
	return __builtin_mul_overflow(a, b, result == NULL ? &a : result);
}

#else /* __GNUC__ >= 5 || __has_builtin(__builtin_add_overflow) */

#ifndef __SIZEOF_INT__
#	if G_MAXINT == G_MAXINT16
#		define __SIZEOF_INT__ 2
#	elif G_MAXINT == G_MAXINT32
#		define __SIZEOF_INT__ 4
#	elif G_MAXINT == G_MAXINT64
#		define __SIZEOF_INT__ 8
#	endif
#endif

gboolean gpseq_overflow_int_add (gint a, gint b, gint *result) {
#if __SIZEOF_INT__ == 2
	gint32 temp = (gint32)a + (gint32)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#elif __SIZEOF_INT__ == 4
	gint64 temp = (gint64)a + (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#elif __SIZEOF_INT__ == 8 && defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a + (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#else
	if ((b > 0 && a > G_MAXINT - b) || (b < 0 && a < G_MININT - b)) {
		if (result != NULL) { *result = (guint)a + (guint)b; }
		return TRUE;
	} else {
		if (result != NULL) { *result = a + b; }
		return FALSE;
	}
#endif
}

gboolean gpseq_overflow_int_sub (gint a, gint b, gint *result) {
	return gpseq_overflow_int_add(a, -b, result);
}

gboolean gpseq_overflow_int_mul (gint a, gint b, gint *result) {
#if __SIZEOF_INT__ == 2
	gint32 temp = (gint32)a * (gint32)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#elif __SIZEOF_INT__ == 4
	gint64 temp = (gint64)a * (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#elif __SIZEOF_INT__ == 8 && defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a * (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT || temp < G_MININT;
#else
	if (result != NULL) { *result = (guint)a * (guint)b; }
	if ( !(a && b) ) {
		return FALSE;
	} else if (a > 0) {
		if (b > 0) {
			return a > G_MAXINT / b;
		} else {
			return b < G_MININT / a;
		}
	} else {
		if (b > 0) {
			return a < G_MININT / b;
		} else {
			return b < G_MAXINT / a;
		}
	}
#endif
}

#ifndef __SIZEOF_LONG__
#	if G_MAXLONG == G_MAXINT32
#		define __SIZEOF_LONG__ 4
#	elif G_MAXLONG == G_MAXINT64
#		define __SIZEOF_LONG__ 8
#	endif
#endif

gboolean gpseq_overflow_long_add (glong a, glong b, glong *result) {
#if __SIZEOF_LONG__ == 4
	gint64 temp = (gint64)a + (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXLONG || temp < G_MINLONG;
#elif __SIZEOF_LONG__ == 8 && defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a + (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXLONG || temp < G_MINLONG;
#else
	if ((b > 0 && a > G_MAXLONG - b) || (b < 0 && a < G_MINLONG - b)) {
		if (result != NULL) { *result = (gulong)a + (gulong)b; }
		return TRUE;
	} else {
		if (result != NULL) { *result = a + b; }
		return FALSE;
	}
#endif
}

gboolean gpseq_overflow_long_sub (glong a, glong b, glong *result) {
	return gpseq_overflow_long_add(a, -b, result);
}

gboolean gpseq_overflow_long_mul (glong a, glong b, glong *result) {
#if __SIZEOF_LONG__ == 4
	gint64 temp = (gint64)a * (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXLONG || temp < G_MINLONG;
#elif __SIZEOF_LONG__ == 8 && defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a * (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXLONG || temp < G_MINLONG;
#else
	if (result != NULL) { *result = (gulong)a * (gulong)b; }
	if ( !(a && b) ) {
		return FALSE;
	} else if (a > 0) {
		if (b > 0) {
			return a > G_MAXLONG / b;
		} else {
			return b < G_MINLONG / a;
		}
	} else {
		if (b > 0) {
			return a < G_MINLONG / b;
		} else {
			return b < G_MAXLONG / a;
		}
	}
#endif
}

gboolean gpseq_overflow_int32_add (gint32 a, gint32 b, gint32 *result) {
	gint64 temp = (gint64)a + (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT32 || temp < G_MININT32;
}

gboolean gpseq_overflow_int32_sub (gint32 a, gint32 b, gint32 *result) {
	return gpseq_overflow_int32_add(a, -b, result);
}

gboolean gpseq_overflow_int32_mul (gint32 a, gint32 b, gint32 *result) {
	gint64 temp = (gint64)a * (gint64)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT32 || temp < G_MININT32;
}

gboolean gpseq_overflow_int64_add (gint64 a, gint64 b, gint64 *result) {
#if defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a + (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT64 || temp < G_MININT64;
#else
	if ((b > 0 && a > G_MAXINT64 - b) || (b < 0 && a < G_MININT64 - b)) {
		if (result != NULL) { *result = (guint64)a + (guint64)b; }
		return TRUE;
	} else {
		if (result != NULL) { *result = a + b; }
		return FALSE;
	}
#endif
}

gboolean gpseq_overflow_int64_sub (gint64 a, gint64 b, gint64 *result) {
	return gpseq_overflow_int64_add(a, -b, result);
}

gboolean gpseq_overflow_int64_mul (gint64 a, gint64 b, gint64 *result) {
#if defined(__SIZEOF_INT128__)
	__int128 temp = (__int128)a * (__int128)b;
	if (result != NULL) { *result = temp; }
	return temp > G_MAXINT64 || temp < G_MININT64;
#else
	if (result != NULL) { *result = (guint64)a * (guint64)b; }
	if ( !(a && b) ) {
		return FALSE;
	} else if (a > 0) {
		if (b > 0) {
			return a > G_MAXINT64 / b;
		} else {
			return b < G_MININT64 / a;
		}
	} else {
		if (b > 0) {
			return a < G_MININT64 / b;
		} else {
			return b < G_MAXINT64 / a;
		}
	}
#endif
}

#endif /* __GNUC__ >= 5 || __has_builtin(__builtin_add_overflow) */
