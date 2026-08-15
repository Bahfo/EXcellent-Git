module mdparser;

import std.conv;
import std.regex;
import std.array;
import std.string;
import std.algorithm;

// Local Imports
import html_parser;

string markdownToHTML(string input) {
    string[] lines = input.splitLines();
    string result = "";
    bool inCodeBlock = false;
    bool inList = false;
    bool inCallout = false;

    auto reImg      = regex(`!\[(.*?)\]\((.*?)\)`);
    auto reLink     = regex(`\[(.*?)\]\((.*?)\)`);
    auto reAutoLink = regex(`(?<!["'=])(https?://[^\s<]+)`);
    auto reBold     = regex(`(\*\*|__)(.*?)\1`);
    auto reItalic   = regex(`(\*|_)(.*?)\1`);
    auto reCode     = regex("`(.*?)`");

    string processInline(string text) {
        string s = escapeHTML(text);
        s = s.replaceAll(reImg, `<img src="$2" alt="$1">`);
        s = s.replaceAll(reLink, `<a href="$2" target="_blank">$1</a>`);
        s = s.replaceAll(reAutoLink, `<a href="$1" target="_blank">$1</a>`);
        s = s.replaceAll(reBold, `<strong>$2</strong>`);
        s = s.replaceAll(reItalic, `<em>$2</em>`);
        s = s.replaceAll(reCode, `<code>$1</code>`);
        return s;
    }

    foreach (line; lines) {
        string trimmed = line.strip();

        if (trimmed.startsWith("```")) {
            if (inCodeBlock) {
                result ~= "</code></pre>\n";
                inCodeBlock = false;
            } else {
                if (inList) { result ~= "</ul>\n"; inList = false; }
                if (inCallout) { result ~= "</div>\n"; inCallout = false; }
                
                string lang = trimmed[3..$].strip();
                if (lang.length > 0) {
                    result ~= "<pre><code class=\"language-" ~ escapeHTML(lang) ~ "\">";
                } else {
                    result ~= "<pre><code>";
                }
                inCodeBlock = true;
            }
            continue;
        }

        if (inCodeBlock) {
            result ~= escapeHTML(line) ~ "\n";
            continue;
        }

        if (inList && !trimmed.startsWith("- ") && !trimmed.startsWith("* ")) {
            result ~= "</ul>\n";
            inList = false;
        }

        if (inCallout && !trimmed.startsWith(">")) {
            result ~= "</div>\n";
            inCallout = false;
        }

        if (trimmed.empty) continue;

        if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
            result ~= "<hr>\n";
            continue;
        }

        if (trimmed.startsWith("<") && (trimmed.endsWith(">") || trimmed.canFind(">"))) {
            result ~= line ~ "\n";
            continue;
        }

        if (trimmed.startsWith("#")) {
            size_t level = 0;
            while (level < trimmed.length && trimmed[level] == '#') level++;
            
            if (level >= 1 && level <= 6 && level < trimmed.length && trimmed[level] == ' ') {
                string headerText = processInline(trimmed[level + 1 .. $]);
                result ~= format("<h%d>%s</h%d>\n", level, headerText, level);
                continue;
            }
        }

        if (trimmed.startsWith(">")) {
            string qText = trimmed[1..$].strip();
            
            if (qText.startsWith("[!") && qText.canFind("]")) {
                ptrdiff_t endIdx = qText.indexOf("]");
                string alertType = qText[2..endIdx].toLower();
                
                result ~= format(
                    "<div class=\"callout callout-%s\">\n  <div class=\"callout-title\">%s</div>\n  ", 
                    alertType, alertType.toUpper()
                );
                
                string calloutBody = qText[endIdx + 1 .. $].strip();
                if (!calloutBody.empty) {
                    result ~= processInline(calloutBody) ~ "<br>\n";
                }
                inCallout = true;
                continue;
            }

            if (inCallout) {
                result ~= processInline(qText) ~ "<br>\n";
            } else {
                result ~= "<blockquote>" ~ processInline(qText) ~ "</blockquote>\n";
            }
            continue;
        }

        if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
            if (!inList) {
                result ~= "<ul>\n";
                inList = true;
            }
            result ~= "  <li>" ~ processInline(trimmed[2..$]) ~ "</li>\n";
            continue;
        }

        result ~= "<p>" ~ processInline(line) ~ "</p>\n";
    }

    if (inList) result ~= "</ul>\n";
    if (inCallout) result ~= "</div>\n";
    if (inCodeBlock) result ~= "</code></pre>\n";

    return result;
}