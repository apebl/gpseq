/* SumUlongCollector.vala
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

private class Gpseq.Collectors.SumUlongCollector<G> : Object, Collector<ulong,Accumulator,G> {
	private MapFunc<ulong,G> _mapper;

	public SumUlongCollector (owned MapFunc<ulong,G> mapper) {
		_mapper = (owned) mapper;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator create_accumulator () {
		return new Accumulator(0);
	}

	public void accumulate (G g, Accumulator a) {
		a.val += _mapper(g);
	}

	public Accumulator combine (Accumulator a, Accumulator b) {
		a.val += b.val;
		return a;
	}

	public ulong finish (Accumulator a) {
		return a.val;
	}

	public class Accumulator : Object {
		public ulong val { get; set; }
		public Accumulator (ulong val) {
			_val = val;
		}
	}
}
