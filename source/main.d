import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;

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
    return 0;
}