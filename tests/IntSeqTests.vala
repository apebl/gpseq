/* IntSeqTests.vala
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

using Gpseq;
using Gee;
using TestUtils;

public class IntSeqTests : SeqTests<int> {
	private Rand _rand;

	public IntSeqTests () {
		base("seq<int>");
		_rand = new Rand();
	}

	protected override Seq<int> create_rand_seq () {
		return Seq.of_supply_func<int>((SupplyFunc<int>) random);
	}

	protected override Iterator<int> create_rand_iter (int64 length, uint32? seed = null) {
		if (seed == null) seed = Random.next_int();
		Rand r = new Rand.with_seed(seed);
		return new FiniteSupplyIterator<int>(() => _random(r), length);
	}

	protected override Iterator<int> create_distinct_iter (int64 length) {
		int i = 0;
		SupplyFunc<int> func = () => AtomicInt.add(ref i, 1);
		return new FiniteSupplyIterator<int>((owned) func, length);
	}

	protected override uint hash (int g) {
		return g;
	}

	protected override bool equal (int a, int b) {
		return a == b;
	}

	protected override int compare (int a, int b) {
		return a < b ? -1 : (a == b ? 0 : 1);
	}

	protected override bool filter (int g) {
		return g % 2 == 0;
	}

	protected override int random () {
		lock (_rand) {
			return _random(_rand);
		}
	}

	private int _random (Rand rand) {
		return (int) rand.next_int();
	}

	protected override int combine (owned int a, owned int b) {
		return a + b;
	}

	protected override int identity () {
		return 0;
	}

	protected override string map_to_str (owned int g) {
		return g.to_string();
	}

	protected override Iterator<int> flat_map (owned int g) {
		lock (_rand) {
			_rand.set_seed(g);
			Gee.List<int> list = new ArrayList<int>();
			list.add(g);
			list.add((int) _rand.next_int());
			list.add((int) _rand.next_int());
			return list.iterator();
		}
	}

	protected override int map_to_int (owned int g) {
		return g;
	}
}
