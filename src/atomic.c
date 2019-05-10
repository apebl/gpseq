/* atomic.c
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
 * GPSEQ_ATOMIC_INT64_LOCK_FREE:
 *
 * This macro is defined if the 64-bit atomic operations of Gpseq are
 * implemented using real hardware atomic operations. This means that the
 * Gpseq 64-bit atomic API can be used between processes and safely mixed
 * with other (hardware) atomic APIs.
 *
 * If this macro is not defined, the 64-bit atomic operations may be
 * emulated using a mutex. In that case, the atomic operations are only
 * atomic relative to themselves and within a single process.
 */

/**
 * gpseq_atomic_int64_get:
 * @atomic: a pointer to a #gint64 or #guint64
 *
 * Gets the current value of @atomic.
 *
 * This call acts as a full compiler and hardware
 * memory barrier (before the get).
 *
 * Returns: the value of the integer
 **/
gint64 gpseq_atomic_int64_get (const volatile gint64 *atomic);

/**
 * gpseq_atomic_int64_set:
 * @atomic: a pointer to a #gint64 or #guint64
 * @newval: a new value to store
 *
 * Sets the value of @atomic to @newval.
 *
 * This call acts as a full compiler and hardware
 * memory barrier (after the set).
 **/
void gpseq_atomic_int64_set (volatile gint64 *atomic, gint64 newval);

/**
 * gpseq_atomic_int64_inc:
 * @atomic: a pointer to a #gint64 or #guint64
 *
 * Increments the value of @atomic by 1.
 *
 * Think of this operation as an atomic version of `{ *atomic += 1; }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 **/
void gpseq_atomic_int64_inc (volatile gint64 *atomic);

/**
 * gpseq_atomic_int64_dec_and_test:
 * @atomic: a pointer to a #gint64 or #guint64
 *
 * Decrements the value of @atomic by 1.
 *
 * Think of this operation as an atomic version of
 * `{ *atomic -= 1; return (*atomic == 0); }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Returns: %TRUE if the resultant value is zero
 **/
gboolean gpseq_atomic_int64_dec_and_test (volatile gint64 *atomic);

/**
 * gpseq_atomic_int64_compare_and_exchange:
 * @atomic: a pointer to a #gint64 or #guint64
 * @oldval: the value to compare with
 * @newval: the value to conditionally replace with
 *
 * Compares @atomic to @oldval and, if equal, sets it to @newval.
 * If @atomic was not equal to @oldval then no change occurs.
 *
 * This compare and exchange is done atomically.
 *
 * Think of this operation as an atomic version of
 * `{ if (*atomic == oldval) { *atomic = newval; return TRUE; } else return FALSE; }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Returns: %TRUE if the exchange took place
 **/
gboolean gpseq_atomic_int64_compare_and_exchange (volatile gint64 *atomic, gint64 oldval, gint64 newval);

/**
 * gpseq_atomic_int64_add:
 * @atomic: a pointer to a #gint64 or #guint64
 * @val: the value to add
 *
 * Atomically adds @val to the value of @atomic.
 *
 * Think of this operation as an atomic version of
 * `{ tmp = *atomic; *atomic += val; return tmp; }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Returns: the value of @atomic before the add, signed
 **/
gint64 gpseq_atomic_int64_add (volatile gint64 *atomic, gint64 val);

/**
 * gpseq_atomic_int64_and:
 * @atomic: a pointer to a #gint64 or #guint64
 * @val: the value to 'and'
 *
 * Performs an atomic bitwise 'and' of the value of @atomic and @val,
 * storing the result back in @atomic.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Think of this operation as an atomic version of
 * `{ tmp = *atomic; *atomic &= val; return tmp; }`.
 *
 * Returns: the value of @atomic before the operation, unsigned
 **/
guint64 gpseq_atomic_int64_and (volatile guint64 *atomic, guint64 val);

/**
 * gpseq_atomic_int64_or:
 * @atomic: a pointer to a #gint64 or #guint64
 * @val: the value to 'or'
 *
 * Performs an atomic bitwise 'or' of the value of @atomic and @val,
 * storing the result back in @atomic.
 *
 * Think of this operation as an atomic version of
 * `{ tmp = *atomic; *atomic |= val; return tmp; }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Returns: the value of @atomic before the operation, unsigned
 **/
