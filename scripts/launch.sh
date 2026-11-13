#!/usr/bin/env bash
#
# antigravity-2-users — launcher for an isolated profile.
# Installed copy lives in ~/.ag-profile-<id>/.ag2u/launch.sh and reads ./config next to it.
# From a checkout you can run:  ./scripts/launch.sh --name b [extra Antigravity args]
#
set -euo pipefail
SERVICE="antigravity-2-users"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--name" ]]; then
  CONF="$HOME/.ag-profile-${2:?--name needs a value}/.ag2u/config"; shift 2
else
  CONF="$HERE/config"
fi
[[ -f "$CONF" ]] || { echo "❌ Profile config not found: $CONF (run ./install.sh first)" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONF"

KEYCHAIN_PATH="$AG2U_PROFILE_HOME/Library/Keychains/login.keychain-db"
USER_DATA_DIR="$AG2U_PROFILE_HOME/Library/Application Support/Antigravity"

if PW="$(security find-generic-password -s "$SERVICE" -a "$AG2U_NAME" -w 2>/dev/null)"; then
  security unlock-keychain -p "$PW" "$KEYCHAIN_PATH" 2>/dev/null || true
  security set-keychain-settings "$KEYCHAIN_PATH" 2>/dev/null || true
  unset PW
else
  echo "⚠️  Stored keychain password not found; the profile keychain stays locked." >&2
fi

# GUI apps get a minimal PATH; add the usual Homebrew locations for the agent's terminal.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOME="$AG2U_PROFILE_HOME"
exec "$AG2U_APP_EXEC" --user-data-dir="$USER_DATA_DIR" "$@"
