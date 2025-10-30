# ⚡ Zio

**A blazing-fast, cross-platform file system utility built in Zig — designed for efficiency, reliability, and simplicity.**

---

## 🚀 Overview

`zio` is a lightweight command-line tool that provides powerful file and directory operations across **Linux**, **macOS**, and **Windows**.  
It’s written in [Zig](https://ziglang.org/) for performance, safety, and consistency — offering a clean, intuitive CLI that supports **batch operations**.

---

## ✨ Features

- ⚡ **Fast and lightweight** — compiled to native code with Zig.
- 🧱 **Cross-platform** — works seamlessly on Linux, macOS, and Windows.
- 📁 **Complete file & directory control** — create, move, rename, and delete.
- 🧹 **Safe, reliable operations** — clear error handling and consistent behavior.
- 🧰 **Multi-operation support** — execute commands on multiple targets in one go.
- 💬 **Simple, human-friendly CLI** — consistent structure, easy to remember.

---

## 🧩 Installation

Download the pre-built binary for your platform from the [releases page](https://github.com/Kingrashy12/zio/releases).

Example:

```bash
# Linux (x86_64)
curl -L https://github.com/Kingrashy12/zio/releases/latest/download/zio-x86_64-linux -o zio
chmod +x zio
sudo mv zio /usr/local/bin/
```

```bash
# macOS (Apple Silicon)
curl -L https://github.com/Kingrashy12/zio/releases/latest/download/zio-aarch64-macos -o zio
chmod +x zio
sudo mv zio /usr/local/bin/
```

```powershell
# Windows (PowerShell) — Option A: install to a user folder and add to your user PATH (no admin)
$dest = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force -Path $dest
Invoke-WebRequest -Uri "https://github.com/Kingrashy12/zio/releases/latest/download/zio-x86_64-windows.exe" -OutFile "$dest\zio.exe"
# add to user PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path","User")
if (-not ($userPath -split ';' | Where-Object { $_ -eq $dest })) {
    [Environment]::SetEnvironmentVariable("Path", ("$userPath;"+$dest).Trim(';'), "User")
    Write-Output "Added $dest to your user PATH. Restart your terminal to apply."
} else {
    Write-Output "$dest is already in your user PATH."
}

# Windows (PowerShell) — Option B: install to per-user Programs (global appdata) and add to PATH (no admin)
$dest = "$env:LOCALAPPDATA\Programs\zio"
New-Item -ItemType Directory -Force -Path $dest
Invoke-WebRequest -Uri "https://github.com/Kingrashy12/zio/releases/latest/download/zio-x86_64-windows.exe" -OutFile "$dest\zio.exe"
$userPath = [Environment]::GetEnvironmentVariable("Path","User")
if (-not ($userPath -split ';' | Where-Object { $_ -eq $dest })) {
    [Environment]::SetEnvironmentVariable("Path", ("$userPath;"+$dest).Trim(';'), "User")
    Write-Output "Added $dest to your user PATH. Restart your terminal to apply."
} else {
    Write-Output "$dest is already in your user PATH."
}
```

## 🧠 Usage

```bash
zio <command> [options]
```

## 📄 File Commands

| Command  | Description                                 |
| -------- | ------------------------------------------- |
| `create` | Create a new file in the current directory. |
| `delete` | Delete a file from the current directory.   |
| `move`   | Move a file to a new location.              |
| `rename` | Rename a file in the current directory.     |

## 📁 Directory Commands

| Command | Description                                                                    |
| ------- | ------------------------------------------------------------------------------ |
| `mkdir` | Create a new directory in the current location.                                |
| `rmdir` | Remove a directory. Supports `--force` / `-f` to delete non-empty directories. |
| `rndir` | Rename a directory in the current location.                                    |

## 🧪 Examples

```bash
# Create a new file
zio create hello.txt

# Create multiple files
zio create hello.txt users.js data.ts

# Delete a file
zio delete old.txt

# List files
zio list

# Move file to subdirectory
zio move hello.txt->docs/hello.txt

# Rename a file
zio rename old.txt->new.txt

# Create and remove directories
zio mkdir my_project
zio rmdir my_project --force
```

## ⚙️ Build from Source

Requires [Zig 0.15.1+](https://ziglang.org)

```bash
git clone https://github.com/Kingrashy12/zio.git
cd zio
zig build
```
