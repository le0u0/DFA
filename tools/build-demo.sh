#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${DFA_GODOT:-"$project_dir/.tools/godot/Godot.app/Contents/MacOS/Godot"}
platform=${1:-macos}
if [ ! -x "$godot_bin" ]; then
  echo 'Set DFA_GODOT to a Godot 4.7.2 executable.' >&2
  exit 1
fi
case "$platform" in
  macos) preset='macOS'; output='build/macos/Dungeon Fighter Arad.app' ;;
  windows) preset='Windows Desktop'; output='build/windows/Dungeon Fighter Arad.exe' ;;
  *) echo 'Usage: tools/build-demo.sh [macos|windows]' >&2; exit 1 ;;
esac
cd "$project_dir"
mkdir -p build/macos build/windows
"$godot_bin" --headless --path . --import
"$godot_bin" --headless --path . --export-release "$preset" "$output"
echo "Built $project_dir/$output"
