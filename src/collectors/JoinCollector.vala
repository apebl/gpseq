/* JoinCollector.vala
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

private class Gpseq.Collectors.JoinCollector : Object, Collector<string,Accumulator,string> {
	private string _delimiter;

	public JoinCollector (owned string delimiter) {
		_delimiter = (owned) delimiter;
	}

	public CollectorFeatures features {
		get {
			return 0;
		}
	}

	public Accumulator create_accumulator () throws Error {
		return new Accumulator();
	}

	public void accumulate (string g, Accumulator a) throws Error {
		if (!a.empty) a.val.append(_delimiter);
		a.val.append(g);
	}

	public Accumulator combine (Accumulator a, Accumulator b) throws Error {
		if (a.empty) {
			return b;
		} else if (b.empty) {
			return a;
		} else {
			a.val.append(_delimiter).append(b.val.str);
			return a;
		}
	}

	public string finish (Accumulator a) throws Error {
		return a.val.str;
	}

	public class Accumulator : Object {
		private StringBuilder _val;

		public Accumulator () {
			_val = new StringBuilder();
			empty = true;
		}

		public StringBuilder val {
			get {
				empty = false;
				return _val;
			}
		}

		public bool empty {
			get; private set;
		}
	}
}
