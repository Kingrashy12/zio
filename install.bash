#!/usr/bin/env bash

# --- Configuration ---
owner="Kingrashy12"
repo="zio"
base_asset_name="zio" # Prefix for all assets
windows_ext=".exe"    # Extension for Windows assets
install_name="zio"    # Name of the executable after installation

# Stop on first error
set -e

# --- Utility Functions ---

# Function to determine the OS and architecture
get_platform_info() {
    local os=""
    local arch=""

    # 1. Determine OS
    case "$(uname -s)" in
        Linux*)
            os="linux"
            ;;
        Darwin*)
            os="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            os="windows"
            ;;
        *)
            echo "Error: Unsupported OS type: $(uname -s)" >&2
            exit 1
            ;;
    esac

    # 2. Determine Architecture (Standardizing common variations)
    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        i386|i686) # For Windows 32-bit (zio-x86-windows.exe)
            arch="x86"
            ;;
        *)
            echo "Error: Unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac

    echo "$os,$arch"
}

# --- Main Logic ---

echo "--- ZIO Universal Installer ---"

# Get platform info
IFS=',' read -r OS ARCH <<< "$(get_platform_info)"

echo "Detected OS: **$OS**"
echo "Detected Architecture: **$ARCH**"

# 3. Construct Asset Name based on OS and ARCH
if [ "$OS" = "windows" ]; then
    # Windows assets are: zio-x86_64-windows.exe, zio-x86-windows.exe
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "x86" ]; then
        asset_name="${base_asset_name}-${ARCH}-windows${windows_ext}"
        install_name="${install_name}${windows_ext}"
    else
        echo "Error: No Windows asset found for architecture $ARCH." >&2
        exit 1
    fi
else
    # Linux/macOS assets are: zio-aarch64-linux, zio-x86_64-linux, etc.
    asset_name="${base_asset_name}-${ARCH}-${OS}"
fi

echo "Target Asset Name: **$asset_name**"
echo "Target Executable Name: **$install_name**"

# 4. Fetch Latest Version
echo "Fetching latest version from GitHub..."
latest_version=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" \
    | grep "tag_name" \
    | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

if [ -z "$latest_version" ]; then
    echo "Error: Could not retrieve latest version tag." >&2
    exit 1
fi

echo "Latest version: **$latest_version**"

# 5. Construct Download URL
download_url="https://github.com/$owner/$repo/releases/download/$latest_version/$asset_name"

echo "Downloading from: **$download_url**"

# 6. Download the Asset
curl -L -o "$asset_name" "$download_url"

echo "Download complete."

# 7. Determine Install Directory
install_dir=""
if [ "$OS" = "windows" ]; then
    # Prefer WindowsApps for Windows users (in PATH by default)
    if [ -n "$LOCALAPPDATA" ]; then
        install_dir="$LOCALAPPDATA/Microsoft/WindowsApps"
    else
        # Fallback if $LOCALAPPDATA isn't set (e.g., some WSL/Git Bash configs)
        install_dir="/usr/local/bin"
    fi
else
    # Standard location for Linux/macOS
    install_dir="/usr/local/bin"
fi

mkdir -p "$install_dir"

echo "Installing to directory: **$install_dir**"

# 8. Move and Rename (Install)
mv -f "$asset_name" "$install_dir/$install_name"

# 9. Set executable permissions for non-Windows systems
if [ "$OS" != "windows" ]; then
    chmod +x "$install_dir/$install_name"
    echo "Set executable permissions."
fi

echo "Installation complete as: **$install_dir/$install_name**"
echo

# 10. Check if in PATH
if command -v zio >/dev/null 2>&1; then
    echo "✅ Installation successful! Run: **zio**"
else
    echo "⚠ Installation successful, but the executable might not be immediately available in PATH."
    echo "⚠ Please ensure **$install_dir** is in your system's PATH environment variable."
    echo "⚠ You may need to restart your terminal or run **source ~/.bashrc** / **source ~/.zshrc**."
fi