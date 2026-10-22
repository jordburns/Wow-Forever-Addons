#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDON="${ADDON:-Class_Macros}"
TOC="$ROOT/$ADDON/$ADDON.toc"
PART="${1:-patch}"

current="$(sed -n 's/^## Version: //p' "$TOC" | tr -d '\r')"
if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "The version in $TOC is \"$current\". It must look like 1.2.3." >&2
    exit 1
fi

IFS=. read -r major minor patch <<< "$current"
case "$PART" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    none) ;;
    *) echo "Usage: scripts/release.sh [patch|minor|major|none]" >&2; exit 1 ;;
esac
version="$major.$minor.$patch"

if [[ "$version" != "$current" ]]; then
    perl -pi -e "s/^## Version: .*/## Version: $version/" "$TOC"
    echo "Version: $current -> $version"
else
    echo "Version: $version (not changed)"
fi

mkdir -p "$ROOT/dist"
archive="$ROOT/dist/$ADDON-$version.zip"
rm -f "$archive"
(cd "$ROOT" && zip -r -X -q "$archive" "$ADDON" -x "*.DS_Store")
echo "Zip: $archive"
