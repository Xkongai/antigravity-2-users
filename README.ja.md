<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — macOS で 2 つの Antigravity プロファイルを並べて実行" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>macOS で 2 つの Antigravity プロファイルを並べて実行。仕事用と個人用のアカウントに同時にサインインできます。</b><br>
  プロファイルごとに HOME、<code>--user-data-dir</code>、キーチェーンを分け、Dock にランチャーを追加します。素の Bash だけで書かれていて依存関係はなし、ライセンスは MIT です。
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <b>日本語</b> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **非公式のコミュニティプロジェクトです。** Google とは一切関係がなく、Google の承認やサポートも受けていません。「Antigravity」は Google LLC の商標で、ここではこのツールがどのアプリ向けかを示すためだけに使っています。このリポジトリには Google のコード、アイコン、その他の素材は一切含まれていません。ご自身が所有するアカウントで使い、サインインする各アカウントの利用規約を守ってください。利用上限などの制限を回避する目的では使わないでください。

## 目次

- [なぜ必要か](#なぜ必要か)
- [仕組み](#仕組み)
- [動作環境](#動作環境)
- [インストール](#インストール)
- [使い方](#使い方)
- [オプション](#オプション)
- [分離を確認する](#分離を確認する)
- [アップデート](#アップデート)
- [アンインストール](#アンインストール)
- [よくある質問](#よくある質問)
- [トラブルシューティング](#トラブルシューティング)
- [既知の制限](#既知の制限)
- [セキュリティについて](#セキュリティについて)
- [コントリビュート](#コントリビュート)
- [ライセンス](#ライセンス)

## なぜ必要か

Antigravity デスクトップアプリは一度に 1 つの Google アカウントにしかサインインできません。認証情報はユーザー共通の macOS キーチェーンと `~/.gemini/` に保存されます。`--user-data-dir` だけを変えて 2 つ目を起動しても、たいていは**同じ**アカウントでサインインした状態で開きます。バックエンドが読むのは Electron のデータディレクトリではなく `$HOME` だからです。

2 つのプロファイルを使い分けたくなるのは、たとえば次のような場合です。

- **仕事と個人を分ける**：会社のコード、会社のアカウント、会社指定の拡張機能は一方のウィンドウに、個人プロジェクトはもう一方に置けます。
- **クライアントごとに分ける**：フリーランスなら、クライアントごとのワークスペース、設定、履歴を分けておけます。
- **まっさらな検証環境**：新しい拡張機能や設定、プレビュー版を使い捨てのプロファイルで試し、普段の環境には手を付けずに済みます。
- **講義やデモ**：クリーンなデモ用アカウントで画面共有し、普段のアカウントはそのまま動かしておけます。

## 仕組み

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

1. **HOME を分ける**：ランチャーは `HOME=~/.ag-profile-<id>` を設定します。アプリが `~` の下に置くもの（`.gemini`、拡張機能を含む `.antigravity`、キャッシュ）はすべてそちらに保存されます。
2. **Electron プロファイルを分ける**：`--user-data-dir` をその HOME の中に向けるので、ウィンドウ、設定、ストレージ、単一インスタンスのロックも別々になります。
3. **キーチェーンを分ける**：インストーラーは `~/.ag-profile-<id>/Library/Keychains/login.keychain-db` を**ランダムな**パスワードで作成します。そのパスワードは普段のログインキーチェーンに `antigravity-2-users` という項目名で保存されます。プロファイル用キーチェーンは自動ロックしない設定なので、スリープから復帰してもバックグラウンドのトークン更新が止まりません。
4. **ランチャーアプリ**：`osacompile` で小さな AppleScript アプリ `AG Profile <ID>.app` を作ります。このアプリは `~/.ag-profile-<id>/.ag2u/launch.sh` を実行し、プロファイル用キーチェーンのロックを解除してから本物の Antigravity を `exec` します。アイコンはインストール済みの Antigravity からインストール時に手元でコピーするだけで、再配布はしません。アプリには ad-hoc 署名を付け、希望すれば Dock にも追加できます。

メインの Antigravity には一切手を加えません。

## 動作環境

- macOS 13 以降で動作する見込みです（Apple シリコン / Intel。実機ではまだ未検証）。標準の `bash`、`python3`、`security`、`osacompile`、`codesign` を使います。
- Antigravity デスクトップアプリがインストールされていること（既定は `/Applications/Antigravity.app`）
- `/Applications` への書き込みには管理者アカウントが必要です。管理者でない場合は `--app-dir ~/Applications` を指定してください。
- サインインに使う 2 つ目の Google アカウント

## インストール

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

インストーラーは次の順に処理します。

1. macOS であること、Antigravity がインストールされていることを確認します。
2. `~/.ag-profile-b`（パーミッション 700）を作り、デスクトップ・書類・ダウンロードをリンクします。`--link-dev` を付けると git、ssh、シェルの設定ファイルもリンクします。既存の実ファイルは上書きせず、何度実行しても安全です。
3. ランダムなキーチェーン用パスワードを作ってログインキーチェーンに保存し、プロファイル用キーチェーンを作成・ロック解除して、自動ロックを無効にします。
4. `~/.ag-profile-b/.ag2u/launch.sh` と `config` を書き出し、`/Applications/AG Profile B.app` を作成して、アイコンをコピーし ad-hoc 署名します。
5. Dock の設定を `~/.ag-profile-b/.ag2u/dock-backup-*.plist` にバックアップし、ランチャーを Antigravity の隣に追加します。Dock を変えたくない場合は `--no-dock` を付けてください。

`security` が項目 `antigravity-2-users` を使ってよいか、macOS から一度確認されることがあります。**常に許可** を選んでください。

## 使い方

1. Dock、Launchpad、または `/Applications` から **AG Profile B** を開きます。
2. 初回はまっさらな、サインインしていない Antigravity が開きます。2 つ目のアカウントでサインインしてください。ブラウザーがサインイン結果を別のウィンドウに渡してしまう場合は[ログインのコールバック](#ブラウザーでのログイン後別のウィンドウに戻ってしまう)を参照してください。
3. 以降は 2 つのウィンドウを同時に開けます。サインイン状態、設定、拡張機能、履歴はそれぞれ別々です。
4. 同じプロジェクトを両方で開くには、それぞれのウィンドウで「ファイル → フォルダーを開く」を使います。デスクトップ、書類、ダウンロードはどちらからも見えますし、ほかの絶対パスも使えます。

ターミナルから起動することもでき、デバッグに便利です。余分な引数は Antigravity にそのまま渡されます。

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

プロファイルを増やすには、`./install.sh --name c` で `~/.ag-profile-c` と `AG Profile C.app` が作られます。

## オプション

`install.sh`

| オプション | 既定値 | 説明 |
|---|---|---|
| `--name <id>` | `b` | プロファイル ID（`a-z`、`0-9`、`-`）。データは `~/.ag-profile-<id>`、ランチャーは `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | 起動する Antigravity アプリ |
| `--app-dir <dir>` | `/Applications` | ランチャーを作る場所（例：`~/Applications`） |
| `--no-dock` | オフ | Dock を変更しない |
| `--link-dev` | オフ | `~/.gitconfig`、`~/.ssh`、`~/.zshrc`、`~/.zprofile`、`~/.npmrc`、`~/.config/git` もリンクする |
| `-h`, `--help` / `-V`, `--version` | | ヘルプ / バージョン |

`uninstall.sh`

| オプション | 説明 |
|---|---|
| `--name <id>` | 削除するプロファイル（既定は `b`） |
| `--app-dir <dir>` | ランチャーを作った場所（既定は `/Applications`） |
| `--purge` | 確認なしで、プロファイルのデータ、キーチェーン、保存されたパスワードも削除する（そのプロファイルはサインアウトされます） |
| `--keep-data` | ランチャーと Dock の項目だけを削除する |

`scripts/launch.sh [--name <id>] [Antigravity の引数…]` と `scripts/verify.sh [--name <id>]` の既定のプロファイルは `b` です。

## 分離を確認する

```bash
./scripts/verify.sh --name b
```

読み取り専用のチェックで、表示するのは項目の**名前**だけです。秘密情報は表示しません。

- このプロファイルの `--user-data-dir` で動いているプロセス
- プロファイル用キーチェーンの設定（`no-timeout` と表示されるはずです）と、その中の項目（`svce` / `acct`）
- **ログイン**キーチェーン内の Antigravity、Gemini、Jetski 関連の項目
- `~/.gemini` と `~/.ag-profile-b/.gemini` のファイル名

**期待される結果**：プロファイル B でサインインしたあと、その項目は**プロファイル用**キーチェーンに、トークンファイルは `~/.ag-profile-b/.gemini` に入っていること。メインアカウントの項目はログインキーチェーンに残ります。
もしプロファイル B の項目がログインキーチェーンに入っていたら、お使いのシステムではプロファイル用キーチェーンが使われていません。macOS と Antigravity のバージョンを添えて [issue を作成](https://github.com/Xkongai/antigravity-2-users/issues)してください。手動で確認する場合は、**キーチェーンアクセス** → ファイル → キーチェーンを追加… → `~/.ag-profile-b/Library/Keychains/login.keychain-db` を選びます。

## アップデート

- **Antigravity のアップデート**：何もする必要はありません。ランチャーは `--app-source` にあるアプリをそのまま起動します。アイコンが古いままなら `./install.sh` をもう一度実行してください。何度実行しても大丈夫で、サインイン状態も保たれます。
- **このツールのアップデート**：前回と同じオプションで `git pull && ./install.sh --name b` を実行します。プロファイルのデータとキーチェーンはそのまま使われます。
- **初期のプロトタイプから移行する場合**（`Antigravity Pro 2.app`、`~/.antigravity-pro2-home`）：プロトタイプは固定の、公開されているキーチェーンパスワードを使っていました。まず `/Applications/Antigravity Pro 2.app` とその Dock アイコンを削除してください。そのうえで、`~/.antigravity-pro2-home` を削除して新しいプロファイルでサインインし直すか、`./install.sh` を実行する前に `~/.ag-profile-b` へ移動します。後者の場合、インストーラーが古いパスワードをランダムなものに置き換えます。

## アンインストール

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

止めるのは、そのプロファイルの `--user-data-dir` で起動したプロセスだけです。メインの Antigravity、そのデータ、ログインキーチェーンには触れません（`--purge` を指定したときに `antigravity-2-users` の項目を削除するのだけが例外です）。

## よくある質問

**これはサンドボックスですか？** いいえ。どちらのプロファイルも同じ macOS ユーザー、同じファイル権限で動きます。分けているのは**アカウントとアプリの状態**で、セキュリティ境界ではありません。

**再起動したらアカウントが入れ替わりませんか？** その心配はないはずです。各プロファイルはそれぞれの HOME、データディレクトリ、キーチェーンを読みます。お使いのマシンで `verify.sh` を実行して確かめてください。

**プロファイル B からデスクトップや書類が見えるのはなぜ？** プロジェクトを開けるように、プロファイルの HOME にシンボリックリンクしてあるからです。プロファイル HOME の外にあるものも、もともと絶対パスでアクセスできます。

**プロファイル B のターミナルで git や SSH が使えません。** その HOME には `.gitconfig` も `.ssh` もないためです。`--link-dev` を付けて再実行するか、そのアカウント用に別途設定してください。

**`brew`、`node`、`pyenv` などのコマンドが見つかりません。** プロファイルの HOME に `.zshrc` がないためです。`--link-dev` を使ってください。ランチャーは `/opt/homebrew/bin` と `/usr/local/bin` も PATH に追加します。

**3 つ以上動かせますか？** はい。プロファイルごとに `--name` を変えてください。

**Antigravity.app を書き換えますか？** いいえ。本体を読み取り、アイコンをコピーするだけです。

## トラブルシューティング

### 「AG Profile B」が壊れている、または開けないと表示される
ランチャーに署名し直し、隔離属性（quarantine）を外してください。
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
または、アプリを右クリック → 開く。

### ランチャーをクリックしても何も開かない
ターミナルで `./scripts/launch.sh --name b` を実行してエラーを確認し、`--app-source` が実在する `Antigravity.app` を指しているか確かめてください。

### Dock のアイコンが消えた、または 2 つになった
`/Applications` からアプリを Dock に手動でドラッグするか、`--no-dock` を付けて再実行してください。Dock を元に戻すには `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock` を実行します。

### ブラウザーでのログイン後、別のウィンドウに戻ってしまう
2 つのプロファイルは実は同じアプリなので、macOS は `antigravity://` のサインインコールバックを自分で選んだ方（たいていメイン）に渡します。対処法：
1. メインの Antigravity を終了し、プロファイル B でサインインしてから、メインを開き直します。サインイン状態は保存されるので、これは一度だけで済みます。
2. サインインページにアプリへ貼り付けるコードや URL が表示される場合は、それをプロファイル B に貼り付けます。

### キーチェーンのパスワードを何度も聞かれる
`security` / `antigravity-2-users` に対して **常に許可** を選んでください。それでもプロファイル用キーチェーンがロックされる場合は、`security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db` を実行するか、`./install.sh` を再実行してください。

### プロファイル B が急にサインアウトされた、またはモデルが使えなくなった
ランチャーから開き直すと、キーチェーンのロックがもう一度解除されます。そのあと `verify.sh` を実行し、プロファイル用キーチェーンにタイムアウトが設定されていたら `./install.sh` を再実行してください。

## 既知の制限

- **実機ではまだテストしていません。** スクリプトは shellcheck を通っていて、開発中に Linux 上でモックした macOS ツールを使って最初から最後まで実行済みです。ただし、最新の Antigravity を入れた実際の Mac で確認したリリースはまだありません。実験的なツールとして扱い、気づいたことを報告してください。
- `HOME` を変えただけで macOS が本当にプロファイル B の秘密情報をプロファイル用キーチェーンに保存するかは**保証されておらず**、macOS のバージョンによって変わる可能性があります。`verify.sh` はまさにそのためにあります。
- `antigravity://` のサインインコールバックが別のウィンドウに届くことがあります（上記参照）。
- キーチェーンのパスワードはコマンドライン引数として `security` に渡されるため、ほんの一瞬、同じユーザーのほかのプロセスから見えます。
- macOS 専用です。Windows と Linux には対応していません。
- Antigravity の内部仕様（ファイルの場所、サインインの流れ）はアップデートでいつでも変わる可能性があり、そうなるとこの方法は使えなくなります。

## セキュリティについて

- プロファイル用キーチェーンには 16 進数 48 文字のランダムなパスワードを使い、それはあなた自身のログインキーチェーンに保存されます。ハードコードされたものは何もなく、データが Mac の外に出ることもありません。
- ログインしている間、プロファイル用キーチェーンは自動ロックしません。そのおかげでトークンの更新が続くのですが、ロック解除後はあなたのユーザーとして動くどのプロセスからも読めるということでもあります。これはログインキーチェーンと同じ信頼モデルです。
- プロファイルのディレクトリはパーミッション `700` で作成されます。
- スクリプトは `sudo` を使わず、何もダウンロードせず、Dock 以外のシステム設定を変えず（Dock も事前にバックアップし、スキップも可能）、`Antigravity.app` にも触れません。
- 実行する前に、すべてのスクリプトに目を通してください。どれも短いものです。

セキュリティ上の問題を見つけた場合は、公開の issue ではなく、GitHub の非公開のセキュリティアドバイザリーで報告してください。

## コントリビュート

Issue と PR を歓迎します。特に**実機でのテスト報告**（macOS のバージョン、チップ、Antigravity のバージョン、メールアドレスを伏せた `verify.sh` の出力）は助かります。

- macOS 標準の Bash 3.2 で動く書き方を守り、`shellcheck -S style install.sh uninstall.sh scripts/*.sh` を通るようにしてください。
- 各言語の README は `README.md` と内容をそろえてください。
- リポジトリに Google の素材は入れないでください。

## ライセンス

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
