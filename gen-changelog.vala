#!/usr/bin/env vala

/*
 * A utility script to generate a changelog from git log
 *
 * example:
 * gen-changelog.vala > CHANGELOG.md
 */

const string REPOSITORY = "https://gitlab.com/kosmospredanie/gpseq";
const string LOG_FORMAT = "<< COMMIT START\n%H\n%h\n%ct\n%s\n%b\nCOMMIT END >>";
const string TIME_FORMAT = "%Y-%m-%d";
const string[] TYPES = {
	"feat", "fix", "refactor", "perf", "deps", "revert"
};

void main () {
	string[] tags = get_tags();

	StringBuilder result = new StringBuilder();
	result.append("## Changelog\n\n");
	result.append("This project adheres to Semantic Versioning.\n");
	result.append("Dates are displayed in UTC and yyyy-mm-dd date format.\n");

	for (int i = 0; i < tags.length; i++) {
		unowned string tag = tags[i];
		Commit tag_commit = new Commit();
		tag_commit.timestamp = gitlog("%ct", tag);

		string time = tag_commit.time;
		string tag_url = @"$REPOSITORY/tags/$tag";
		result.append(@"\n### [$tag]($tag_url) ($time)\n");
		if (i == tags.length-1) break;

		unowned string prev_tag = tags[i+1];
		string cmp_url = @"$REPOSITORY/compare/$prev_tag...$tag";
		result.append(@"\n[Full Changelog]($cmp_url)\n\n");

		Commit[] commits = get_commits(@"$prev_tag..$tag");
		foreach (unowned Commit commit in commits) {
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

string[] get_tags () {
	string[] tags = cmd("git --no-pager tag --sort=committerdate").split("\n");
	reverse(tags);
	return tags;
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

void reverse (string[] array) {
	int start = 0;
	int end = array.length - 1;
	while (start < end) {
		string temp = array[start];
		array[start] = array[end];
		array[end] = temp;
		start++;
		end--;
	}
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

[Compact]
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
