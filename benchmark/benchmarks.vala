/* benchmarks.vala - A single-file benchmark utility
 *
 * deps:
 *  * glib-2.0
 *  * gobject-2.0
 *  * gio-2.0
 *
 * Written in 2019 by Космическое П. (kosmospredanie@yandex.ru)
 *
 * To the extent possible under law, the author have dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 *
 * You should have received a copy of the CC0 legalcode along with this
 * work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

namespace Benchmarks {
	/* public methods */

	public Results benchmark (int iteration, Func<Reporter> setup) {
		assert(iteration >= 0);
		ResultsImpl results = new ResultsImpl();
		for (int i = 0; i < iteration; i++) {
			ReporterImpl reporter = new ReporterImpl(i);
			setup(reporter);
			reporter.run();
			if (!reporter.is_warming_up) results.add(reporter);
		}
		return results;
	}

	/* definitions */
	
	public interface Results : Object {
		public abstract int size { get; }
		public abstract Group get (int idx);
		public abstract Results print ();
		public abstract Results print_last ();
		public abstract string to_data (bool columnheader = true);
		public abstract void save_data (string filename, bool columnheader = true);
	}

	public interface Reporter : Object {
		public abstract void report (owned string label, owned Func<Stopwatch> job);
		public abstract void group (owned string label, Func<Reporter> setup);
		public abstract int current_iteration { get; }
		public abstract void set_xval (string xval);
		public abstract void mark_warming_up ();
	}

	public interface Stopwatch : Object {
		public abstract void start ();
		public abstract void stop ();
		public abstract void notate (owned string note);
	}

	public interface Group : Object {
		public abstract string label { get; }
		public abstract string xval { get; }
		public abstract Group? parent { get; }
		public abstract bool has_report (string label);
		public abstract bool has_group (string label);
		public abstract Report get_report (string label);
		public abstract Group get_group (string label);
		public abstract Report[] get_reports ();
		public abstract Group[] get_groups ();
		public abstract GenericArray<Report> get_sorted_reports ();
		public abstract Group print (uint depth = 0);
	}

	public interface Report : Object {
		public abstract string label { get; }
		public abstract double monotonic_time { get; }
		public abstract double real_time { get; }
		public abstract string note { get; }
	}

	/* implementations */

	private class ResultsImpl : Object, Results {
		private const char SEPARATOR = ' ';
		
		private ReporterImpl[] _results;
		
		public ResultsImpl () {
			_results = {};
		}
		
		public int size {
			get {
				return _results.length;
			}
		}
		
		public new Group get (int idx) {
			return _results[idx];
		}
		
		public Results print () {
			if (size == 1) {
				_results[0].print(0);
			} else if (size > 0) {
				for (int i = 0; i < _results.length; i++) {
					GLib.print("Iteration #%d\n", i);
					_results[i].print(1);
				}
			}
			return this;
		}
		
		public Results print_last () {
			if (_results.length > 0) {
				_results[_results.length - 1].print(0);
			}
			return this;
		}
		
		public void add (ReporterImpl result) {
			_results += result;
		}
		
		public string to_data (bool columnheader) {
			StringBuilder buf = new StringBuilder();
			for (int i = 0; i < _results.length; i++) {
				Group result = _results[i];
				Report[] reports = result.get_reports();
				if (i == 0 && columnheader && reports.length > 0) {
					if (result.xval.length > 0) {
						buf.append_c('.');
						buf.append_c(SEPARATOR);
					}
					for (int j = 0; j < reports.length; j++) {
						buf.append_c('"');
						buf.append(reports[j].label);
						buf.append_c('"');
						buf.append_c(SEPARATOR);
					}
					buf.append_c('\n');
				}
				if (result.xval.length > 0) {
					buf.append(result.xval);
					buf.append_c(SEPARATOR);
				}
				for (int j = 0; j < reports.length; j++) {
					buf.append_printf("%f%c", reports[j].real_time, SEPARATOR);
				}
				buf.append_c('\n');
			}
			return buf.str;
		}
		
		public void save_data (string filename, bool columnheader) {
			File file = File.new_for_path(filename);
			try {
				FileOutputStream fstream = file.replace(null, false, FileCreateFlags.NONE);
				DataOutputStream stream = new DataOutputStream(fstream);
				string data = to_data(columnheader);
				stream.put_string(data);
			} catch (Error err) {
				error("An error occurs while saving data: " + err.message);
			}
		}
	}

	private class ReporterImpl : Object, Reporter, Group {
		private const int DECIMAL_PLACES = 6;
		private const string ROOT_GROUP_NAME = "root";
		private const string HEADER_INDENT = " - ";
		private const string INDENT = "   ";
		private const string XVAL_PREFIX = "[";
		private const string XVAL_SUFFIX = "]";
		private const string GROUP_SUFFIX = ")";
		private const string LABEL_SUFFIX = ":";
		private const string LABEL_TOTAL = "*total";
		private const string LABEL_AVG = "*avg";
		private const string TIME_SUFFIX = "s";
		private const string MONOTONIC_TIME_TITLE = "monotonic";
		private const string REAL_TIME_TITLE = "real";

		private GenericArray<ReportImpl> _reports;
		private HashTable<string,int> _report_names; // <name, index>
		private GenericArray<ReporterImpl> _children;
		private HashTable<string,int> _child_names; // <name, index>

		private string _label;
		private string _xval;
		private unowned ReporterImpl? _parent;
		private int _current_iteration;
		private bool _is_warming_up;

		public ReporterImpl (int current_iteration = 0, owned string? label = null, ReporterImpl? parent = null) {
			_label = label == null ? ROOT_GROUP_NAME : ((owned) label);
			_xval = "";
			_parent = parent;
			_current_iteration = current_iteration;
			_reports = new GenericArray<ReportImpl>();
			_report_names = new HashTable<string,int>(str_hash, str_equal);
			_children = new GenericArray<ReporterImpl>();
			_child_names = new HashTable<string,int>(str_hash, str_equal);
		}

		public void report (owned string label, owned Func<Stopwatch> job) {
			if (label in _report_names) {
				error(@"Duplicated report name '$label'");
			}
			int idx = _reports.length;
			_report_names[label] = idx;
			var report = new ReportImpl((owned) label, (owned) job);
			_reports.add(report);
		}

		public void group (owned string label, Func<Reporter> setup) {
			if (label in _child_names) {
				error(@"Duplicated group name '$label'");
			}
			int idx = _children.length;
			_child_names[label] = idx;
			var child = new ReporterImpl(current_iteration, (owned) label, this);
			_children.add(child);
			setup(child);
		}

		public int current_iteration {
			get {
				return _current_iteration;
			}
		}

		public string label {
			get {
				return _label;
			}
		}
		
		public string xval {
			get {
				return _xval;
			}
		}
		
		public void set_xval (string xval) {
			_xval = xval;
		}
		
		public bool is_warming_up {
			get {
				return _is_warming_up;
			}
		}
		
		public void mark_warming_up () {
			_is_warming_up = true;
		}

		public Group? parent {
			get {
				return _parent;
			}
		}

		public uint num_total_reports {
			get {
				uint len = _reports.length;
				_children.foreach(g => len += g.num_total_reports);
				return len;
			}
		}

		public bool has_report (string label) {
			return _report_names.contains(label);
		}

		public bool has_group (string label) {
			return _child_names.contains(label);
		}

		public Report get_report (string label) {
			if (label in _report_names) {
				error(@"Report '$label' not found");
			}
			return _reports[_report_names[label]];
		}

		public Group get_group (string label) {
			if (label in _child_names) {
				error(@"Group '$label' not found");
			}
			return _children[_child_names[label]];
		}

		public Report[] get_reports () {
			Report[] array = new Report[_reports.length];
			for (int i = 0, n = array.length; i < n; i++) {
				array[i] = _reports[i];
			}
			return array;
		}

		public Group[] get_groups () {
			Group[] array = new Group[_children.length];
			for (int i = 0, n = array.length; i < n; i++) {
				array[i] = _children[i];
			}
			return array;
		}

		public void run () {
			_reports.foreach(g => g.measure());
			_children.foreach(g => g.run());
		}

		public Group print (uint depth = 0) {
			uint len = _reports.length;
			if (len == 0) {
				GLib.print("%s%s\n", header_indent(depth), _label + GROUP_SUFFIX);
			} else {
				var sorted_reports = get_sorted_reports();
				double fastest = sorted_reports[0].real_time;

				string group_label = _label + (_xval.length > 0 ? XVAL_PREFIX + _xval + XVAL_SUFFIX : "") + GROUP_SUFFIX;
				string total_label = LABEL_TOTAL + LABEL_SUFFIX;
				string avg_label = LABEL_AVG + LABEL_SUFFIX;

				int label_width = group_label.length + (_xval.length > 0 ? _xval.length + XVAL_PREFIX.length + XVAL_SUFFIX.length : 0);
				label_width = int.max(label_width, total_label.length);
				label_width = int.max(label_width, avg_label.length);

				int time_width = MONOTONIC_TIME_TITLE.length;
				time_width = int.max(time_width, REAL_TIME_TITLE.length);
				string time_format = @"%.$(DECIMAL_PLACES)f$(TIME_SUFFIX)";
				double m_total = 0;
				double r_total = 0;
				sorted_reports.foreach(report => {
					int lw = report.label.length + LABEL_SUFFIX.length;
					int mw = time_format.printf(report.monotonic_time).length;
					int rw = time_format.printf(report.real_time).length;
					if (label_width < lw) label_width = lw;
					if (time_width < mw) time_width = mw;
					if (time_width < rw) time_width = rw;
					m_total += report.monotonic_time;
					r_total += report.real_time;
				});
				int mw = time_format.printf(m_total).length;
				int rw = time_format.printf(r_total).length;
				if (time_width < mw) time_width = mw;
				if (time_width < rw) time_width = rw;

				string hidt = header_indent(depth);
				string header_format = @"$(hidt)%-$(label_width)s   %$(time_width)s   %$(time_width)s\n";
				GLib.print(header_format, group_label, MONOTONIC_TIME_TITLE, REAL_TIME_TITLE);

				string idt = indent(depth);
				string body_format = @"$(idt)%-$(label_width)s   $(time_format)   $(time_format)%s%s\n";
				sorted_reports.foreach(report => {
					string multiple = fastest == report.real_time || fastest == 0 ? "" : "   %.2fx slower".printf(report.real_time / fastest);
					string note = report.note.length == 0 ? "" : "   " + report.note;
					GLib.print(body_format, report.label + LABEL_SUFFIX, report.monotonic_time, report.real_time, multiple, note);
				});

				GLib.print(body_format, total_label, m_total, r_total, "", "");
				double m_avg = m_total / len;
				double r_avg = r_total / len;
				GLib.print(body_format, avg_label, m_avg, r_avg, "", "");
			}
			_children.foreach(g => g.print(depth + 1));
			return this;
		}

		private string header_indent (uint depth) {
			StringBuilder buf = new StringBuilder();
			for (uint i = 0; i < depth; i++) {
				buf.append(HEADER_INDENT);
			}
			return buf.str;
		}

		private string indent (uint depth) {
			StringBuilder buf = new StringBuilder();
			for (uint i = 0; i < depth; i++) {
				buf.append(INDENT);
			}
			return buf.str;
		}

		public GenericArray<Report> get_sorted_reports () {
			var result = new GenericArray<Report>(_reports.length);
			for (int i = 0; i < _reports.length; i++) {
				result.add(_reports[i]);
			}
			result.sort_with_data((a, b) => {
				double ta = a.real_time;
				double tb = b.real_time;
				return ta < tb ? -1 : (ta == tb ? 0 : 1);
			});
			return result;
		}
	}

	private class ReportImpl : Object, Report {
		private string _label;
		private Func<Stopwatch> _job;
		private StopwatchImpl? _stopwatch;

		public ReportImpl (owned string label, owned Func<Stopwatch> job) {
			_label = (owned) label;
			_job = (owned) job;
		}

		public string label {
			get {
				return _label;
			}
		}

		public StopwatchImpl stopwatch {
			get {
				assert_nonnull(_stopwatch);
				return _stopwatch;
			}
		}

		public double monotonic_time {
			get {
				return _stopwatch.monotonic_time;
			}
		}

		public double real_time {
			get {
				return _stopwatch.real_time;
			}
		}

		public string note {
			get {
				return _stopwatch.note;
			}
		}

		public void measure () {
			_stopwatch = new StopwatchImpl();
			_stopwatch.start();
			_job(_stopwatch);
			if (!_stopwatch.is_stopped) _stopwatch.stop();
		}
	}

	private class StopwatchImpl : Object, Stopwatch {
		private double _monotonic_time;
		private double _real_time;
		private bool _started;
		private bool _stopped;
		private string _note = "";

		public double monotonic_time {
			get {
				assert(_stopped);
				return _monotonic_time;
			}
		}

		public double real_time {
			get {
				assert(_stopped);
				return _real_time;
			}
		}

		public bool is_stopped {
			get {
				return _stopped;
			}
		}

		public void start () {
			assert(!_stopped);
			_started = true;
			_monotonic_time = get_monotonic_time();
			_real_time = get_real_time();
		}

		public void stop () {
			assert(_started);
			assert(!_stopped);
			_stopped = true;
			_monotonic_time = (get_monotonic_time() - _monotonic_time) / 1000000.0;
			_real_time = (get_real_time() - _real_time) / 1000000.0;
		}

		public void notate (owned string note) {
			_note = (owned) note;
		}

		public string note {
			get {
				return _note;
			}
		}
	}
}
