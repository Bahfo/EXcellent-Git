import std.file;
import std.path;
import std.stdio;
import std.array;
import std.string;
import std.process;

struct Commit {
	string hash;
	string date;
	string author;
	string message;
}

struct RepositoryFile {
	string mode;
	string type;
	string hash;
	string path;
}

Commit[] getCommits(string repoPath) {
	auto result = execute([
		"git",
		"-C",
		repoPath,
		"log",
		"--pretty=format:%h|%an|%ad|%s",
		"--date=short"
	]);

	if (result.status != 0) {
		return [];
	}

	Commit[] commits;
	foreach (line; result.output.splitLines()) {
		if (line.empty) continue;

		auto parts = line.split("|");
		if (parts.length >= 4) {
			string msg = parts[3..$].join("|");
			commits ~= Commit(parts[0], parts[1], parts[2], msg);
		}
	}

	return commits;
}

RepositoryFile[] getTree(string repoPath) {
	auto result = execute(["git", "-C", repoPath, "ls-tree", "-r", "HEAD"]);
	if (result.status != 0) return [];

	RepositoryFile[] files;
	foreach (line; result.output.splitLines()) {
		if (line.empty) continue;

		auto tabParts = line.split("\t");
		if (tabParts.length < 2) continue;

		string meta = tabParts[0];
		string filePath = tabParts[1..$].join("\t");

		auto metaParts = meta.split(" ");
		if (metaParts.length == 3) {
			files ~= RepositoryFile(metaParts[0], metaParts[1], metaParts[2], filePath);
		}
	}

	return files;
}

int main(string[] args) {
    string repoPath = (args.length > 1) ? args[1] : ".";
    repoPath = buildNormalizedPath(absolutePath(repoPath));

    if (!exists(repoPath) || !isDir(repoPath)) {
        stderr.writeln("Error: Path '", repoPath, "' does not exist or is not a directory.");
        return 1;
    }

    auto gitCheck = execute(["git", "-C", repoPath, "rev-parse", "--git-dir"]);

    if (gitCheck.status != 0) {
        stderr.writeln("Error: '", repoPath, "' is not recognized as a valid Git repository by git.");
        stderr.writeln("Git Exit Code: ", gitCheck.status);
        stderr.writeln("Git Output: ", gitCheck.output.strip());
        return 1;
    }

    writeln("Targeting Git repository: ", repoPath);

	Commit[] commits = getCommits(repoPath);
	writeln("Fetched ", commits.length, " commit(s).\n");

	RepositoryFile[] files =getTree(repoPath);
	writeln("Fetched ", files.length, " file(s) from HEAD.\n");

	foreach (f; files)
		writeln(f.type, " ", f.type, " ", f.path, " ", f.hash[0..7]);

    return 0;
}