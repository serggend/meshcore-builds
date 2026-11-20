#!/bin/sh
set -eu

profile=${1:-repeater}
case "$profile" in
  repeater) profile_suffix=connect ;;
  companion) profile_suffix=companion ;;
  client|client-ble|client-radio) ;;
  *) echo 'Использование: ./scripts/build.sh [repeater|companion|client|client-ble|client-radio]' >&2; exit 2 ;;
esac

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
revision=81dbae592ffad40b4212bc0b37e82b38da08f4bc
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/meshcore-builds.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$build_dir/source" "$build_dir/dist"

curl -fLSs --retry 3 "https://codeload.github.com/meshcore-dev/MeshCore/tar.gz/$revision" -o "$build_dir/meshcore.tar.gz"
tar -xzf "$build_dir/meshcore.tar.gz" -C "$build_dir/source" --strip-components=1
cd "$build_dir/source"

if [ "$profile" = client ] || [ "$profile" = client-radio ]; then
  git apply --check "$repo_dir/patches/heltec-v4-companion-all.patch" "$repo_dir/patches/companion-rx-log.patch"
  git apply "$repo_dir/patches/heltec-v4-companion-all.patch" "$repo_dir/patches/companion-rx-log.patch"
  cp "$repo_dir/platformio.releases.ini" platformio.local.ini
  unset PLATFORMIO_BUILD_FLAGS

  env_name=heltec_v4_companion_radio_all
  artifact=heltec-v4-oled-companion-echo
  if [ "$profile" = client-radio ]; then
    git apply --check "$repo_dir/patches/companion-radio-history.patch"
    git apply "$repo_dir/patches/companion-radio-history.patch"
    c++ -std=c++11 -Wall -Wextra -Werror -fsanitize=address,undefined \
      -I examples/companion_radio "$repo_dir/tests/companion_radio_noise_history.cpp" \
      -o "$build_dir/radio-noise-history-test"
    "$build_dir/radio-noise-history-test"
    artifact=heltec-v4-companion-radio-history
  fi
  pio run -e "$env_name" -t mergebin
  cp ".pio/build/$env_name/firmware-merged.bin" "$build_dir/dist/$artifact-merged.bin"
  cp ".pio/build/$env_name/firmware.bin" "$build_dir/dist/$artifact-app.bin"
  cd "$build_dir/dist"
  shasum -a 256 ./*.bin > SHA256SUMS
  mkdir -p "$repo_dir/dist/$profile"
  cp ./*.bin SHA256SUMS "$repo_dir/dist/$profile/"
  exit 0
fi

if [ "$profile" = client-ble ]; then
  git apply --check "$repo_dir/patches/companion-rx-log.patch" "$repo_dir/patches/rak4631-open-bme680.patch"
  git apply "$repo_dir/patches/companion-rx-log.patch" "$repo_dir/patches/rak4631-open-bme680.patch"
  cp "$repo_dir/platformio.releases.ini" platformio.local.ini
  unset PLATFORMIO_BUILD_FLAGS UF2_FILE_PATH

  pio run -e Heltec_v3_companion_radio_ble -t mergebin
  cp .pio/build/Heltec_v3_companion_radio_ble/firmware.bin "$build_dir/dist/heltec-v3-oled-companion-echo-app.bin"
  cp .pio/build/Heltec_v3_companion_radio_ble/firmware-merged.bin "$build_dir/dist/heltec-v3-oled-companion-echo-merged.bin"

  pio run -e ProMicro_companion_radio_ble -t create_uf2
  cp .pio/build/ProMicro_companion_radio_ble/firmware.uf2 "$build_dir/dist/faketec-v4-promicro-companion-echo.uf2"

  pio run -e RAK_4631_companion_radio_ble -t create_uf2
  cp .pio/build/RAK_4631_companion_radio_ble/firmware.uf2 "$build_dir/dist/rak4631-companion-echo.uf2"

  cd "$build_dir/dist"
  shasum -a 256 ./*.bin ./*.uf2 > SHA256SUMS
  mkdir -p "$repo_dir/dist/$profile"
  cp ./*.bin ./*.uf2 SHA256SUMS "$repo_dir/dist/$profile/"
  exit 0
fi

git apply --check "$repo_dir/patches/repeater-connect.patch"
git apply "$repo_dir/patches/repeater-connect.patch"
if [ "$profile" = companion ]; then
  git apply --check "$repo_dir/patches/repeater-companion.patch"
  git apply "$repo_dir/patches/repeater-companion.patch"
fi
cp "$repo_dir/platformio.releases.ini" platformio.local.ini

c++ -std=c++11 -Wall -Wextra -Werror -fsanitize=address,undefined \
  -I examples/simple_repeater tests/repeater/console.cpp -o "$build_dir/console-test"
"$build_dir/console-test"
if [ "$profile" = companion ]; then
  c++ -std=c++11 -DREPEATER_COMPANION -fsanitize=address,undefined \
    -I src -I test/mocks -I examples/simple_repeater \
    tests/repeater/companion_scheduler.cpp src/Dispatcher.cpp src/Packet.cpp \
    src/Utils.cpp src/helpers/StaticPoolPacketManager.cpp -o "$build_dir/companion-test"
  "$build_dir/companion-test"
fi

# Сборка для распространения, каждый владелец задаёт PIN по USB.
unset PLATFORMIO_BUILD_FLAGS
for board in Heltec_v3 heltec_v4; do
  case "$board" in
    Heltec_v3) model=v3 ;;
    heltec_v4) model=v4 ;;
  esac
  env_name="${board}_repeater_$profile_suffix"
  artifact="heltec-$model-oled-repeater-$profile_suffix"
  pio run -e "$env_name" -t mergebin
  cp ".pio/build/$env_name/firmware-merged.bin" "$build_dir/dist/$artifact-merged.bin"
  cp ".pio/build/$env_name/firmware.bin" "$build_dir/dist/$artifact-app.bin"
done

faketec="ProMicro_repeater_$profile_suffix"
pio run -e "$faketec" -t create_uf2
cp ".pio/build/$faketec/firmware.uf2" "$build_dir/dist/faketec-v4-repeater-$profile_suffix.uf2"
cd "$build_dir/dist"
shasum -a 256 ./*.bin ./*.uf2 > SHA256SUMS
mkdir -p "$repo_dir/dist/$profile"
cp ./*.bin ./*.uf2 SHA256SUMS "$repo_dir/dist/$profile/"
