#!/usr/bin/env bash
# Refreshes the vendored copies from Nerviz at the ref in
# .plugin-source.json. Run it, read `git diff`, commit. Nothing here writes to the
# source repository, and nothing commits on your behalf.
#
#   ./sync.sh                # pull at the ref recorded in .plugin-source.json
#   ./sync.sh v1.2.0         # pull at this ref AND record it as the new one
#
# Dependencies: bash, curl, python3 (the JSON reader only — no packages).
#
# `pipefail` is load-bearing, not decoration: the loop below runs in a subshell (it is
# the right-hand side of a pipe), so its `exit 1` is the pipeline's status and nothing
# else would carry a failed fetch out of this script.
set -euo pipefail

cd "$(dirname "$0")"
SRC=.plugin-source.json
REF="${1:-$(python3 -c 'import json;print(json.load(open("'"$SRC"'"))["ref"])')}"
RAW=$(python3 -c 'import json;print(json.load(open("'"$SRC"'"))["raw_url"])')
AUTH_ENV=$(python3 -c 'import json;print(json.load(open("'"$SRC"'"))["auth_env"])')
TOKEN="${!AUTH_ENV:-}"

# Bash 3.2 (the macOS default) reports "${HEADER[@]}" as unbound when the array is empty
# under 'set -u', so the expansion at the call site is guarded. A public source repository
# needs no header at all, which is the common case.
HEADER=()
[ -n "$TOKEN" ] && HEADER=(-H "Authorization: Bearer $TOKEN")

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

python3 -c 'import json;[print(k,v) for k,v in json.load(open("'"$SRC"'"))["files"].items()]' \
| while read -r local remote; do
    url="${RAW/\{ref\}/$REF}"; url="${url/\{path\}/$remote}"
    # Downloaded to a temporary file and moved only on success: a 404 must leave the
    # committed copy exactly as it was, not half-written.
    if ! curl -sS --fail --retry 3 --retry-all-errors --max-time 60 -L \
           ${HEADER[@]+"${HEADER[@]}"} "$url" -o "$TMP"; then
      echo "❌ could not fetch $remote @ $REF"
      echo "   Private source? Export \$$AUTH_ENV with read access and run again."
      echo "   Wrong ref? $REF must exist in the source repository."
      exit 1
    fi
    mkdir -p "$(dirname "$local")"
    mv "$TMP" "$local"
    echo "  $local  ←  $remote @ $REF"
  done

if [ $# -ge 1 ]; then
  python3 - "$SRC" "$REF" <<'PY'
import json, sys
p, ref = sys.argv[1], sys.argv[2]
d = json.load(open(p))
d["ref"] = ref
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
open(p, "a").write("\n")
PY
  echo "  .plugin-source.json  ref → $REF"
fi

echo "Done. Review with \`git diff\`, then commit."
