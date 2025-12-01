# zio

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Zig 0.15.2+](https://img.shields.io/badge/zig-0.15.2%2B-brightgreen.svg)](https://ziglang.org)

> **zio** – A blazing-fast, cross-platform file system utility built in Zig, designed for efficiency, reliability, and simplicity.

---

## Table of Contents

- [What is zio?](#what-is-zio)
- [Why zio?](#why-zio)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Build from Source](#build-from-source)
  - [Pre-compiled Binaries](#pre-compiled-binaries)
- [Usage](#usage)
  - [File Commands](#file-commands)
  - [Directory Commands](#directory-commands)
  - [Utility Commands](#utility-commands)
  - [Global Options](#global-options)
- [Getting Help](#getting-help)
- [Contributing](#contributing)
- [License](#license)
- [Maintainers](#maintainers)

---

## What is zio?

`zio` is a lightweight command-line tool that provides powerful file and directory operations across **Linux**, **macOS**, and **Windows**. Written in [Zig](https://ziglang.org/) for performance, safety, and consistency, it offers a clean, intuitive CLI that supports batch operations.

---

## Why zio?

- ⚡ **Fast and lightweight** — Compiled to native code with Zig's optimizations.
- 🧱 **Cross-platform** — Works seamlessly on Linux, macOS, and Windows.
- 📁 **Complete file & directory control** — Create, move, rename, delete, and inspect files and directories.
- 🧹 **Safe, reliable operations** — Clear error handling and consistent behavior.
- 🧰 **Batch operations** — Execute commands on multiple targets in one go.
- 💬 **Simple, human-friendly CLI** — Consistent structure, easy to remember.

---

## Installation

### Prerequisites

- **Zig 0.15.2+** – Download from [ziglang.org/download](https://ziglang.org/download/) or install via your package manager:

  ```bash
  # macOS
  brew install zig

  # Debian/Ubuntu
  sudo apt-get install zig

  # Windows (Chocolatey)
  choco install zig
  ```

- **Git** – Required only when building from source.

### Build from Source

```bash
# 1. Clone the repository
git clone https://github.com/Kingrashy12/zio.git
cd zio

# 2. Build the release binary
zig build -Drelease-safe

# 3. (Optional) Install globally
# On Unix-like systems, copy the binary to a directory on your $PATH
sudo cp zig-out/bin/zio /usr/local/bin/
```

### Pre-compiled Binaries

Download the latest release for your platform from the [GitHub Releases](https://github.com/Kingrashy12/zio/releases) page.

Example for Linux x86_64:

```bash
curl -L https://github.com/Kingrashy12/zio/releases/latest/download/zio-x86_64-linux -o zio
chmod +x zio
sudo mv zio /usr/local/bin/
```

Supported platforms: Linux (x86_64, aarch64), macOS (x86_64, aarch64), Windows (x86_64, x86).

---

## Usage

All commands follow a consistent syntax:

```
zio <command> [options] [arguments...]
```

### File Commands

#### `create`

Create new files in the current directory.

**Usage:**

```
zio create <file_name> [file_name...]
```

**Examples:**

```bash
# Create a single file
zio create hello.txt

# Create multiple files
zio create file1.txt file2.js data.json
```

#### `delete`

Delete files from the current directory.

**Usage:**

```
zio delete <file_name> [file_name...]
```

**Examples:**

```bash
# Delete a single file
zio delete old.txt

# Delete multiple files
zio delete temp.log cache.dat
```

#### `move`

Move a file to a new location. Requires the same filename (path change only).

**Usage:**

```
zio move <old_location>-><new_location>
```

**Examples:**

```bash
# Move file to subdirectory
zio move data.txt->docs/data.txt

# Move file up a directory
zio move src/main.zig->main.zig
```

#### `rename`

Rename a file in the current directory.

**Usage:**

```
zio rename <old_name>-><new_name>
```

**Examples:**

```bash
# Rename a file
zio rename old.txt->new.txt

# Rename with extension change
zio rename config.json->config.yaml
```

### Directory Commands

#### `mkdir`

Create new directories in the current location.

**Usage:**

```
zio mkdir <dir_name> [dir_name...]
```

**Examples:**

```bash
# Create a single directory
zio mkdir my_project

# Create multiple directories
zio mkdir src docs tests
```

#### `rmdir`

Remove directories from the current location.

**Usage:**

```
zio rmdir [--force|-f] <dir_name> [dir_name...]
```

**Options:**

- `--force`, `-f`: Force removal of non-empty directories without confirmation.

**Examples:**

```bash
# Remove an empty directory
zio rmdir temp

# Force remove a non-empty directory
zio rmdir -f old_project

# Remove multiple directories
zio rmdir dir1 dir2 dir3
```

#### `rndir`

Rename a directory in the current location.

**Usage:**

```
zio rndir <old_name>-><new_name>
```

**Examples:**

```bash
# Rename a directory
zio rndir old_folder->new_folder
```

### Utility Commands

#### `list`

List all files in the current directory.

**Usage:**

```
zio list
```

**Note:** This command is currently under development.

#### `stats`

Get statistics for all files in the current directory, including line counts.

**Usage:**

```
zio stats [ignore_pattern...]
```

**Examples:**

```bash
# Get stats for all files
zio stats

# Ignore certain files or patterns
zio stats *.log build/
```

**Output:** Displays a table with file names and line counts, plus totals.

### Global Options

- `--help`, `-h`: Show help information.
- `--version`, `-v`: Show version information.

**Examples:**

```bash
# Show general help
zio --help

# Show version
zio --version

# Show help for a specific command
zio create --help
```

---

## Getting Help

- **Documentation:** This README and inline help (`zio --help`).
- **Issues:** Report bugs or request features on [GitHub Issues](https://github.com/Kingrashy12/zio/issues).
- **Discussions:** Join community discussions on [GitHub Discussions](https://github.com/Kingrashy12/zio/discussions).

---

## Contributing

Want to make zio better? Feel free to open issues, suggest features, or submit pull requests. Let’s build something sharp together.

---

## License

`zio` is released under the **MIT License**. See the [LICENSE](LICENSE) file for full details.

---

## Maintainers

- **Kingrashy12** – [GitHub](https://github.com/Kingrashy12)

---

_Built with ❤️ using Zig_