guint64 gpseq_atomic_int64_or (volatile guint64 *atomic, guint64 val);

/**
 * gpseq_atomic_int64_xor:
 * @atomic: a pointer to a #gint64 or #guint64
 * @val: the value to 'xor'
 *
 * Performs an atomic bitwise 'xor' of the value of @atomic and @val,
 * storing the result back in @atomic.
 *
 * Think of this operation as an atomic version of
 * `{ tmp = *atomic; *atomic ^= val; return tmp; }`.
 *
 * This call acts as a full compiler and hardware memory barrier.
 *
 * Returns: the value of @atomic before the operation, unsigned
 **/
guint64 gpseq_atomic_int64_xor (volatile guint64 *atomic, guint64 val);

#if defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8)

#if defined(__ATOMIC_SEQ_CST)

gint64 gpseq_atomic_int64_get (const volatile gint64 *atomic) {
	return __atomic_load_8(atomic, __ATOMIC_SEQ_CST);
}

void gpseq_atomic_int64_set (volatile gint64 *atomic, gint64 newval) {
	__atomic_store_8(atomic, newval, __ATOMIC_SEQ_CST);
}

void gpseq_atomic_int64_inc (volatile gint64 *atomic) {
	__atomic_add_fetch(atomic, 1, __ATOMIC_SEQ_CST);
}

gboolean gpseq_atomic_int64_dec_and_test (volatile gint64 *atomic) {
	return __atomic_sub_fetch(atomic, 1, __ATOMIC_SEQ_CST) == 0;
}

