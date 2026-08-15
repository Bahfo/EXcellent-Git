import std.file;
import std.path;
import std.stdio;
import std.array;
import std.string;
import std.process;

struct Commit {
    string hash;
    string author;
    string date;
    string message;
}

struct RepositoryFile {
    string mode;
    string type;
    string hash;
    string path;
}

string escapeHTML(string input) {
    return input
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&#39;");
}

string renderLayout(string repoName, string pageTitle, string bodyHTML) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>` ~ escapeHTML(repoName) ~ ` - ` ~ escapeHTML(pageTitle) ~ `</title>
    <style>
        :root {
            --bg-main: #ffffff;
            --bg-header: #f8f9fa;
            --border-color: #dadce0;
            --text-main: #202124;
            --text-muted: #5f6368;
            --link-color: #1a73e8;
            --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
            --font-mono: "JetBrains Mono", Consolas, "Liberation Mono", monospace;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: var(--font-sans); color: var(--text-main); background: var(--bg-main); line-height: 1.5; }

        header {
            background: var(--bg-header);
            border-bottom: 1px solid var(--border-color);
            padding: 12px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        header .title { font-size: 18px; font-weight: 500; color: var(--text-main); }
        header .title a { color: inherit; text-decoration: none; }

        nav {
            display: flex;
            gap: 16px;
            padding: 12px 24px;
            border-bottom: 1px solid var(--border-color);
            background: #ffffff;
        }

        nav a {
            color: var(--text-muted);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            padding-bottom: 4px;
        }

        nav a:hover, nav a.active {
            color: var(--link-color);
            border-bottom: 2px solid var(--link-color);
        }

        main { max-width: 1200px; margin: 24px auto; padding: 0 24px; }

        .card {
            border: 1px solid var(--border-color);
            border-radius: 6px;
            overflow: hidden;
            background: #ffffff;
            margin-bottom: 24px;
        }

        .card-header {
            background: var(--bg-header);
            padding: 10px 16px;
            font-weight: 500;
            font-size: 14px;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-muted);
        }

        .card-body { padding: 16px; }

        table { width: 100%; border-collapse: collapse; font-size: 14px; }
        th, td { text-align: left; padding: 10px 16px; border-bottom: 1px solid var(--border-color); }
        th { background: var(--bg-header); color: var(--text-muted); font-weight: 500; }
        tr:last-child td { border-bottom: none; }
        tr:hover { background: #f8f9fa; }

        a { color: var(--link-color); text-decoration: none; }
        a:hover { text-decoration: underline; }

        pre, code { font-family: var(--font-mono); font-size: 13px; }
        pre { background: #f8f9fa; padding: 16px; overflow-x: auto; line-height: 1.45; }
    </style>
</head>
<body>
    <header>
        <div class="title"><a href="index.html">` ~ escapeHTML(repoName) ~ `</a></div>
    </header>
    <nav>
        <a href="index.html">Summary</a>
        <a href="files.html">Files</a>
        <a href="commits.html">Commits</a>
        <a href="stats.html">Stats & Graph</a>
    </nav>
    <main>
        ` ~ bodyHTML ~ `
    </main>
</body>
</html>`;
}

Commit[] getCommits(string repoPath) {
    auto result = execute(["git", "-C", repoPath, "log", "--pretty=format:%h|%an|%ad|%s", "--date=short"]);
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

string getFileContents(string repoPath, string filePath) {
    auto result = execute(["git", "-C", repoPath, "show", "HEAD:" ~ filePath]);
    if (result.status != 0) return "";
    return result.output;
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
        stderr.writeln("Error: '", repoPath, "' is not a valid Git repository.");
        return 1;
    }

    string repoName = baseName(repoPath);
    writeln("Targeting Git repository: ", repoName);

    string sampleBody = `<div class="card">
        <div class="card-header">Repository Status</div>
        <div class="card-body">Site template initialized for Google Git UI look.</div>
    </div>`;

    string fullHTML = renderLayout(repoName, "Summary", sampleBody);
    writeln("\nGenerated ", fullHTML.length, " bytes of layout HTML successfully.");

    return 0;
}