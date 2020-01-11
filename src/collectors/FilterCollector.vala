/* FilterCollector.vala
 *
 * Copyright (C) 2019-2020  Космическое П. (kosmospredanie@yandex.ru)
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

private class Gpseq.Collectors.FilterCollector<A,G> : Object, Collector<A,Object,G> {
	private Predicate<G> _pred;
	private Collector<A,Object,G> _downstream;

	public FilterCollector (owned Predicate<G> pred, Collector<A,Object,G> downstream) {
		_pred = (owned) pred;
		_downstream = downstream;
	}

	public CollectorFeatures features {
		get {
			return _downstream.features;
		}
	}

	public Object create_accumulator () throws Error {
		return _downstream.create_accumulator();
	}

	public void accumulate (G g, Object a) throws Error {
		if (_pred(g)) {
			_downstream.accumulate(g, a);
		}
	}

	public Object combine (Object a, Object b) throws Error {
		return _downstream.combine(a, b);
	}

	public A finish (Object a) throws Error {
		return _downstream.finish(a);
	}
}