gboolean gpseq_atomic_int64_compare_and_exchange (volatile gint64 *atomic, gint64 oldval, gint64 newval) {
	return __atomic_compare_exchange_8(atomic, &oldval, newval, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

gint64 gpseq_atomic_int64_add (volatile gint64 *atomic, gint64 val) {
	return __atomic_fetch_add(atomic, val, __ATOMIC_SEQ_CST);
}

guint64 gpseq_atomic_int64_and (volatile guint64 *atomic, guint64 val) {
	return __atomic_fetch_and(atomic, val, __ATOMIC_SEQ_CST);
}

guint64 gpseq_atomic_int64_or (volatile guint64 *atomic, guint64 val) {
	return __atomic_fetch_or(atomic, val, __ATOMIC_SEQ_CST);
}

guint64 gpseq_atomic_int64_xor (volatile guint64 *atomic, guint64 val) {
	return __atomic_fetch_xor(atomic, val, __ATOMIC_SEQ_CST);
}

#else /* defined(__ATOMIC_SEQ_CST) */

gint64 gpseq_atomic_int64_get (const volatile gint64 *atomic) {
	__sync_synchronize();
	return *atomic;
}

void gpseq_atomic_int64_set (volatile gint64 *atomic, gint64 newval) {
	*atomic = newval;
	__sync_synchronize();
}

void gpseq_atomic_int64_inc (volatile gint64 *atomic) {
	__sync_add_and_fetch(atomic, 1);
}

gboolean gpseq_atomic_int64_dec_and_test (volatile gint64 *atomic) {
	return __sync_sub_and_fetch(atomic, 1) == 0;
}

gboolean gpseq_atomic_int64_compare_and_exchange (volatile gint64 *atomic, gint64 oldval, gint64 newval) {
	return __sync_bool_compare_and_swap(atomic, oldval, newval);
}

gint64 gpseq_atomic_int64_add (volatile gint64 *atomic, gint64 val) {
	return __sync_fetch_and_add(atomic, val);
}

guint64 gpseq_atomic_int64_and (volatile guint64 *atomic, guint64 val) {
	return __sync_fetch_and_and(atomic, val);
}

guint64 gpseq_atomic_int64_or (volatile guint64 *atomic, guint64 val) {
	return __sync_fetch_and_or(atomic, val);
}

guint64 gpseq_atomic_int64_xor (volatile guint64 *atomic, guint64 val) {
	return __sync_fetch_and_xor(atomic, val);
}

#endif /* defined(__ATOMIC_SEQ_CST) */

#elif defined(G_PLATFORM_WIN32) /* defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8) */

#include <windows.h>

gint64 gpseq_atomic_int64_get (const volatile gint64 *atomic) {
	MemoryBarrier();
	return *atomic;
}

void gpseq_atomic_int64_set (volatile gint64 *atomic, gint64 newval) {
	*atomic = newval;
	MemoryBarrier();
}

void gpseq_atomic_int64_inc (volatile gint64 *atomic) {
	InterlockedIncrement64(atomic);
}

gboolean gpseq_atomic_int64_dec_and_test (volatile gint64 *atomic) {
	return InterlockedDecrement64(atomic) == 0;
}

gboolean gpseq_atomic_int64_compare_and_exchange (volatile gint64 *atomic, gint64 oldval, gint64 newval) {
	return InterlockedCompareExchange64(atomic, newval, oldval) == oldval;
}

gint64 gpseq_atomic_int64_add (volatile gint64 *atomic, gint64 val) {
	return InterlockedExchangeAdd64(atomic, val);
}

guint64 gpseq_atomic_int64_and (volatile guint64 *atomic, guint64 val) {
	return InterlockedAnd64(atomic, val);
}

guint64 gpseq_atomic_int64_or (volatile guint64 *atomic, guint64 val) {
	return InterlockedOr64(atomic, val);
}

guint64 gpseq_atomic_int64_xor (volatile guint64 *atomic, guint64 val) {
	return InterlockedXor64(atomic, val);
}

#else /* defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8) */

#if defined(GPSEQ_ATOMIC_INT64_LOCK_FREE)
#error GPSEQ_ATOMIC_INT64_LOCK_FREE defined, but incapable of lock-free atomics.
#endif

static GMutex gpseq_atomic_lock;

gint64 gpseq_atomic_int64_get (const volatile gint64 *atomic) {
	gint64 value;
	g_mutex_lock(&gpseq_atomic_lock);
	value = *atomic;
	g_mutex_unlock(&gpseq_atomic_lock);
	return value;
}

void gpseq_atomic_int64_set (volatile gint64 *atomic, gint64 value) {
	g_mutex_lock(&gpseq_atomic_lock);
	*atomic = value;
	g_mutex_unlock(&gpseq_atomic_lock);
}

void gpseq_atomic_int64_inc (volatile gint64 *atomic) {
	g_mutex_lock(&gpseq_atomic_lock);
	(*atomic)++;
	g_mutex_unlock(&gpseq_atomic_lock);
}

gboolean gpseq_atomic_int64_dec_and_test (volatile gint64 *atomic) {
	gboolean is_zero;
	g_mutex_lock(&gpseq_atomic_lock);
	is_zero = --(*atomic) == 0;
	g_mutex_unlock(&gpseq_atomic_lock);
	return is_zero;
}

gboolean gpseq_atomic_int64_compare_and_exchange (volatile gint64 *atomic, gint64 oldval, gint64 newval) {
	gboolean success;
	g_mutex_lock(&gpseq_atomic_lock);
	if ((success = (*atomic == oldval))) {
		*atomic = newval;
	}
	g_mutex_unlock(&gpseq_atomic_lock);
	return success;
}

gint64 gpseq_atomic_int64_add (volatile gint64 *atomic, gint64 val) {
	gint64 oldval;
	g_mutex_lock(&gpseq_atomic_lock);
	oldval = *atomic;
	*atomic = oldval + val;
	g_mutex_unlock(&gpseq_atomic_lock);
	return oldval;
}

guint64 gpseq_atomic_int64_and (volatile guint64 *atomic, guint64 val) {
	guint64 oldval;
	g_mutex_lock(&gpseq_atomic_lock);
	oldval = *atomic;
	*atomic = oldval & val;
	g_mutex_unlock(&gpseq_atomic_lock);
	return oldval;
}

guint64 gpseq_atomic_int64_or (volatile guint64 *atomic, guint64 val) {
	guint64 oldval;
	g_mutex_lock(&gpseq_atomic_lock);
	oldval = *atomic;
	*atomic = oldval | val;
	g_mutex_unlock(&gpseq_atomic_lock);
	return oldval;
}

guint64 gpseq_atomic_int64_xor (volatile guint64 *atomic, guint64 val) {
	guint64 oldval;
	g_mutex_lock(&gpseq_atomic_lock);
	oldval = *atomic;
	*atomic = oldval ^ val;
	g_mutex_unlock(&gpseq_atomic_lock);
	return oldval;
}

#endif /* defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8) */
