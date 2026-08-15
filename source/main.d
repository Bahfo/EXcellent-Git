import std.file;
import std.path;
import std.stdio;
import std.array;
import std.regex;
import std.string;
import std.process;
import std.algorithm;

// Local Imports
import structs;
import mdparser;
import html_parser;
import files;

int main(string[] args) {
    string repoPath = (args.length > 1) ? args[1] : ".";
    repoPath = buildNormalizedPath(absolutePath(repoPath));

    if (!exists(repoPath) || !isDir(repoPath)) {
        stderr.writeln(
			"Error: Path '", 
			repoPath, 
			"' does not exist or is not a directory.");
        return 1;
    }

    auto gitCheck = execute([
		"git", 
		"-C", 
		repoPath, 
		"rev-parse", 
		"--git-dir"]);
    if (gitCheck.status != 0) {
        stderr.writeln(
			"Error: '", 
			repoPath, 
			"' is not a valid Git repository.");
        return 1;
    }

    string repoName = baseName(repoPath);
    writeln("Targeting Git repository: ", repoName);

    Commit[] commits = getCommits(repoPath);
    RepositoryFile[] files = getTree(repoPath);

    string outDir = buildPath(repoPath, "public");
    mkdirRecurse(outDir);

    string indexHTML = generateIndexHTML(repoName, repoPath, commits, files);
    string indexPath = buildPath(outDir, "index.html");
    std.file.write(indexPath, indexHTML);
    writeln("Generated: ", indexPath);

    string commitsHTML = renderCommitsPage(repoName, commits);
    string commitsPath = buildPath(outDir, "commits.html");
    std.file.write(commitsPath, commitsHTML);
    writeln("Generated: ", commitsPath);

    string filesHTML = renderFilesPage(repoName, files);
    string filesPath = buildPath(outDir, "files.html");
    std.file.write(filesPath, filesHTML);
    writeln("Generated: ", filesPath);

    return 0;
}