# EXcellent Git: A Simple Git Viewer Written in Dlang

![Main Language](https://img.shields.io/badge/Main_Language-D-BA3925?style=for-the-badge&logo=d&logoColor=white)
![Author](https://img.shields.io/badge/Author-Bahaa_Nofal-CBA317?style=for-the-badge)

## Introduction

EXcellent-Git aims to add simple way of featuring the repository as a static `HTML` source. It uses the `git` CLI commands to parse and generate a suitable static HTML pages suitable to the repository. It is also able to parse markdown files cleanly like in GitHub. 

## Building the Source Code

By using dub, you can easily build the source code: 

```bash
dub build
```

Then, use `./excellentgit` to generate the files inside a folder called (/public). You have one of two options: 

```bash
./excellentgit /path/to/your/repository # Guiding EXcellent Git to your repository
./excellentgit . # Or in cwd
```

## License
This project is licensed under GPLv3. Read LICENSE for more info.