module structs;

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

struct CommitInfo {
    string hash;
    string author;
    string date;
    string message;
}

struct FileItem {
    string name;
    string path;
    bool isDir;
    string size;
    string lastCommitMsg;
    string lastUpdated;
}