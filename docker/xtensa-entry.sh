#!/usr/bin/env bash

set -euo pipefail

TARGET="${1}"

case "${TARGET}" in
  xtensa-esp32-none-elf)
    CHIP=esp32
    ELF2IMAGE_VERSION=2
    ;;
  xtensa-esp8266-none-elf)
    CHIP=esp8266
    ELF2IMAGE_VERSION=3
    ;;
esac

if [[ -n "${IDF_PATH:-}" ]]; then
  PIP_CONFIG_FILE="$(mktemp)"

  {
    echo '[global]'
    echo 'no-cache-dir = false'
  } > "${PIP_CONFIG_FILE}"

  export PIP_CONFIG_FILE

  if [[ -z "${IDF_TOOLS_PATH:-}" ]]; then
    IDF_TOOLS_PATH="$(mktemp)"
    export IDF_TOOLS_PATH
  fi

  export PYTHONUSERBASE="${IDF_TOOLS_PATH}/local"

  idf_version="$(git -C "${IDF_PATH}" rev-parse HEAD 2>/dev/null || true)"
  version_file="${IDF_TOOLS_PATH}/installed_version"

  if ! [[ -f "${version_file}" ]] || [[ "${idf_version}" != "$(cat "${version_file}")" ]]; then
    case "${CHIP}" in
      esp32)
        "${IDF_PATH}/install.sh"
        ;;
      esp8266)
        python -m pip install --user -r "${IDF_PATH}/requirements.txt"
        ;;
    esac

    if [[ -n "${idf_version:-}" ]]; then
      echo "${idf_version}" > "${version_file}"
    fi
  fi

  case "${CHIP}" in
    esp32)
      # shellcheck disable=SC1090
      source "${IDF_PATH}/export.sh" >/dev/null
      ;;
    esp8266)
      ;;
  esac
fi

"${@:2}"

export PATH="${PATH}:/rust/bin"

mapfile -t binary_targets < <(
  cargo metadata --format-version 1 \
  | jq -c '
      .workspace_members as $members | .packages
      | map(select(.id as $id | $members[] | contains($id) ))
      | map(.targets)[] | map(select(.kind[] | contains("bin") or contains("example")))[]
      | .name
    ' -r
)

for binary_target in "${binary_targets[@]}"; do
  for t in "${CARGO_TARGET_DIR}"/${TARGET}/{release,debug}/{,examples/}"${binary_target}"; do
    if [[ -f "${t}" ]]; then
      "${IDF_PATH}/components/esptool_py/esptool/esptool.py" \
        --chip "${CHIP}" \
        elf2image \
        --version "${ELF2IMAGE_VERSION}" \
        -o "${t}.bin" \
        "${t}" | tail -n +2
    fi
  done
done
