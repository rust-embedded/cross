#!/usr/bin/env bash

set -euo pipefail

TARGET="${1}"

"${@:2}"

export PATH="${PATH}:/rust/bin"

case "${TARGET}" in
  xtensa-esp32-none-elf)
    CHIP=esp32
    ;;
  xtensa-esp8266-none-elf)
    CHIP=esp8266
    ;;
esac

binary_targets="$(cargo metadata --format-version 1 | jq -c '.workspace_members as $members | .packages | map(select(.id as $id | $members[] | contains($id) )) | map(.targets)[] | map(select(.kind[] | contains("bin")))[] | .name' -r)"
for binary_target in "${binary_targets[@]}"; do
  for t in "${CARGO_TARGET_DIR}"/${TARGET}/{release,debug}/"${binary_target}"; do
    if [[ -f "${t}" ]]; then
      "${IDF_PATH}/components/esptool_py/esptool/esptool.py" \
        --chip "${CHIP}" \
        elf2image \
        -o "${t}.bin" \
        "${t}" | tail -n +2
    fi
  done
done
