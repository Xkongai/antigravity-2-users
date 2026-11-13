# Changelog

## 0.1.0 — unreleased

First public release (rewrite of an earlier private prototype).

- `install.sh` with `--name`, `--app-source`, `--app-dir`, `--no-dock`, `--link-dev`.
- Random per-profile keychain password kept in your login keychain. The prototype used a fixed public password; old keychains are migrated automatically.
- Re-running the installer no longer creates self-referencing `Desktop/Desktop` links (`ln -sfn`).
- Launcher is ad-hoc re-signed after the icon swap. The Dock is backed up before it is changed, and `--no-dock` skips it.
- `uninstall.sh --purge` / `--keep-data`. Only processes started with the profile's `--user-data-dir` are stopped.
- `scripts/verify.sh` shows which keychain the credentials end up in. It prints names only, never secrets.
- CI: shellcheck plus macOS syntax checks.
