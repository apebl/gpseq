/* StringSeqTests.vala
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
using Gpseq;
using TestUtils;

public class StringSeqTests : SeqTests<string> {
	private const string MAGIC_STRING = "seven-two-six";

	public StringSeqTests () {
		base("seq<string>");
		register_tests();
	}

	private void register_tests () {
		add_test("collector-join", () => test_collector_join(false));
		add_test("collector-join:parallel", () => test_collector_join(true));
	}

	protected override Seq<string> create_rand_seq () {
		return Seq.of_supply_func<string>((SupplyFunc<string>) random);
	}

	protected override Iterator<string> create_rand_iter (int64 length, uint32? seed = null) {
		if (seed == null) seed = Random.next_int();
		Rand r = new Rand.with_seed(seed);
		return new FiniteSupplyIterator<string>(() => TestUtils.random_str(32, r), length);
	}

	protected override Iterator<string> create_distinct_iter (int64 length) {
		int i = 0;
		SupplyFunc<string> func = () => wrap_atomic_int_add(ref i, 1).to_string();
		return new FiniteSupplyIterator<string>((owned) func, length);
	}

	protected override uint hash (string g) {
		return str_hash(g);
	}

	protected override bool equal (string a, string b) {
		return str_equal(a, b);
	}

	protected override int compare (string a, string b) {
		return strcmp(a, b);
	}

	protected override bool filter (string g) {
		return !g.contains("a");
	}

	protected override string random () {
		return TestUtils.random_str(32);
	}

	protected override string combine (owned string a, owned string b) {
		int i = a == MAGIC_STRING ? 0 : int.parse(a);
		int i2 = b == MAGIC_STRING ? 0 : int.parse(b);
		int result;
		Overflow.int_add(i, i2, out result);
		return result.to_string();
	}

	protected override string identity () {
		return MAGIC_STRING;
	}

	protected override string map_to_str (owned string g) {
		return g;
	}

	protected override Iterator<string> flat_map (owned string g) {
		Gee.List<string> list = new ArrayList<string>();
		list.add(g);
		list.add("hello");
		list.add("world");
		return list.iterator();
	}

	protected override int map_to_int (owned string g) {
		return (int)hash(g);
	}

	private void test_collector_join (bool parallel) {
		string[] list = {"", "d", "on", "", "key", ""};
		if (parallel) {
			Seq<string> seq = Seq.of_array<string>(list).parallel();
			assert(seq.collect(Collectors.join()).value == "donkey");
			seq = Seq.of_array<string>(list).parallel();
			assert(seq.collect_ordered(Collectors.join()).value == "donkey");
			seq = Seq.of_array<string>(list).parallel();
			assert(seq.collect(Collectors.join(",")).value == ",d,on,,key,");
			seq = Seq.of_array<string>(list).parallel();
			assert(seq.collect_ordered(Collectors.join(",")).value == ",d,on,,key,");
		} else {
			Seq<string> seq = Seq.of_array<string>(list);
			assert(seq.collect(Collectors.join()).value == "donkey");
			seq = Seq.of_array<string>(list);
			assert(seq.collect_ordered(Collectors.join()).value == "donkey");
			seq = Seq.of_array<string>(list);
			assert(seq.collect(Collectors.join(",")).value == ",d,on,,key,");
			seq = Seq.of_array<string>(list);
			assert(seq.collect_ordered(Collectors.join(",")).value == ",d,on,,key,");
		}
	}
}
