#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$project_dir/build"

if command -v godot4 >/dev/null 2>&1; then
  godot_bin="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
else
  echo "Godot 4.3+ wurde nicht gefunden." >&2
  exit 1
fi

"$godot_bin" --headless --editor --quit --path "$project_dir"
"$godot_bin" --headless --path "$project_dir" --export-debug Android "$project_dir/build/Sirenen-Nullnacht.apk"
test -s "$project_dir/build/Sirenen-Nullnacht.apk"
echo "APK: $project_dir/build/Sirenen-Nullnacht.apk"
