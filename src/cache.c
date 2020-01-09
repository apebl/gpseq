/* cache.h
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
 * GPSEQ_CACHE_LINE_SIZE:
 *
 * The cache line size of the target platform. If this macro is not defined,
 * Gpseq determines and defines it.
 */

#ifndef GPSEQ_CACHE_LINE_SIZE
#	if defined(__powerpc__) || defined(__ppc__) /* PowerPC */
#		define GPSEQ_CACHE_LINE_SIZE 128
#	elif defined(__elbrus__) || defined(__e2k__) /* Elbrus */
#		define GPSEQ_CACHE_LINE_SIZE 256
#	else
#		define GPSEQ_CACHE_LINE_SIZE 64
#	endif
#endif

typedef struct {
	char _[GPSEQ_CACHE_LINE_SIZE];
} GpseqCacheLinePad;
