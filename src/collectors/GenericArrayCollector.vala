/* GenericArrayCollector.vala
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

private class Gpseq.Collectors.GenericArrayCollector<G> : Object, Collector<GenericArray<G>,Accumulator<G>,G> {
	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator<G> create_accumulator () throws Error {
		return new Accumulator<G>();
	}

	public void accumulate (G g, Accumulator<G> a) throws Error {
		a.array.add(g);
	}

	public Accumulator<G> combine (Accumulator<G> a, Accumulator<G> b) throws Error {
		for (int i = 0; i < b.array.length; i++) {
			a.array.add(b.array[i]);
		}
		return a;
	}

	public GenericArray<G> finish (Accumulator<G> a) throws Error {
		return a.array;
	}

	public class Accumulator<G> : Object {
		public GenericArray<G> array;

		public Accumulator () {
			array = new GenericArray<G>();
		}
	}
}
