#!/usr/bin/env bash
#
# antigravity-2-users — read-only isolation check. Prints item NAMES only, never secrets.
#
set -uo pipefail
NAME="b"
[[ "${1:-}" == "--name" ]] && NAME="${2:?--name needs a value}"
P="$HOME/.ag-profile-$NAME"
KC="$P/Library/Keychains/login.keychain-db"
LOGIN_KC="$(security default-keychain -d user | tr -d ' "')"

echo "Profile '$NAME' -> $P"
[[ -d "$P" ]] || { echo "❌ not installed"; exit 1; }

echo; echo "== Processes using this profile"
pgrep -fl -- "--user-data-dir=$P/" || echo "(not running)"

echo; echo "== Profile keychain: $KC"
security show-keychain-info "$KC" 2>&1 | sed 's/^/  /'
security dump-keychain "$KC" 2>/dev/null | grep -E '"(svce|acct)"' | sed 's/^ */  /' || true

echo; echo "== Your login keychain ($LOGIN_KC): Antigravity-looking items"
security dump-keychain "$LOGIN_KC" 2>/dev/null | grep -iE '"svce".*(antigravity|gemini|jetski)' | sed 's/^ */  /' || echo "  (none)"
echo "  (Items for your MAIN account are expected here. If the SECOND account's items show up here"
echo "   instead of in the profile keychain, isolation is incomplete — please open an issue.)"

echo; echo "== Token / config files (names only)"
for d in "$HOME/.gemini" "$P/.gemini"; do echo "  $d:"; if [[ -d "$d" ]]; then find "$d" -mindepth 1 -maxdepth 1 -exec basename {} \; | sed "s/^/    /"; else echo "    (missing)"; fi; done
