#!/usr/bin/env bash
#
# antigravity-2-users — uninstaller (macOS). Never touches your main Antigravity profile.
#
set -euo pipefail
SERVICE="antigravity-2-users"
NAME="b"; APP_DIR="/Applications"; MODE="ask"

usage() {
  cat <<USAGE
Usage: ./uninstall.sh [options]

  --name <id>      Profile id to remove. Default: b
  --app-dir <dir>  Where the launcher app was created. Default: /Applications
  --purge          Also delete profile data (~/.ag-profile-<id>), its keychain and the
                   stored keychain password, without asking. This signs the profile out.
  --keep-data      Remove only the launcher and Dock entry; keep profile data
  -h, --help       Show this help
USAGE
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)      NAME="${2:?}"; shift 2 ;;
    --app-dir)   APP_DIR="${2:?}"; shift 2 ;;
    --purge)     MODE="purge"; shift ;;
    --keep-data) MODE="keep"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[[ "$(uname)" == "Darwin" ]] || { echo "❌ macOS only" >&2; exit 1; }
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]{0,30}$ ]] || { echo "❌ Invalid --name" >&2; exit 1; }

LABEL="AG Profile $(echo "$NAME" | tr '[:lower:]' '[:upper:]')"
PROFILE_HOME="$HOME/.ag-profile-$NAME"
APP_TARGET="$APP_DIR/$LABEL.app"
KEYCHAIN_PATH="$PROFILE_HOME/Library/Keychains/login.keychain-db"

echo "==> Stopping profile '$NAME' (only processes started with its --user-data-dir)"
pkill -f -- "--user-data-dir=$PROFILE_HOME/" 2>/dev/null && sleep 1 || echo "  ✓ not running"

echo "==> Removing launcher"
if [[ -d "$APP_TARGET" ]]; then rm -rf "$APP_TARGET"; echo "  ✓ removed $APP_TARGET"; else echo "  ✓ $APP_TARGET not found"; fi

echo "==> Removing Dock entry"
AG2U_APP="$APP_TARGET" python3 - <<'PY' || echo "  ! Could not update the Dock"
import os, plistlib, subprocess, urllib.parse
url = "file://" + urllib.parse.quote(os.environ["AG2U_APP"].rstrip("/")) + "/"
dock = plistlib.loads(subprocess.run(["defaults", "export", "com.apple.dock", "-"], capture_output=True, check=True).stdout)
apps = dock.get("persistent-apps", [])
new = [a for a in apps if a.get("tile-data", {}).get("file-data", {}).get("_CFURLString") != url]
if len(new) != len(apps):
    dock["persistent-apps"] = new
    subprocess.run(["defaults", "import", "com.apple.dock", "-"], input=plistlib.dumps(dock), check=True)
    subprocess.run(["killall", "Dock"], check=False)
    print("  ✓ removed from Dock")
else:
    print("  ✓ not in Dock")
PY

if [[ "$MODE" == "ask" ]]; then
  read -r -p "Delete profile data in $PROFILE_HOME (signs this profile out)? [y/N] " choice
  [[ "$choice" =~ ^[Yy]$ ]] && MODE="purge" || MODE="keep"
fi
if [[ "$MODE" == "purge" ]]; then
  security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
  security delete-generic-password -s "$SERVICE" -a "$NAME" >/dev/null 2>&1 || true
  rm -rf "$PROFILE_HOME"
  echo "  ✓ deleted $PROFILE_HOME, its keychain and stored password"
else
  echo "  ✓ kept $PROFILE_HOME (reinstall later to reuse it, or rerun with --purge)"
fi
echo "Done. Your main Antigravity profile was not touched."
