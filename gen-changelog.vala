#!/usr/bin/env vala

/*
 * gen-changelog.vala - A utility script to generate a changelog from git log
 *
 * Written in 2019-2020 by Космическое П. (kosmospredanie@yandex.ru)
 *
 * To the extent possible under law, the author have dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 *
 * You should have received a copy of the CC0 legalcode along with this
 * work. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 *
 * example:
 *   gen-changelog.vala > CHANGELOG.md
 */

const string REPOSITORY = "https://gitlab.com/kosmospredanie/gpseq";
// Commit types to be included in changelog
const string[] TYPES = {
	"feat", "fix", "refactor", "perf", "deps", "revert"
};

const string LOG_FORMAT = "<< COMMIT START\n%H\n%h\n%ct\n%s\n%b\nCOMMIT END >>";
const string TIME_FORMAT = "%Y-%m-%d";
const string VERSION_PATTERN = "(\\d+).(\\d+).(\\d+)(-[\\w.-]+)?(\\+[\\w.-]+)? \\(([^)]+)\\)";
const string TAG_CMD="git --no-pager tag -l --format='%(refname:short) (%(creatordate:unix))' --sort=committerdate";

void main () {
	Version[] versions = get_versions();

	StringBuilder result = new StringBuilder();
	result.append("## Changelog\n\n");
	result.append("This project adheres to Semantic Versioning.\n");
	result.append("Dates are displayed in UTC and yyyy-mm-dd date format.\n");

	for (int i = 0; i < versions.length; ++i) {
		Version version = versions[i];
		string name = version.name;

		string time = version.date_str;
		string tag_url = @"$REPOSITORY/tags/$name";
		result.append(@"\n### [$name]($tag_url) ($time)\n");
		if (i == versions.length-1) break;

		Version prev = find_prev_version(i, versions);
		string prev_name = prev.name;
		string cmp_url = @"$REPOSITORY/compare/$prev_name...$name";
		result.append(@"\n[Full Changelog]($cmp_url)\n\n");

		Commit[] commits = get_commits(@"$prev_name..$name");
		foreach (Commit commit in commits) {
			string type = commit.commit_type;
			if (type.length == 0 || type in TYPES || commit.is_breaking_change) {
				string abbrev = commit.abbrev_hash;
				string url = @"$REPOSITORY/commit/$(commit.hash)";
				string breaks = commit.is_breaking_change ? "**!!** " : "";
				result.append(@"- $breaks$(commit.subject) [[$abbrev]]($url)");
				int[] issues = commit.issues;
				foreach (int issue in issues) {
					string issue_url = @"$REPOSITORY/issues/$issue";
					result.append(@" [#$issue]($issue_url)");
				}
				result.append("\n");
			}
		}
	}
	print("%s", result.str);
}

Version[] get_versions () {
	string[] tags = cmd(TAG_CMD).split("\n");
	Version[] versions = new Version[tags.length];
	for (int i = 0; i < tags.length; ++i) {
		versions[i] = parse_version( match(VERSION_PATTERN, tags[i]) );
	}
	sort_versions(versions);
	reverse(versions);
	return versions;
}

void sort_versions (Version[] versions) {
	qsort_with_data<Version>(versions, sizeof(Version), (a, b) => {
		return compare({
			a.major-b.major, a.minor-b.minor, a.patch-b.patch,
			(a.pre != "" && b.pre == "") ? -1 :
			(a.pre == "" && b.pre == "") ? 0 :
			(a.pre == "" && b.pre != "") ? 1 :
			strcmp(a.pre, b.pre)
		});
	});
}

Version parse_version (MatchInfo m) {
	Version ver = new Version();
	ver.major = int.parse( m.fetch(1) );
	ver.minor = int.parse( m.fetch(2) );
	ver.patch = int.parse( m.fetch(3) );
	ver.pre = m.fetch(4) ?? "";
	ver.meta = m.fetch(5) ?? "";
	ver.date = new DateTime.from_unix_utc( int64.parse(m.fetch(6)) );
	return ver;
}

int compare (int[] args) {
	for (int i = 0; i < args.length; ++i) {
		if (args[i] != 0) {
			return args[i].clamp(-1, 1);
		}
	}
	return 0;
}

void reverse (Version[] array) {
	int start = 0;
	int end = array.length - 1;
	while (start < end) {
		Version temp = (owned) array[start];
		array[start] = (owned) array[end];
		array[end] = (owned) temp;
		start++;
		end--;
	}
}

Version find_prev_version (int idx, Version[] list) {
	Version cur = list[idx];
	for (int i = idx + 1; i < list.length; ++i) {
		Version ver = list[i];
		if ( ver.date.compare(cur.date) <= 0 ) {
			return ver;
		}
	}
	error("Previous version of %s not found", cur.name);
}

Commit[] get_commits (string range) {
	Commit[] list = {};
	string log = gitlog_all(LOG_FORMAT, range);
	var m = match("^<< COMMIT START$\n((?:.|\n)*?)\n^COMMIT END >>$", log);
	if (!m.matches()) return list;
	try {
		do {
			list += parse_commit( m.fetch(1) );
		} while (m.next());
	} catch (RegexError e) {
		error(e.message);
	}
	return list;
}

Commit parse_commit (string text) {
	string[] tokens = text.split("\n", 5);
	Commit commit = new Commit();
	commit.hash = (owned) tokens[0];
	commit.abbrev_hash = (owned) tokens[1];
	commit.timestamp = (owned) tokens[2];
	commit.subject = (owned) tokens[3];
	commit.body = (owned) tokens[4];
	return commit;
}

MatchInfo match (string pattern, string str) {
	Regex regex;
	try {
		regex = new Regex(pattern, RegexCompileFlags.MULTILINE);
	} catch (RegexError e) {
		error(e.message);
	}
	MatchInfo m;
	regex.match(str, 0, out m);
	return (owned)m;
}

string gitlog (string format, string range) {
	return cmd("git --no-pager log -1 --no-merges --format='%s' %s".printf(format, range));
}

string gitlog_all (string format, string range) {
	return cmd("git --no-pager log --no-merges --format='%s' %s".printf(format, range));
}

string cmd (string cmd) {
	try {
		string output;
		Process.spawn_command_line_sync(cmd, out output);
		return output.strip();
	} catch (SpawnError e) {
		error(e.message);
	}
}

class Commit {
	public string hash;
	public string abbrev_hash;
	public string timestamp;
	public string subject;
	public string body;

	public string time {
		owned get {
			DateTime time = new DateTime.from_unix_utc(int64.parse(timestamp));
			return time.format(TIME_FORMAT);
		}
	}

	public string commit_type {
		owned get {
			string str = subject;
			var m = match("^(.+?):", str);
			if (m.matches()) {
				return m.fetch(1);
			} else {
				return "";
			}
		}
	}

	public bool is_breaking_change {
		get {
			return match("^BREAKING CHANGE", body).matches();
		}
	}

	public int[] issues {
		owned get {
			int[] list = {};
			string str = subject + "\n" + body;
			var m = match("#(\\d+)", str);
			if (!m.matches()) return list;
			try {
				do {
					list += int.parse(m.fetch(1));
				} while (m.next());
			} catch (RegexError e) {
				error(e.message);
			}
			return list;
		}
	}
}

class Version {
	public int major;
	public int minor;
	public int patch;
	public string pre;
	public string meta;
	public DateTime date;

	public string name {
		owned get {
			return @"$major.$minor.$patch$pre$meta";
		}
	}

	public string date_str {
		owned get {
			return date.format(TIME_FORMAT);
		}
	}
}
