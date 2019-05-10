/* TestSuite.vala
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

namespace Gpseq {
	public abstract class TestSuite : Object {
		private string _name;
		private GLib.TestSuite _suite;
		private Adaptor[] _adaptors = {};

		public TestSuite (owned string name) {
			_name = (owned) name;
			_suite = new GLib.TestSuite(_name);
		}

		public string name {
			get {
				return _name;
			}
		}

		public void register () {
			GLib.TestSuite.get_root().add_suite(_suite);
		}

		public void add_test (string name, owned TestFunc test,
				owned TestFunc? set_up = null, owned TestFunc? tear_down = null) {
			var adaptor = new Adaptor (name, this, (owned) test, (owned) set_up, (owned) tear_down);
			_adaptors += adaptor;
			var test_case = new GLib.TestCase(adaptor.name, adaptor.set_up, adaptor.run, adaptor.tear_down);
			_suite.add(test_case);
		}

		public void add_subprocess (string test_name, owned TestFunc test) {
			Test.add_func("/" + _name + "/" + test_name, test);
		}

		public void trap (string test_name, uint64 usec_timeout, TestSubprocessFlags test_flags) {
			Test.trap_subprocess("/" + _name + "/" + test_name, usec_timeout, test_flags);
		}

		public virtual void set_up () {
		}

		public virtual void tear_down () {
		}

		private class Adaptor {
			[CCode (notify = false)]
			public string name { get; private set; }
			private TestSuite _suite;
			private TestFunc _test;
			private TestFunc? _set_up;
			private TestFunc? _tear_down;

			public Adaptor (string name, TestSuite suite, owned TestFunc test,
					owned TestFunc? set_up, owned TestFunc? tear_down) {
				_name = name;
				_suite = suite;
				_test = (owned) test;
				_set_up = (owned) set_up;
				_tear_down = (owned) tear_down;
			}

			public void set_up (void* fixture) {
				_suite.set_up();
				if (_set_up != null) _set_up();
			}

			public void run (void* fixture) {
				_test();
			}

			public void tear_down (void* fixture) {
				if (_tear_down != null) _tear_down();
				_suite.tear_down();
			}
		}

		public delegate void TestFunc ();
	}
}
