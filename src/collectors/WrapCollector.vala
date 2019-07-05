/* WrapCollector.vala
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

private class Gpseq.Collectors.WrapCollector<A,G> : Object, Collector<Wrapper<A>,Object,G> {
	private Collector<A,Object,G> _collector;

	public WrapCollector (Collector<A,Object,G> collector) {
		_collector = collector;
	}

	public CollectorFeatures features {
		get {
			return _collector.features;
		}
	}

	public Object create_accumulator () throws Error {
		return _collector.create_accumulator();
	}

	public void accumulate (G g, Object a) throws Error {
		_collector.accumulate(g, a);
	}

	public Object combine (Object a, Object b) throws Error {
		return _collector.combine(a, b);
	}

	public Wrapper<A> finish (Object a) throws Error {
		return new Wrapper<A>(_collector.finish(a));
	}
}
