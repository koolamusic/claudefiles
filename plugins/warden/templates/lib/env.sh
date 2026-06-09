#!/usr/bin/env bash
# .warden/lib/env.sh - layered dotenv loading
#
# Sources every file in ENV_FILES (configured in warden.config.sh) in order.
# Variables are auto-exported. Paths are relative to PROJECT_ROOT.

warden_load_env() {
  local -a files=("$@")
  if [[ ${#files[@]} -eq 0 ]]; then
    files=("${ENV_FILES[@]:-.env}")
  fi
  for f in "${files[@]}"; do
    local path
    if [[ "$f" = /* ]]; then
      path="$f"
    else
      path="${PROJECT_ROOT}/${f}"
    fi
    if [[ -f "$path" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$path"
      set +a
    fi
  done
}
