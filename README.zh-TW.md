<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users：在 macOS 上並排執行兩個 Antigravity 設定檔" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>在 macOS 上並排執行兩個 Antigravity 設定檔：工作帳號和個人帳號同時線上。</b><br>
  每個設定檔都有獨立的 HOME、獨立的 <code>--user-data-dir</code> 和獨立的鑰匙圈，Dock 裡還會多一個啟動器。純 Bash 編寫，零相依套件，MIT 授權。
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <b>繁體中文</b> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **這是非官方的社群專案**，與 Google 沒有任何關聯，也沒有獲得 Google 的認可或支援。"Antigravity" 是 Google LLC 的商標，這裡提到它只是為了說明本工具配合哪個應用使用。本倉庫不包含任何 Google 的程式碼、圖示或其他素材。請只用你本人擁有的帳號，並遵守每個登入帳號的服務條款。不要用它規避用量限制或其他限制。

## 目錄

- [為什麼需要它](#為什麼需要它)
- [工作原理](#工作原理)
- [環境要求](#環境要求)
- [安裝](#安裝)
- [使用方法](#使用方法)
- [參數](#參數)
- [驗證隔離效果](#驗證隔離效果)
- [更新](#更新)
- [解除安裝](#解除安裝)
- [常見問題](#常見問題)
- [故障排除](#故障排除)
- [已知限制](#已知限制)
- [安全說明](#安全說明)
- [參與貢獻](#參與貢獻)
- [授權條款](#授權條款)

## 為什麼需要它

Antigravity 桌面端一次只能登入一個 Google 帳號，憑據存放在使用者級的 macOS 鑰匙圈和 `~/.gemini/` 裡。如果只加 `--user-data-dir` 再開一個，通常會直接登入成**同一個**帳號，因為後端讀取的是 `$HOME`，而不是 Electron 的資料目錄。

常見的使用場景：

- **工作和個人分開**：公司程式碼、公司帳號和公司要求的擴充套件放在一個視窗，個人專案放在另一個視窗。
- **客戶隔離**：自由工作者可以把不同客戶的工作區、設定和歷史記錄分開。
- **乾淨的測試環境**：在一個可以隨時丟棄的設定檔裡試新擴充套件、新設定或預覽版，日常環境保持不動。
- **教學和演示**：用乾淨的演示帳號投屏，真實帳號照常執行。

## 工作原理

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

1. **獨立的 HOME**：啟動器把 `HOME` 設為 `~/.ag-profile-<id>`。應用原本存在 `~` 下的東西都會改存到這裡，包括 `.gemini`、`.antigravity`（含擴充套件）和快取。
2. **獨立的 Electron 設定檔**：`--user-data-dir` 指向這個 HOME 裡面，所以視窗、設定、儲存和單例項鎖也是各自獨立的。
3. **獨立的鑰匙圈**：安裝指令碼會建立 `~/.ag-profile-<id>/Library/Keychains/login.keychain-db`，密碼是**隨機生成**的，儲存在你平時用的登入鑰匙圈裡，條目名為 `antigravity-2-users`。這個鑰匙圈設定為不自動鎖定，所以電腦休眠喚醒後，後臺重新整理令牌也不會失敗。
4. **啟動器**：用 `osacompile` 生成一個小的 AppleScript 應用 `AG Profile <ID>.app`。它會執行 `~/.ag-profile-<id>/.ag2u/launch.sh`，先解鎖設定檔鑰匙圈，再用 `exec` 啟動真正的 Antigravity。啟動器的圖示取自你本機已安裝的 Antigravity（安裝時在本機複製，不會再分發），會做 ad-hoc 簽名，也可以選擇加到 Dock 裡。

主程式 Antigravity 不會被改動。

## 環境要求

- macOS 13 及以上，預計可以執行（Apple 晶片和 Intel 均可，尚未在真機上測試），需要系統自帶的 `bash`、`python3`、`security`、`osacompile` 和 `codesign`
- 已安裝 Antigravity 桌面端，預設路徑是 `/Applications/Antigravity.app`
- 寫入 `/Applications` 需要管理員帳號；如果不是管理員，請加 `--app-dir ~/Applications`
- 一個用來登入的第二個 Google 帳號

## 安裝

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

安裝指令碼按以下步驟執行：

1. 檢查是不是 macOS，以及是否裝了 Antigravity。
2. 建立 `~/.ag-profile-b`（許可權 700），把桌面、文件、下載三個資料夾連結進去。加 `--link-dev` 時還會連結 git、ssh 和 shell 的設定檔。已有的真實檔案不會被覆蓋，重複執行也是安全的。
3. 生成隨機的鑰匙圈密碼並存進登入鑰匙圈，然後建立並解鎖設定檔鑰匙圈，關閉它的自動鎖定。
4. 寫入 `~/.ag-profile-b/.ag2u/launch.sh` 和 `config`，生成 `/Applications/AG Profile B.app`，複製圖示並做 ad-hoc 簽名。
5. 把 Dock 設定備份到 `~/.ag-profile-b/.ag2u/dock-backup-*.plist`，再把啟動器放到 Antigravity 旁邊。不想改 Dock 的話，加 `--no-dock`。

macOS 可能會詢問一次是否允許 `security` 使用 `antigravity-2-users` 這個條目，請選擇**始終允許**。

## 使用方法

1. 從 Dock、啟動臺或 `/Applications` 開啟 **AG Profile B**。
2. 第一次開啟是一個乾淨、未登入的 Antigravity，用第二個帳號登入即可。如果瀏覽器把登入結果交給了錯誤的視窗，請看[登入回撥問題](#瀏覽器登入後跳回了錯誤的視窗)。
3. 之後兩個視窗可以同時開啟，登入狀態、設定、擴充套件和歷史記錄各自獨立。
4. 兩邊要開啟同一個專案時，在各自視窗裡用"檔案 → 開啟資料夾"即可。桌面、文件和下載在兩邊都能看到，其他絕對路徑也都能用。

也可以從終端啟動，方便除錯。多餘的參數會原樣傳給 Antigravity：

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

需要更多設定檔時，`./install.sh --name c` 會建立 `~/.ag-profile-c` 和 `AG Profile C.app`。

## 參數

`install.sh`

| 參數 | 預設值 | 說明 |
|---|---|---|
| `--name <id>` | `b` | 設定檔 ID（`a-z`、`0-9`、`-`）。資料存在 `~/.ag-profile-<id>`，啟動器名為 `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | 要啟動的 Antigravity 應用 |
| `--app-dir <dir>` | `/Applications` | 啟動器的存放位置，例如 `~/Applications` |
| `--no-dock` | 關閉 | 不修改 Dock |
| `--link-dev` | 關閉 | 同時連結 `~/.gitconfig`、`~/.ssh`、`~/.zshrc`、`~/.zprofile`、`~/.npmrc` 和 `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | 幫助 / 版本號 |

`uninstall.sh`

| 參數 | 說明 |
|---|---|
| `--name <id>` | 要刪除的設定檔（預設 `b`） |
| `--app-dir <dir>` | 啟動器所在位置（預設 `/Applications`） |
| `--purge` | 不再詢問，同時刪除設定檔資料、它的鑰匙圈和儲存的密碼（該設定檔會登出） |
| `--keep-data` | 只刪除啟動器和 Dock 圖示 |

`scripts/launch.sh [--name <id>] [antigravity 参数…]` 和 `scripts/verify.sh [--name <id>]` 的預設設定檔都是 `b`。

## 驗證隔離效果

```bash
./scripts/verify.sh --name b
```

這個檢查是隻讀的，只輸出條目**名稱**，不會輸出任何金鑰：

- 正在使用這個設定檔 `--user-data-dir` 的程序
- 設定檔鑰匙圈的設定（應顯示 `no-timeout`）和其中的條目（`svce` / `acct`）
- 你的**登入**鑰匙圈裡與 Antigravity、Gemini、Jetski 相關的條目
- `~/.gemini` 和 `~/.ag-profile-b/.gemini` 裡的檔名

**正常的結果**：在設定檔 B 登入之後，它的條目出現在**設定檔**鑰匙圈裡，令牌檔案出現在 `~/.ag-profile-b/.gemini` 裡；主帳號的條目留在登入鑰匙圈裡。
如果設定檔 B 的條目反而出現在登入鑰匙圈裡，說明你的系統沒有用上設定檔鑰匙圈。請[提交 issue](https://github.com/Xkongai/antigravity-2-users/issues)，並附上 macOS 和 Antigravity 的版本號。你也可以手動檢查：開啟**鑰匙圈存取** → 檔案 → 新增鑰匙圈… → 選擇 `~/.ag-profile-b/Library/Keychains/login.keychain-db`。

## 更新

- **Antigravity 更新時**：不用做任何事，啟動器執行的就是 `--app-source` 裡的程式。如果圖示沒跟著變，重新執行一次 `./install.sh` 即可。它可以重複執行，不會丟失登入狀態。
- **更新本工具**：執行 `git pull && ./install.sh --name b`，參數和之前保持一致。原來的設定檔資料和鑰匙圈會繼續使用。
- **從早期原型遷移**（`Antigravity Pro 2.app`、`~/.antigravity-pro2-home`）：原型用的是固定、公開的鑰匙圈密碼。先刪除 `/Applications/Antigravity Pro 2.app` 和它的 Dock 圖示，然後二選一：刪除 `~/.antigravity-pro2-home`，在新設定檔裡重新登入；或者把它改名為 `~/.ag-profile-b` 再執行 `./install.sh`，安裝指令碼會把舊密碼換成隨機密碼。

## 解除安裝

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

只會停止用這個設定檔的 `--user-data-dir` 啟動的程序。主程式 Antigravity、它的資料和你的登入鑰匙圈都不會被動到；唯一的例外是加 `--purge` 時會刪除 `antigravity-2-users` 這個條目。

## 常見問題

**這是沙盒嗎？** 不是。兩個設定檔以同一個 macOS 使用者身份執行，檔案許可權也一樣。它隔離的是**帳號和應用狀態**，不是安全邊界。

**重啟後會串號嗎？** 不應該會。每個設定檔讀取各自的 HOME、資料目錄和鑰匙圈。可以用 `verify.sh` 在你自己的電腦上確認。

**為什麼設定檔 B 能看到我的桌面和文件？** 因為它們被軟連結進了設定檔的 HOME，方便你開啟專案。設定檔 HOME 之外的東西本來也能用絕對路徑訪問。

**設定檔 B 的終端裡 git 或 SSH 用不了。** 因為它的 HOME 裡沒有 `.gitconfig` 和 `.ssh`。加 `--link-dev` 重新安裝，或者為這個帳號單獨設定檔。

**找不到 `brew`、`node`、`pyenv` 等命令。** 因為設定檔 HOME 裡沒有 `.zshrc`。請使用 `--link-dev`；另外啟動器也會把 `/opt/homebrew/bin` 和 `/usr/local/bin` 加進 PATH。

**能開兩個以上嗎？** 可以，每個設定檔用一個不同的 `--name`。

**會修改 Antigravity.app 嗎？** 不會。只會讀取它的程式檔案，並複製圖示。

## 故障排除

### 提示 "AG Profile B" 已損壞或無法開啟
重新簽名，並清除隔離標記：
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
或者右鍵點選應用 → 開啟。

### 點選啟動器後什麼都沒有開啟
在終端執行 `./scripts/launch.sh --name b` 檢視報錯，並檢查 `--app-source` 是否指向一個真實存在的 `Antigravity.app`。

### Dock 圖示不見了或出現兩個
手動把應用從 `/Applications` 拖到 Dock，或者加 `--no-dock` 重新執行。要恢復原來的 Dock：`defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`。

### 瀏覽器登入後跳回了錯誤的視窗
兩個設定檔其實是同一個應用，macOS 會把 `antigravity://` 登入回撥交給它自己選的那一個，通常是主程式。解決辦法：
1. 先退出主程式 Antigravity，在設定檔 B 裡完成登入，再重新開啟主程式。這只需要做一次，登入狀態會保留。
2. 如果登入頁面提供可以複製回應用的程式碼或 URL，在設定檔 B 裡貼上使用。

### macOS 反覆要求輸入鑰匙圈密碼
對 `security` / `antigravity-2-users` 選擇**始終允許**。如果設定檔鑰匙圈還是會鎖定，執行 `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db`，或者重新執行 `./install.sh`。

### 設定檔 B 突然登出，或者模型顯示不可用
從啟動器重新開啟一次，它會再次解鎖鑰匙圈。然後執行 `verify.sh`。如果設定檔鑰匙圈顯示有超時設定，重新執行 `./install.sh`。

## 已知限制

- **尚未在真機上測試。** 指令碼透過了 shellcheck，開發期間也在 Linux 上用模擬的 macOS 工具完整跑過一遍，但還沒有任何版本在裝有最新 Antigravity 的真實 Mac 上驗證過。請當作實驗性工具使用，並反饋你遇到的情況。
- 只改 `HOME` 時，macOS 是否真的會把設定檔 B 的金鑰存進設定檔鑰匙圈，**並沒有保證**，不同 macOS 版本也可能不一樣。`verify.sh` 就是為此準備的。
- `antigravity://` 登入回撥可能會跳到錯誤的視窗（見上文）。
- 鑰匙圈密碼是透過命令列參數傳給 `security` 的，在極短的時間內，你這個使用者下的其他程序能看到它。
- 只支援 macOS，不支援 Windows 和 Linux。
- Antigravity 的內部實現（檔案位置、登入流程）隨時可能在更新中改變，導致這個方案失效。

## 安全說明

- 每個設定檔鑰匙圈都用 48 位十六進位制的隨機密碼，儲存在你自己的登入鑰匙圈裡。沒有任何寫死的密碼，也沒有任何資料離開你的 Mac。
- 只要你處於登入狀態，設定檔鑰匙圈就不會自動鎖定。這正是令牌能持續重新整理的原因，但也意味著鑰匙圈解鎖後，任何以你的使用者身份執行的程序都能讀取它。這和登入鑰匙圈本身的信任模型相同。
- 設定檔目錄的許可權是 `700`。
- 指令碼不使用 `sudo`，不下載任何東西，除了 Dock 之外不改任何系統設定（Dock 修改前會備份，也可以跳過），也不動 `Antigravity.app`。
- 執行前請先讀一遍所有指令碼，它們都很短。

如果發現安全問題，請在 GitHub 上提交私密的安全公告（security advisory），不要提公開 issue。

## 參與貢獻

歡迎提交 issue 和 PR，尤其歡迎**真機測試報告**：請附上 macOS 版本、晶片、Antigravity 版本，以及去掉郵箱後的 `verify.sh` 輸出。

- 只用 macOS 自帶的 Bash 3.2 語法，並確保能透過 `shellcheck -S style install.sh uninstall.sh scripts/*.sh`。
- 各語言的 README 要和 `README.md` 保持同步。
- 倉庫裡不要放任何 Google 的素材。

## 授權條款

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
