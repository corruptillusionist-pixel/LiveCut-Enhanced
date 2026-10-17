#!/usr/bin/env bash
# Build the LiveCut Enhanced Audio Unit (AU) natively on an Apple Silicon Mac.
# Requires: full Xcode (not just Command Line Tools) and CMake 3.22+.
#   brew install cmake
# Usage: ./build_au_mac.sh [--install]
set -euo pipefail
cd "$(dirname "$0")"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is required for AU builds. Install it from the App Store, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

if [ ! -d vendor/JUCE ]; then
  git clone --depth 1 --branch 8.0.10 https://github.com/juce-framework/JUCE.git vendor/JUCE
fi

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build --config Release -j"$(sysctl -n hw.ncpu)"

AU="build/LiveCutVariant_artefacts/Release/AU/LiveCut Enhanced.component"
echo "Built: $AU"
lipo -info "$AU/Contents/MacOS/LiveCut Enhanced"

if [ "${1:-}" = "--install" ]; then
  mkdir -p "$HOME/Library/Audio/Plug-Ins/Components"
  rm -rf "$HOME/Library/Audio/Plug-Ins/Components/LiveCut Enhanced.component"
  cp -R "$AU" "$HOME/Library/Audio/Plug-Ins/Components/"
  # Ad-hoc sign so Apple Silicon hosts will load it
  codesign --force --deep -s - "$HOME/Library/Audio/Plug-Ins/Components/LiveCut Enhanced.component"
  killall -9 AudioComponentRegistrar 2>/dev/null || true
  echo "Installed to ~/Library/Audio/Plug-Ins/Components. Restart your DAW and rescan plugins."
fi
