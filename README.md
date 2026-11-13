<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — run two Antigravity profiles side by side on macOS" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>Run two Antigravity profiles side by side on macOS: a work account and a personal account, both signed in at once.</b><br>
  Each profile gets its own HOME, its own <code>--user-data-dir</code> and its own keychain, plus a launcher in your Dock. Plain Bash, no dependencies, MIT.
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <b>English</b> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **Unofficial community project.** It is not affiliated with, endorsed by or supported by Google. "Antigravity" is a trademark of Google LLC and is used here only to say which app this tool works with. This repository contains no Google code, icons or other assets. Use it with accounts you own, and follow the terms of service of every account you sign in with. Do not use it to get around usage limits or other restrictions.

## Contents

- [Why](#why)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Options](#options)
- [Verify isolation](#verify-isolation)
- [Updating](#updating)
- [Uninstall](#uninstall)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Known limitations](#known-limitations)
- [Security notes](#security-notes)
- [Contributing](#contributing)
- [License](#license)

## Why

The Antigravity desktop app signs in one Google account at a time. Its credentials live in your user-wide macOS keychain and in `~/.gemini/`. If you start a second copy with only `--user-data-dir`, it usually comes up signed in to **the same** account. The backend reads `$HOME`, not the Electron data dir.

Typical reasons to keep two profiles:

- **Work and personal kept apart.** Company code, company account and company extensions stay in one window; side projects stay in the other.
- **Client separation.** Freelancers can keep one client's workspace, settings and history away from another's.
- **Clean-room testing.** Try new extensions, settings or preview builds in a throwaway profile, and leave your daily setup alone.
- **Teaching and demos.** Present from a clean demo account while your real one keeps running.

## How it works

```
                    your Mac (one macOS user)
 ┌──────────────────────────────┬───────────────────────────────────────┐
 │ Antigravity.app (main)       │ "AG Profile B.app" (launcher)         │
 │                              │   └─ runs the SAME Antigravity binary │
 │ HOME = ~                     │ HOME = ~/.ag-profile-b                │
 │ data = ~/Library/Application │ --user-data-dir = ~/.ag-profile-b/    │
 │        Support/Antigravity   │   Library/Application Support/...     │
 │ ~/.gemini, ~/.antigravity    │ ~/.ag-profile-b/.gemini, .antigravity │
 │ keychain: login.keychain-db  │ keychain: ~/.ag-profile-b/Library/    │
 │                              │   Keychains/login.keychain-db         │
 └──────────────────────────────┴───────────────────────────────────────┘
        shared on purpose (symlinks): Desktop · Documents · Downloads
        optional (--link-dev): .gitconfig · .ssh · .zshrc · .zprofile · .npmrc
```

1. **Separate HOME.** The launcher sets `HOME=~/.ag-profile-<id>`. Everything the app keeps under `~` goes there instead: `.gemini`, `.antigravity` (including extensions) and caches.
2. **Separate Electron profile.** `--user-data-dir` points into that HOME, so windows, settings, storage and the single-instance lock are separate as well.
3. **Separate keychain.** The installer creates `~/.ag-profile-<id>/Library/Keychains/login.keychain-db` with a **random** password. That password is stored in your normal login keychain as the item `antigravity-2-users`. The profile keychain is set not to auto-lock, so background token refresh keeps working after sleep.
4. **Launcher app.** `osacompile` builds a small AppleScript app, `AG Profile <ID>.app`. It runs `~/.ag-profile-<id>/.ag2u/launch.sh`, which unlocks the profile keychain and then `exec`s the real Antigravity binary. The app gets your installed Antigravity icon (copied on your Mac at install time, never redistributed), is ad-hoc signed, and can optionally be added to the Dock.

Your main Antigravity install is never changed.

## Requirements

- macOS 13 or later is expected to work (Apple silicon or Intel; not yet tested on real hardware), with the stock `bash`, `python3`, `security`, `osacompile` and `codesign` tools
- The Antigravity desktop app installed, by default at `/Applications/Antigravity.app`
- An admin account to write to `/Applications`. Without admin rights, use `--app-dir ~/Applications`.
- A second Google account to sign in with

## Install

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

What happens, step by step:

1. It checks that you are on macOS and that Antigravity is installed.
2. It creates `~/.ag-profile-b` (mode 700) and links in Desktop, Documents and Downloads. With `--link-dev` it also links your git, ssh and shell dotfiles. Real files are never overwritten, and re-running is safe.
3. It generates a random keychain password, stores it in your login keychain, creates and unlocks the profile keychain, and turns off its auto-lock.
4. It writes `~/.ag-profile-b/.ag2u/launch.sh` and `config`, builds `/Applications/AG Profile B.app`, copies the icon and ad-hoc signs the app.
5. It backs up your Dock settings to `~/.ag-profile-b/.ag2u/dock-backup-*.plist` and adds the launcher next to Antigravity. Pass `--no-dock` to skip this.

macOS may ask once whether `security` may use the item `antigravity-2-users`. Choose **Always Allow**.

## Usage

1. Open **AG Profile B** from the Dock, Launchpad or `/Applications`.
2. The first launch is a clean, signed-out Antigravity. Sign in with your second account (see [login callback](#the-browser-login-returns-to-the-wrong-window) if the browser hands the login to the wrong window).
3. From then on, both windows can be open at the same time. Each keeps its own sign-in, settings, extensions and history.
4. To open the same project in both, use File → Open Folder in each window. Your Desktop, Documents and Downloads are visible from both. Any other absolute path works too.

Run from a terminal, which is handy for debugging. Extra arguments are passed to Antigravity:

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

More profiles: `./install.sh --name c` creates `~/.ag-profile-c` and `AG Profile C.app`.

## Options

`install.sh`

| Option | Default | Meaning |
|---|---|---|
| `--name <id>` | `b` | Profile id (`a-z`, `0-9`, `-`). Data goes to `~/.ag-profile-<id>`; the launcher is `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | The Antigravity app to run |
| `--app-dir <dir>` | `/Applications` | Where to create the launcher, e.g. `~/Applications` |
| `--no-dock` | off | Don't touch the Dock |
| `--link-dev` | off | Also link `~/.gitconfig`, `~/.ssh`, `~/.zshrc`, `~/.zprofile`, `~/.npmrc`, `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | Help / version |

`uninstall.sh`

| Option | Meaning |
|---|---|
| `--name <id>` | Profile to remove (default `b`) |
| `--app-dir <dir>` | Where the launcher was created (default `/Applications`) |
| `--purge` | Also delete profile data, its keychain and the stored password, without asking (signs that profile out) |
| `--keep-data` | Remove only the launcher and the Dock entry |

`scripts/launch.sh [--name <id>] [antigravity args…]` and `scripts/verify.sh [--name <id>]` default to `b`.

## Verify isolation

```bash
./scripts/verify.sh --name b
```

The check is read-only and prints item **names** only, never secrets:

- running processes that use this profile's `--user-data-dir`
- the profile keychain's settings (it should show `no-timeout`) and its items (`svce` / `acct`)
- Antigravity, Gemini or Jetski items in your **login** keychain
- file names in `~/.gemini` and in `~/.ag-profile-b/.gemini`

**What you want to see:** after signing in to profile B, its items appear in the **profile** keychain and its token files in `~/.ag-profile-b/.gemini`. Your main account's items stay in the login keychain.
If profile B's items show up in your login keychain instead, macOS did not pick up the profile keychain on your system. Please [open an issue](https://github.com/Xkongai/antigravity-2-users/issues) and include your macOS and Antigravity versions. You can also check by hand in **Keychain Access** → File → Add Keychain… → `~/.ag-profile-b/Library/Keychains/login.keychain-db`.

## Updating

- **Antigravity updates:** nothing to do. The launcher runs whatever binary is at `--app-source`. If the icon looks stale, re-run `./install.sh` (it is idempotent and keeps your sign-in).
- **This tool:** `git pull && ./install.sh --name b` with the same options as before. Your profile data and keychain are reused.
- **Coming from the earlier prototype** (`Antigravity Pro 2.app`, `~/.antigravity-pro2-home`): it used a fixed, publicly known keychain password. Remove `/Applications/Antigravity Pro 2.app` and its Dock icon, then either delete `~/.antigravity-pro2-home` and sign in again in the new profile, or move it to `~/.ag-profile-b` before running `./install.sh`. The installer then replaces the old password with a random one.

## Uninstall

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

Only processes started with that profile's `--user-data-dir` are stopped. Your main Antigravity, its data and your login keychain (apart from the `antigravity-2-users` item, with `--purge`) are never touched.

## FAQ

**Is this a sandbox?** No. Both profiles run as the same macOS user, with the same file permissions. This setup keeps **accounts and app state** apart; it is not a security boundary.

**Will the two profiles mix up accounts after a reboot?** They shouldn't. Each profile reads its own HOME, data dir and keychain. Use `verify.sh` to confirm this on your machine.

**Why can profile B see my Desktop and Documents?** They are symlinked into the profile HOME so you can open your projects. Anything outside the profile HOME is reachable through absolute paths anyway.

**Git or SSH doesn't work in profile B's terminal.** Its HOME has no `.gitconfig` or `.ssh`. Re-run with `--link-dev`, or set them up separately for that account.

**My `brew`, `node` or `pyenv` commands are missing.** The profile HOME has no `.zshrc`. Use `--link-dev`; the launcher also adds `/opt/homebrew/bin` and `/usr/local/bin` to PATH.

**Can I run more than two?** Yes, one `--name` per profile.

**Does it modify Antigravity.app?** No. It only reads the binary and copies the icon.

## Troubleshooting

### "AG Profile B" is damaged / can't be opened
Re-sign the launcher and clear the quarantine flag:
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
Or right-click the app → Open.

### The launcher opens nothing
Run `./scripts/launch.sh --name b` in Terminal to see errors. Check that `--app-source` points at a real `Antigravity.app`.

### The Dock icon is missing or doubled
Drag the app from `/Applications` to the Dock by hand, or re-run with `--no-dock`. To roll back the Dock: `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`.

### The browser login returns to the wrong window
Both profiles are the same app, so macOS sends the `antigravity://` sign-in callback to whichever copy it chooses, usually the main one. Workarounds:
1. Quit the main Antigravity, sign in to profile B, then reopen the main one. You only need to do this once; the sign-in persists.
2. If the sign-in page offers a code or URL to paste back into the app, use that in profile B.

### macOS keeps asking for a keychain password
Click **Always Allow** for `security` / `antigravity-2-users`. If the profile keychain still locks, run `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db`, or re-run `./install.sh`.

### Profile B is suddenly signed out or shows no models
Re-open it from the launcher; that unlocks the keychain again. Then run `verify.sh`. If the profile keychain shows a timeout, re-run `./install.sh`.

## Known limitations

- **Not tested on real hardware yet.** The scripts pass shellcheck, and during development they were run end to end against mocked macOS tools on Linux. No release has been checked on a real Mac with a current Antigravity build yet. Treat it as experimental and report what you see.
- Whether macOS really stores profile B's secrets in the profile keychain when only `HOME` is changed is **not guaranteed** and may differ between macOS versions. `verify.sh` exists for exactly that reason.
- The `antigravity://` sign-in callback can land in the wrong window (see above).
- The keychain password is passed to `security` on the command line, so for a split second it is visible to other processes run by your user.
- macOS only. Windows and Linux are not supported.
- Antigravity internals (file locations, the auth flow) can change in any update and break this approach.

## Security notes

- Each profile keychain uses a random 48-hex-character password, kept in your own login keychain. Nothing is hard-coded, and nothing ever leaves your Mac.
- The profile keychain does not auto-lock while you are logged in. This is what lets token refresh keep working, but it also means any process running as your user can read it once it is unlocked. That is the same trust model as your login keychain.
- The profile directory is created with mode `700`.
- The scripts never use `sudo`, never download anything, never change system settings except the Dock (backed up first, can be skipped), and never touch `Antigravity.app`.
- Read every script before you run it. They are short.

Found a security problem? Please open a private security advisory on GitHub instead of a public issue.

## Contributing

Issues and PRs are welcome, especially **real-Mac test reports** (macOS version, chip, Antigravity version, `verify.sh` output with emails redacted).

- Keep it plain Bash 3.2 (the version macOS ships) and make it pass `shellcheck -S style install.sh uninstall.sh scripts/*.sh`.
- Keep the README translations in step with `README.md`.
- No Google assets in the repo.

## License

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
