#!/usr/bin/env bash
#
# antigravity-2-users — installer (macOS)
# Creates an isolated second profile for the Antigravity desktop app:
#   separate HOME, separate --user-data-dir, separate keychain, own launcher app.
#
# Unofficial. Not affiliated with or endorsed by Google.
#
set -euo pipefail

VERSION="0.1.0"
SERVICE="antigravity-2-users"          # login-keychain item that stores the profile keychain password

NAME="b"
APP_SOURCE="/Applications/Antigravity.app"
APP_DIR="/Applications"
ADD_DOCK=1
LINK_DEV=0

usage() {
  cat <<USAGE
antigravity-2-users ${VERSION} — install an isolated second Antigravity profile (macOS)

Usage: ./install.sh [options]

  --name <id>          Profile id: lowercase letters, digits, '-'. Default: b
                       -> data in ~/.ag-profile-<id>, launcher "AG Profile <ID>.app"
  --app-source <path>  Antigravity.app to launch. Default: /Applications/Antigravity.app
  --app-dir <dir>      Where to create the launcher app. Default: /Applications
                       (use ~/Applications if you are not an admin user)
  --no-dock            Do not add the launcher to the Dock
  --link-dev           Also link ~/.gitconfig, ~/.ssh, ~/.zshrc, ~/.zprofile, ~/.npmrc,
                       ~/.config/git into the profile HOME (git/ssh work inside profile)
  -h, --help           Show this help
  -V, --version        Show version
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)       NAME="${2:?--name needs a value}"; shift 2 ;;
    --app-source) APP_SOURCE="${2:?--app-source needs a value}"; shift 2 ;;
    --app-dir)    APP_DIR="${2:?--app-dir needs a value}"; shift 2 ;;
    --no-dock)    ADD_DOCK=0; shift ;;
    --link-dev)   LINK_DEV=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    -V|--version) echo "$VERSION"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

die() { echo "❌ $*" >&2; exit 1; }
ok()  { echo "  ✓ $*"; }

[[ "$(uname)" == "Darwin" ]] || die "This script only supports macOS."
[[ "$NAME" =~ ^[a-z0-9][a-z0-9-]{0,30}$ ]] || die "Invalid --name '$NAME' (use lowercase letters, digits, '-')."
APP_EXEC="$APP_SOURCE/Contents/MacOS/Antigravity"
[[ -x "$APP_EXEC" ]] || die "Antigravity not found at $APP_SOURCE. Install it first (https://antigravity.google) or pass --app-source."

LABEL="AG Profile $(echo "$NAME" | tr '[:lower:]' '[:upper:]')"
PROFILE_HOME="$HOME/.ag-profile-$NAME"
CONF_DIR="$PROFILE_HOME/.ag2u"
KEYCHAIN_PATH="$PROFILE_HOME/Library/Keychains/login.keychain-db"
USER_DATA_DIR="$PROFILE_HOME/Library/Application Support/Antigravity"
APP_TARGET="$APP_DIR/$LABEL.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "  antigravity-2-users ${VERSION} — installing profile '$NAME'"
echo "============================================================"

