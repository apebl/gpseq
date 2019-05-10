/* benchmark-sort.vala
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

using Benchmarks;
using Gpseq;
using Gee;

void benchmark_sort () {
	int[] nums = {
		10, 100, 1000, 10000, 100000, 1000000, 5000000,
		10000000, 20000000, 30000000, 40000000, 50000000,
		60000000, 70000000, 80000000, 90000000, 100000000
	};

	benchmark(17, r => {
		int length = nums[r.current_iteration];
		r.set_xval( length.to_string() );

		r.report("GenericArray.sort_with_data", s => {
			var array = create_rand_generic_int_array(length);
			var cmp = Functions.get_compare_func_for(typeof(int));
			s.start();
			array.sort_with_data(cmp);
		});

		r.report("ArrayList.sort", s => {
			var list = new ArrayList<int>();
			for (int i = 0; i < length; i++) {
				list.add((int) Random.next_int());
			}
			s.start();
			list.sort();
		});

		r.report("Gpseq.parallel_sort", s => {
			var array = create_rand_generic_int_array(length);
			s.start();
			parallel_sort<int>(array.data);
		});
	}).print().save_data("sort.dat");
}
