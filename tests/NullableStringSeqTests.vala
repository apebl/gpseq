/* NullableStringSeqTests.vala
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

public class NullableStringSeqTests : SeqTests<string?> {
	private Rand _rand;

	public NullableStringSeqTests () {
		base("seq<string?>");
		_rand = new Rand();
	}

	protected override Seq<string?> create_rand_seq () {
		return Seq.of_supply_func<string?>(random);
	}

	protected override Iterator<string?> create_rand_iter (int64 length, uint32? seed = null) {
		if (seed == null) seed = Random.next_int();
		Rand r = new Rand.with_seed(seed);
		return new FiniteSupplyIterator<string?>(() => _random(r), length);
	}

	protected override Iterator<string?> create_distinct_iter (int64 length) {
		int i = 0;
		SupplyFunc<string?> func = () => {
			int val = wrap_atomic_int_add(ref i, 1);
			return val == 0 ? null : (val-2).to_string();
		};
		return new FiniteSupplyIterator<string?>((owned) func, length);
	}

	protected override uint hash (string? g) {
		return g == null ? (uint)0xdeadbeef : str_hash(g);
	}

	protected override bool equal (string? a, string? b) {
		if (a == b) return true;
		else if (a == null || b == null) return false;
		else return str_equal(a, b);
	}

	protected override int compare (string? a, string? b) {
		if (a == b) return 0;
		else if (a == null) return -1;
		else if (b == null) return 1;
		else return strcmp(a, b);
	}

	protected override bool filter (string? g) {
		return g == null || !g.contains("a");
	}

	protected override string? random () {
		lock (_rand) {
			return _random(_rand);
		}
	}

	private string? _random (Rand rand) {
		return rand.boolean() ? TestUtils.random_str(32, rand) : null;
	}

	protected override string? combine (owned string? a, owned string? b) {
		int i = a == null ? 0 : int.parse(a);
		int i2 = b == null ? 0 : int.parse(b);
		int sum = wrap_int_add(i, i2);
		return sum.to_string();
	}

	protected override string? identity () {
		return null;
	}

	protected override string map_to_str (owned string? g) {
		return g == null ? "null" : g;
	}

	protected override Iterator<string?> flat_map (owned string? g) {
		Gee.List<string?> list = new ArrayList<string?>();
		list.add(g);
		list.add("hello");
		list.add(null);
		return list.iterator();
	}

	protected override int map_to_int (owned string? g) {
		return (int)hash(g);
	}
}
