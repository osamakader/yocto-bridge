#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR=${1:-build}
LOG_DIR="$BUILD_DIR/tmp/log/cooker"
PKGSTATE_DIR="$BUILD_DIR/tmp/pkgdata/qemuarm64"

if [[ ! -d "$LOG_DIR" ]]; then
  echo "[error] Cannot find cooker logs under $LOG_DIR" >&2
  exit 1
fi

start_time=$(find "$LOG_DIR" -maxdepth 1 -type f -name 'cooker_qemuarm64_*' -printf '%T@ %f\n' | sort | head -n1 | cut -d' ' -f1)
end_time=$(find "$LOG_DIR" -maxdepth 1 -type f -name 'cooker_qemuarm64_*' -printf '%T@ %f\n' | sort | tail -n1 | cut -d' ' -f1)

total_seconds=$(python3 - <<PY
from datetime import datetime
start = $start_time
end = $end_time
print(int(end - start))
PY
)

reused=$(grep -R "Task .* do_package:done" -R "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
rebuilt=()
if [[ -d "$PKGSTATE_DIR/runtime" ]]; then
  while IFS= read -r line; do
    pkg=$(basename "$line")
    rebuilt+=("${pkg%.packaged}" )
  done < <(find "$PKGSTATE_DIR/runtime" -name '*.packaged' -type f)
fi

printf 'total build time: %02dh%02dm%02ds\n' $((total_seconds/3600)) $(((total_seconds%3600)/60)) $((total_seconds%60))

echo "reused packages: ${reused}" 
if ((${#rebuilt[@]} > 0)); then
  printf 'rebuilt packages: %s\n' "${rebuilt[*]}"
else
  echo 'rebuilt packages: none detected'
fi

echo "deb cache enabled: ${ISAR_ENABLE_DEB_CACHE:-unknown}"