echo "==> 1/5 Profile HOME: $PROFILE_HOME"
mkdir -p "$PROFILE_HOME/Library/Keychains" "$USER_DATA_DIR" "$CONF_DIR"
chmod 700 "$PROFILE_HOME"
link() {  # link <source> <dest>; never follows an existing link (-n), never clobbers real files
  local src="$1" dst="$2"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dst" && ! -L "$dst" ]]; then echo "  ! $dst exists and is not a symlink, skipped"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}
for d in Desktop Documents Downloads; do link "$HOME/$d" "$PROFILE_HOME/$d"; done
ok "Linked Desktop, Documents, Downloads"
if [[ "$LINK_DEV" == 1 ]]; then
  for f in .gitconfig .ssh .zshrc .zprofile .npmrc .config/git; do link "$HOME/$f" "$PROFILE_HOME/$f"; done
  ok "Linked developer dotfiles (--link-dev)"
fi

echo "==> 2/5 Dedicated keychain"
if PW="$(security find-generic-password -s "$SERVICE" -a "$NAME" -w 2>/dev/null)"; then
  ok "Reusing stored keychain password (login keychain item '$SERVICE' / '$NAME')"
else
  PW="$(openssl rand -hex 24)"
  if [[ -f "$KEYCHAIN_PATH" ]]; then
    # Migrate keychains created by the old prototype, which used a fixed public password.
    security set-keychain-password -o "antigravity" -p "$PW" "$KEYCHAIN_PATH" 2>/dev/null \
      || die "Keychain $KEYCHAIN_PATH exists but its password is unknown. Run ./uninstall.sh --name $NAME --purge first."
    ok "Rotated legacy fixed password to a random one"
  fi
  security add-generic-password -U -s "$SERVICE" -a "$NAME" -l "$SERVICE ($NAME)" -w "$PW"
  ok "Random password stored in your login keychain (item '$SERVICE' / '$NAME')"
fi
if [[ ! -f "$KEYCHAIN_PATH" ]]; then
  security create-keychain -p "$PW" "$KEYCHAIN_PATH"
  ok "Created $KEYCHAIN_PATH"
fi
security unlock-keychain -p "$PW" "$KEYCHAIN_PATH"
security set-keychain-settings "$KEYCHAIN_PATH"   # no -l / -t: no lock on sleep, no timeout
unset PW
ok "Keychain unlocked; auto-lock disabled so token refresh keeps working"

echo "==> 3/5 Launcher"
install -m 0755 "$SCRIPT_DIR/scripts/launch.sh" "$CONF_DIR/launch.sh"
cat > "$CONF_DIR/config" <<CONF
# written by antigravity-2-users ${VERSION} — sourced by launch.sh
AG2U_NAME='$NAME'
AG2U_APP_EXEC='$APP_EXEC'
AG2U_PROFILE_HOME='$PROFILE_HOME'
CONF
mkdir -p "$APP_DIR"
rm -rf "$APP_TARGET"
osacompile -o "$APP_TARGET" -e "do shell script \"/bin/bash \" & quoted form of \"$CONF_DIR/launch.sh\" & \" >/dev/null 2>&1 &\""
if [[ -f "$APP_SOURCE/Contents/Resources/icon.icns" ]]; then
  # Icon is copied locally from the user's own Antigravity install; nothing is redistributed.
  cp "$APP_SOURCE/Contents/Resources/icon.icns" "$APP_TARGET/Contents/Resources/applet.icns"
  rm -f "$APP_TARGET/Contents/Resources/Assets.car"
fi
codesign --force --deep --sign - "$APP_TARGET" >/dev/null 2>&1 && ok "Ad-hoc signed launcher" || echo "  ! codesign failed; macOS may refuse to open the launcher (see Troubleshooting)"
touch "$APP_TARGET"
ok "Created $APP_TARGET"

echo "==> 4/5 Dock"
if [[ "$ADD_DOCK" == 1 ]]; then
  BACKUP="$CONF_DIR/dock-backup-$(date +%Y%m%d-%H%M%S).plist"
  defaults export com.apple.dock "$BACKUP" && ok "Dock settings backed up to $BACKUP"
  AG2U_APP="$APP_TARGET" AG2U_LABEL="$LABEL" python3 - <<'PY' || echo "  ! Could not update the Dock; drag the app there manually."
import os, plistlib, random, subprocess, urllib.parse
app, label = os.environ["AG2U_APP"], os.environ["AG2U_LABEL"]
url = "file://" + urllib.parse.quote(app.rstrip("/")) + "/"
dock = plistlib.loads(subprocess.run(["defaults", "export", "com.apple.dock", "-"], capture_output=True, check=True).stdout)
apps = dock.get("persistent-apps", [])
if any(a.get("tile-data", {}).get("file-data", {}).get("_CFURLString") == url for a in apps):
    print("  ✓ Already in Dock")
else:
    idx = next((i for i, a in enumerate(apps) if a.get("tile-data", {}).get("file-label") == "Antigravity"), len(apps) - 1)
    apps.insert(idx + 1, {"GUID": random.randint(10**9, 4 * 10**9), "tile-type": "file-tile",
                          "tile-data": {"file-data": {"_CFURLString": url, "_CFURLStringType": 15}, "file-label": label}})
    dock["persistent-apps"] = apps
    subprocess.run(["defaults", "import", "com.apple.dock", "-"], input=plistlib.dumps(dock), check=True)
    subprocess.run(["killall", "Dock"], check=False)
    print("  ✓ Added to Dock next to Antigravity")
PY
else
  ok "Skipped (--no-dock)"
fi

echo "==> 5/5 Done"
cat <<DONE
============================================================
Open "$LABEL" from the Dock or $APP_DIR, then sign in with your
second Google account. Check isolation any time with:
    ./scripts/verify.sh --name $NAME
Remove with:
    ./uninstall.sh --name $NAME [--purge]
============================================================
DONE
