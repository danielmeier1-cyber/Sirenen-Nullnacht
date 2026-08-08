#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$project_dir/build"

# GitHub Actions previously wrote the Android paths to
# editor_settings-4.3.tres. Godot names this file after the major version,
# so configure the paths here immediately before launching Godot.
if [[ -n "${ANDROID_HOME:-}" && -n "${JAVA_HOME:-}" ]]; then
  settings_dir="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
  settings_file="$settings_dir/editor_settings-4.tres"
  debug_keystore="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.android/debug.keystore}"
  mkdir -p "$settings_dir"
  cat > "$settings_file" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME"
export/android/debug_keystore = "$debug_keystore"
export/android/debug_keystore_user = "${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export/android/debug_keystore_pass = "${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"
EOF
fi

if command -v godot4 >/dev/null 2>&1; then
  godot_bin="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
else
  echo "Godot 4.3+ wurde nicht gefunden." >&2
  exit 1
fi

"$godot_bin" --headless --editor --quit --path "$project_dir"
"$godot_bin" --headless --verbose --path "$project_dir" --export-debug Android "$project_dir/build/Sirenen-Nullnacht.apk"
test -s "$project_dir/build/Sirenen-Nullnacht.apk"
echo "APK: $project_dir/build/Sirenen-Nullnacht.apk"
