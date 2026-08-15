module html_parser;

import std.algorithm;
import std.array;
import std.format;
import std.string;

// Local Imports
import files;
import structs;
import mdparser;

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
        body { font-family: var(--font-sans); 
            color: var(--text-main); 
            background: var(--bg-main); 
            line-height: 1.5; }

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

		.markdown-body h1, .markdown-body h2, .markdown-body h3, 
        .markdown-body h4, .markdown-body h5, .markdown-body h6 {
            margin-top: 20px;
            margin-bottom: 8px;
            font-weight: 600;
            line-height: 1.25;
        }
        .markdown-body h1 { font-size: 24px; border-bottom: 1px solid var(--border-color); padding-bottom: 6px; }
        .markdown-body h2 { font-size: 20px; border-bottom: 1px solid var(--border-color); padding-bottom: 4px; }
        .markdown-body h3 { font-size: 16px; }
        .markdown-body h4 { font-size: 14px; }
        .markdown-body h5 { font-size: 13px; }
        .markdown-body h6 { font-size: 12px; color: var(--text-muted); }

        .markdown-body p { margin-bottom: 12px; }
        .markdown-body img { max-width: 100%; height: auto; vertical-align: middle; margin: 2px 0; }
        .markdown-body hr { border: 0; border-top: 1px solid var(--border-color); margin: 24px 0; }

        /* GitHub Callout / Alert Styling */
        .callout {
            border-left: 4px solid var(--link-color);
            background: #f8f9fa;
            padding: 12px 16px;
            margin: 16px 0;
            border-radius: 0 4px 4px 0;
            font-size: 13px;
        }
        .callout-title { font-weight: 600; margin-bottom: 4px; }
        .callout-tip { border-left-color: #1a73e8; background: #e8f0fe; }
        .callout-important { border-left-color: #d93025; background: #fce8e6; }
        .callout-warning { border-left-color: #f2990a; background: #fef7e0; }
        .callout-note { border-left-color: #5f6368; background: #f1f3f4; }
		}

        .commits-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-top: 16px;
        }
        .commit-item {
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 12px 16px;
            background: var(--bg-secondary);
        }
        .commit-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }
        .commit-msg {
            font-weight: 600;
            font-size: 14px;
            color: var(--text-primary);
        }
        .commit-hash code {
            background: var(--bg-muted);
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 12px;
            font-family: monospace;
        }
        .commit-meta {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 6px;
        }

        .files-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
            font-size: 13px;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            overflow: hidden;
        }
        .files-table th, .files-table td {
            padding: 10px 14px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        .files-table th {
            background: var(--bg-muted);
            font-weight: 600;
        }
        .files-table tr:last-child td {
            border-bottom: none;
        }
        .file-name {
            font-weight: 500;
        }
        .file-icon {
            margin-right: 6px;
        }
        .file-commit {
            color: var(--text-muted);
            max-width: 280px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .file-size, .file-date {
            font-size: 12px;
            color: var(--text-muted);
            white-space: nowrap;
        }
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


string generateIndexHTML(
        string repoName, 
        string repoPath, 
        Commit[] commits, 
        RepositoryFile[] files
    ) {

	string body = "";
    body ~= `<div class="card">
        <div class="card-header">Repository Overview</div>
        <div class="card-body">
            <div class="stat-grid">
                <div class="stat-box">
                    <div style="color: var(--text-muted); font-size: 12px;">Total Commits</div>
                    <div class="stat-val">` ~ format("%d", commits.length) ~ `</div>
                </div>
                <div class="stat-box">
                    <div style="color: var(--text-muted); font-size: 12px;">Files in HEAD</div>
                    <div class="stat-val">` ~ format("%d", files.length) ~ `</div>
                </div>
            </div>
        </div>
    </div>`;

    body ~= `<div class="card">
        <div class="card-header">Recent Commits</div>
        <table>
            <thead>
                <tr>
                    <th>Commit</th>
                    <th>Description</th>
                    <th>Author</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>`;

    size_t recentCount = min(commits.length, 5);
    for (size_t i = 0; i < recentCount; i++) {
        auto c = commits[i];
        body ~= `<tr>
            <td class="hash">` ~ escapeHTML(c.hash) ~ `</td>
            <td>` ~ escapeHTML(c.message) ~ `</td>
            <td>` ~ escapeHTML(c.author) ~ `</td>
            <td style="color: var(--text-muted);">` ~ escapeHTML(c.date) ~ `</td>
        </tr>`;
    }

    body ~= `</tbody></table></div>`;

    foreach (f; files) {
        if (f.path.toLower == "readme.md" || f.path.toLower == "readme") {
            string readmeText = getFileContents(repoPath, f.path);
            body ~= `<div class="card">
                <div class="card-header">` ~ escapeHTML(f.path) ~ `</div>
                <div class="card-body markdown-body">`
                    ~ markdownToHTML(readmeText) ~ 
                `</div>
            </div>`;
            break;
        }
    }

    return renderLayout(repoName, "Summary", body);
}

string renderCommitsPage(string repoName, Commit[] commits) {
    string body = `<div class="card">
        <div class="card-header">Commits</div>
        <table>
            <thead>
                <tr>
                    <th>Commit</th>
                    <th>Description</th>
                    <th>Author</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>`;

    foreach (c; commits) {
        body ~= `<tr>
            <td class="hash">` ~ escapeHTML(c.hash) ~ `</td>
            <td>` ~ escapeHTML(c.message) ~ `</td>
            <td>` ~ escapeHTML(c.author) ~ `</td>
            <td style="color: var(--text-muted);">` ~ escapeHTML(c.date) ~ `</td>
        </tr>`;
    }

    body ~= `</tbody></table></div>`;

    return renderLayout(repoName, "Commits", body);
}

string renderFilesPage(string repoName, RepositoryFile[] files) {
    string body = `<div class="card">
        <div class="card-header">Files</div>
        <table>
            <thead>
                <tr>
                    <th>Path</th>
                    <th>Type</th>
                    <th>Mode</th>
                </tr>
            </thead>
            <tbody>`;

    foreach (f; files) {
        body ~= `<tr>
            <td>` ~ escapeHTML(f.path) ~ `</td>
            <td>` ~ escapeHTML(f.type) ~ `</td>
            <td style="color: var(--text-muted);">` ~ escapeHTML(f.mode) ~ `</td>
        </tr>`;
    }

    body ~= `</tbody></table></div>`;

    return renderLayout(repoName, "Files", body);
}

string renderCommitsPage(CommitInfo[] commits) {
    auto app = appender!string();
    app.put(`<div class="page-header"><h2>Commit History</h2></div>` ~ "\n");
    app.put(`<div class="commits-list">` ~ "\n");
    
    foreach (c; commits) {
        string shortHash = c.hash.length >= 7 ? c.hash[0 .. 7] : c.hash;
        app.put(format(`
        <div class="commit-item">
            <div class="commit-header">
                <span class="commit-msg">%s</span>
                <span class="commit-hash"><code>%s</code></span>
            </div>
            <div class="commit-meta">
                <strong>%s</strong> committed on <span>%s</span>
            </div>
        </div>
        `, c.message, shortHash, c.author, c.date));
    }
    
    app.put(`</div>` ~ "\n");
    return app.data;
}

string renderFilesPage(FileItem[] files) {
    auto app = appender!string();
    app.put(`<div class="page-header"><h2>Repository Files</h2></div>` ~ "\n");
    app.put(`<table class="files-table">` ~ "\n");
    app.put(`  <thead>
    <tr>
      <th>Name</th>
      <th>Last Commit</th>
      <th>Size</th>
      <th>Updated</th>
    </tr>
  </thead>` ~ "\n");
    app.put(`  <tbody>` ~ "\n");

    foreach (f; files) {
        string icon = f.isDir ? "📁" : "📄";
        app.put(format(`    <tr>
      <td class="file-name"><span class="file-icon">%s</span> <a href="%s">%s</a></td>
      <td class="file-commit">%s</td>
      <td class="file-size">%s</td>
      <td class="file-date">%s</td>
    </tr>
`, icon, f.path, f.name, f.lastCommitMsg, f.isDir ? "-" : f.size, f.lastUpdated));
    }

    app.put(`  </tbody>` ~ "\n");
    app.put(`</table>` ~ "\n");
    return app.data;
}