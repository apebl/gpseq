/* ReduceCollector.vala
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

private class Gpseq.Collectors.ReduceCollector<G> : Object, Collector<Optional<G>,Accumulator<G>,G> {
	private CombineFunc<G> _accumulator;

	public ReduceCollector (owned CombineFunc<G> accumulator) {
		_accumulator = (owned) accumulator;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator<G> create_accumulator () {
		return new Accumulator<G>();
	}

	public void accumulate (G g, Accumulator<G> a) {
		a.accumulate(g, _accumulator);
	}

	public Accumulator<G> combine (Accumulator<G> a, Accumulator<G> b) {
		if (b.is_present) a.accumulate(b.val, _accumulator);
		return a;
	}

	public Optional<G> finish (Accumulator<G> a) {
		return a.is_present ? new Optional<G>.of(a.val) : new Optional<G>.empty();
	}

	public class Accumulator<G> : Object {
		private G? _val = null;
		private bool _is_present = false;

		public G? val {
			get {
				return _val;
			}
		}

		public bool is_present {
			get {
				return _is_present;
			}
		}

		public void accumulate (G g, CombineFunc<G> func) {
			if (_is_present) {
				_val = func(_val, g);
			} else {
				_val = g;
				_is_present = true;
			}
		}
	}
}
