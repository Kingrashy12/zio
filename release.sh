#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# 🏷️ Configuration
# -------------------------------
VERSION="${1:-v0.0.1}" # optional CLI arg (e.g. ./release.sh v0.1.0)
TITLE="$VERSION"
NOTES="Initial release of zio:

- Cross-platform CLI tool
- Supports Linux, macOS, and Windows
- Available for x86, x86_64, and ARM64 architectures"

REPO="Kingrashy12/zio"

# -------------------------------
# 🧱 Build artifacts (optional)
# -------------------------------
echo "🔨 Building release binaries..."
zig build

# -------------------------------
# 📂 Artifact list
# -------------------------------
ARTIFACTS=(
  "zig-out/aarch64-linux/zio"
  "zig-out/x86_64-linux-gnu/zio"
  "zig-out/aarch64-macos/zio"
  "zig-out/x86_64-macos/zio"
  "zig-out/x86_64-windows/zio.exe"
  "zig-out/x86-windows/zio.exe"
)

# -------------------------------
# 🧩 Validate artifacts
# -------------------------------
echo "🕵️ Checking built binaries..."
for file in "${ARTIFACTS[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "❌ Missing: $file"
    exit 1
  fi
done
echo "✅ All binaries found."

# -------------------------------
# 🏷️ Ensure tag exists
# -------------------------------
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "🏷️ Creating new git tag $VERSION"
  git tag "$VERSION"
  git push origin "$VERSION"
else
  echo "✅ Tag $VERSION already exists."
fi

echo "📦 Preparing assets with unique filenames..."
TMPDIR=$(mktemp -d)

cp zig-out/aarch64-linux/zio           "$TMPDIR/zio-aarch64-linux"
cp zig-out/x86_64-linux-gnu/zio        "$TMPDIR/zio-x86_64-linux"
cp zig-out/aarch64-macos/zio           "$TMPDIR/zio-aarch64-macos"
cp zig-out/x86_64-macos/zio            "$TMPDIR/zio-x86_64-macos"
cp zig-out/x86_64-windows/zio.exe      "$TMPDIR/zio-x86_64-windows.exe"
cp zig-out/x86-windows/zio.exe         "$TMPDIR/zio-x86-windows.exe"

ARTIFACTS=("$TMPDIR"/*)


# -------------------------------
# 🚀 Create release
# -------------------------------
gh release create "$VERSION" \
  "${ARTIFACTS[@]}" \
  --title "$TITLE" \
  --notes "$NOTES" \
  --repo "$REPO"


echo "🎉 Release $VERSION published successfully!"

rm -rf "$TMPDIR"