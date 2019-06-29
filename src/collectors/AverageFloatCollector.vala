/* AverageFloatCollector.vala
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

private class Gpseq.Collectors.AverageFloatCollector<G> : Object, Collector<float?,Accumulator,G> {
	private MapFunc<float?,G> _mapper;

	public AverageFloatCollector (owned MapFunc<float?,G> mapper) {
		_mapper = (owned) mapper;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator create_accumulator () throws Error {
		return new Accumulator(0, 0);
	}

	public void accumulate (G g, Accumulator a) throws Error {
		a.val += _mapper(g);
		a.count++;
	}

	public Accumulator combine (Accumulator a, Accumulator b) throws Error {
		a.val += b.val;
		a.count += b.count;
		return a;
	}

	public float? finish (Accumulator a) throws Error {
		return a.count == 0 ? 0 : a.val/a.count;
	}

	public class Accumulator : Object {
		public float val { get; set; }
		public int64 count { get; set; }
		public Accumulator (float val, int64 count) {
			_val = val;
			_count = count;
		}
	}
}
