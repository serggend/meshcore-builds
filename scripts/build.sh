#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
revision=81dbae592ffad40b4212bc0b37e82b38da08f4bc
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/meshcore-builds.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$build_dir/source" "$build_dir/dist"

curl -fLSs --retry 3 "https://codeload.github.com/meshcore-dev/MeshCore/tar.gz/$revision" -o "$build_dir/meshcore.tar.gz"
tar -xzf "$build_dir/meshcore.tar.gz" -C "$build_dir/source" --strip-components=1
cd "$build_dir/source"
git apply --check "$repo_dir/patches/repeater-connect.patch"
git apply "$repo_dir/patches/repeater-connect.patch"
cp "$repo_dir/platformio.releases.ini" platformio.local.ini

c++ -std=c++11 -Wall -Wextra -Werror -fsanitize=address,undefined \
  -I examples/simple_repeater tests/repeater/console.cpp -o "$build_dir/console-test"
"$build_dir/console-test"

# Сборка для распространения, каждый владелец задаёт PIN по USB.
unset PLATFORMIO_BUILD_FLAGS
pio run -e heltec_v4_repeater_connect -t mergebin
pio run -e ProMicro_repeater_connect -t create_uf2

cp .pio/build/heltec_v4_repeater_connect/firmware-merged.bin "$build_dir/dist/heltec-v4-oled-repeater-connect-merged.bin"
cp .pio/build/heltec_v4_repeater_connect/firmware.bin "$build_dir/dist/heltec-v4-oled-repeater-connect-app.bin"
cp .pio/build/ProMicro_repeater_connect/firmware.uf2 "$build_dir/dist/faketec-v4-repeater-connect.uf2"
cd "$build_dir/dist"
shasum -a 256 ./*.bin ./*.uf2 > SHA256SUMS
mkdir -p "$repo_dir/dist"
cp ./*.bin ./*.uf2 SHA256SUMS "$repo_dir/dist/"
