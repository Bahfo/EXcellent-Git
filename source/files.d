module files;

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

Commit[] getCommits(string repoPath) {
    auto result = execute([
		"git", 
		"-C", 
		repoPath, 
		"log", 
		"--pretty=format:%h|%an|%ad|%s", 
		"--date=short"
	]);
    if (result.status != 0) return [];

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
    auto result = execute([
		"git", 
		"-C", 
		repoPath, 
		"ls-tree", 
		"-r", 
		"HEAD"
	]);
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
            files ~= RepositoryFile(
				metaParts[0], 
				metaParts[1], 
				metaParts[2], 
				filePath
			);
        }
    }
    return files;
}

string getFileContents(string repoPath, string filePath) {
    auto result = execute([
		"git", 
		"-C", 
		repoPath, 
		"show", 
		"HEAD:" ~ filePath]);
    if (result.status != 0) return "";
    return result.output;
}