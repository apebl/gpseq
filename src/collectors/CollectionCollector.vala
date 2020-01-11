/* CollectionCollector.vala
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

private class Gpseq.Collectors.CollectionCollector<G> : Object, Collector<Collection<G>,Collection<G>,G> {
	private Supplier<Collection<G>> _factory;
	private CollectorFeatures _features;

	public CollectionCollector (Supplier<Collection<G>> factory, CollectorFeatures features) {
		_factory = factory;
		_features = features;
	}

	public CollectorFeatures features {
		get {
			return _features;
		}
	}

	public Collection<G> create_accumulator () throws Error {
		return _factory.supply();
	}

	public void accumulate (G g, Collection<G> a) throws Error {
		a.add(g);
	}

	public Collection<G> combine (Collection<G> a, Collection<G> b) throws Error {
		a.add_all(b);
		return a;
	}

	public Collection<G> finish (Collection<G> a) throws Error {
		return a;
	}
}
