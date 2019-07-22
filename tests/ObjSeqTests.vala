/* ObjSeqTests.vala
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

public class ObjSeqTests : SeqTests<Obj> {
	private static int64 objects;
	private Rand _rand;

	public ObjSeqTests () {
		base("seq<Obj>");
		_rand = new Rand();
	}

	public override void set_up () {
		assert(atomic_int64_get(ref objects) == 0);
	}

	public override void tear_down () {
		Thread.usleep(500000); // Wait object finalizations
		assert(atomic_int64_get(ref objects) == 0);
	}

	protected override Seq<Obj> create_rand_seq () {
		return Seq.of_supply_func<Obj>((SupplyFunc<Obj>) random);
	}

	protected override Iterator<Obj> create_rand_iter (int64 length, uint32? seed = null) {
		if (seed == null) seed = Random.next_int();
		Rand r = new Rand.with_seed(seed);
		return new FiniteSupplyIterator<Obj>(() => _random(r), length);
	}

	protected override Iterator<Obj> create_distinct_iter (int64 length) {
		int i = 0;
		SupplyFunc<Obj> func = () => new Obj(wrap_atomic_int_add(ref i, 1));
		return new FiniteSupplyIterator<Obj>((owned) func, length);
	}

	protected override uint hash (Obj g) {
		return g.val;
	}

	protected override bool equal (Obj a, Obj b) {
		return a.val == b.val;
	}

	protected override int compare (Obj a, Obj b) {
		return a.val < b.val ? -1 : (a.val == b.val ? 0 : 1);
	}

	protected override bool filter (Obj g) {
		return g.val % 2 == 0;
	}

	protected override Obj random () {
		lock (_rand) {
			return _random(_rand);
		}
	}

	private Obj _random (Rand rand) {
		return new Obj( (int)rand.next_int() );
	}

	protected override Obj combine (owned Obj a, owned Obj b) {
		int result;
		Overflow.int_add(a.val, b.val, out result);
		return new Obj(result);
	}

	protected override Obj identity () {
		return new Obj(0);
	}

	protected override string map_to_str (owned Obj g) {
		return g.val.to_string();
	}

	protected override Iterator<Obj> flat_map (owned Obj g) {
		lock (_rand) {
			_rand.set_seed(g.val);
			Gee.List<Obj> list = new ArrayList<Obj>();
			list.add(g);
			list.add( new Obj((int)_rand.next_int()) );
			list.add( new Obj((int)_rand.next_int()) );
			return list.iterator();
		}
	}

	protected override int map_to_int (owned Obj g) {
		return g.val;
	}
	
	public class Obj : Object {
		public int val;

		public Obj (int val) {
			this.val = val;
			atomic_int64_inc(ref objects);
		}

		~Obj () {
			atomic_int64_dec_and_test(ref objects);
		}
	}
}
