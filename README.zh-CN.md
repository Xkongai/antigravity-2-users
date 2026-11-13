<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users：在 macOS 上并排运行两个 Antigravity 配置" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>在 macOS 上并排运行两个 Antigravity 配置：工作账号和个人账号同时在线。</b><br>
  每个配置都有独立的 HOME、独立的 <code>--user-data-dir</code> 和独立的钥匙串，Dock 里还会多一个启动器。纯 Bash 编写，零依赖，MIT 协议。
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <b>简体中文</b> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **这是非官方的社区项目**，与 Google 没有任何关联，也没有获得 Google 的认可或支持。"Antigravity" 是 Google LLC 的商标，这里提到它只是为了说明本工具配合哪个应用使用。本仓库不包含任何 Google 的代码、图标或其他素材。请只用你本人拥有的账号，并遵守每个登录账号的服务条款。不要用它规避用量限制或其他限制。

## 目录

- [为什么需要它](#为什么需要它)
- [工作原理](#工作原理)
- [环境要求](#环境要求)
- [安装](#安装)
- [使用方法](#使用方法)
- [参数](#参数)
- [验证隔离效果](#验证隔离效果)
- [更新](#更新)
- [卸载](#卸载)
- [常见问题](#常见问题)
- [故障排除](#故障排除)
- [已知限制](#已知限制)
- [安全说明](#安全说明)
- [参与贡献](#参与贡献)
- [许可证](#许可证)

## 为什么需要它

Antigravity 桌面端一次只能登录一个 Google 账号，凭据存放在用户级的 macOS 钥匙串和 `~/.gemini/` 里。如果只加 `--user-data-dir` 再开一个，通常会直接登录成**同一个**账号，因为后端读取的是 `$HOME`，而不是 Electron 的数据目录。

常见的使用场景：

- **工作和个人分开**：公司代码、公司账号和公司要求的扩展放在一个窗口，个人项目放在另一个窗口。
- **客户隔离**：自由职业者可以把不同客户的工作区、设置和历史记录分开。
- **干净的测试环境**：在一个可以随时丢弃的配置里试新扩展、新设置或预览版，日常环境保持不动。
- **教学和演示**：用干净的演示账号投屏，真实账号照常运行。

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

1. **独立的 HOME**：启动器把 `HOME` 设为 `~/.ag-profile-<id>`。应用原本存在 `~` 下的东西都会改存到这里，包括 `.gemini`、`.antigravity`（含扩展）和缓存。
2. **独立的 Electron 配置**：`--user-data-dir` 指向这个 HOME 里面，所以窗口、设置、存储和单实例锁也是各自独立的。
3. **独立的钥匙串**：安装脚本会创建 `~/.ag-profile-<id>/Library/Keychains/login.keychain-db`，密码是**随机生成**的，保存在你平时用的登录钥匙串里，条目名为 `antigravity-2-users`。这个钥匙串设置为不自动锁定，所以电脑休眠唤醒后，后台刷新令牌也不会失败。
4. **启动器**：用 `osacompile` 生成一个小的 AppleScript 应用 `AG Profile <ID>.app`。它会运行 `~/.ag-profile-<id>/.ag2u/launch.sh`，先解锁配置钥匙串，再用 `exec` 启动真正的 Antigravity。启动器的图标取自你本机已安装的 Antigravity（安装时在本机复制，不会再分发），会做 ad-hoc 签名，也可以选择加到 Dock 里。

主程序 Antigravity 不会被改动。

## 环境要求

- macOS 13 及以上，预计可以运行（Apple 芯片和 Intel 均可，尚未在真机上测试），需要系统自带的 `bash`、`python3`、`security`、`osacompile` 和 `codesign`
- 已安装 Antigravity 桌面端，默认路径是 `/Applications/Antigravity.app`
- 写入 `/Applications` 需要管理员账号；如果不是管理员，请加 `--app-dir ~/Applications`
- 一个用来登录的第二个 Google 账号

## 安装

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

安装脚本按以下步骤执行：

1. 检查是不是 macOS，以及是否装了 Antigravity。
2. 创建 `~/.ag-profile-b`（权限 700），把桌面、文稿、下载三个文件夹链接进去。加 `--link-dev` 时还会链接 git、ssh 和 shell 的配置文件。已有的真实文件不会被覆盖，重复运行也是安全的。
3. 生成随机的钥匙串密码并存进登录钥匙串，然后创建并解锁配置钥匙串，关闭它的自动锁定。
4. 写入 `~/.ag-profile-b/.ag2u/launch.sh` 和 `config`，生成 `/Applications/AG Profile B.app`，复制图标并做 ad-hoc 签名。
5. 把 Dock 设置备份到 `~/.ag-profile-b/.ag2u/dock-backup-*.plist`，再把启动器放到 Antigravity 旁边。不想改 Dock 的话，加 `--no-dock`。

macOS 可能会询问一次是否允许 `security` 使用 `antigravity-2-users` 这个条目，请选择**始终允许**。

## 使用方法

1. 从 Dock、启动台或 `/Applications` 打开 **AG Profile B**。
2. 第一次打开是一个干净、未登录的 Antigravity，用第二个账号登录即可。如果浏览器把登录结果交给了错误的窗口，请看[登录回调问题](#浏览器登录后跳回了错误的窗口)。
3. 之后两个窗口可以同时打开，登录状态、设置、扩展和历史记录各自独立。
4. 两边要打开同一个项目时，在各自窗口里用"文件 → 打开文件夹"即可。桌面、文稿和下载在两边都能看到，其他绝对路径也都能用。

也可以从终端启动，方便调试。多余的参数会原样传给 Antigravity：

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

需要更多配置时，`./install.sh --name c` 会创建 `~/.ag-profile-c` 和 `AG Profile C.app`。

## 参数

`install.sh`

| 参数 | 默认值 | 说明 |
|---|---|---|
| `--name <id>` | `b` | 配置 ID（`a-z`、`0-9`、`-`）。数据存在 `~/.ag-profile-<id>`，启动器名为 `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | 要启动的 Antigravity 应用 |
| `--app-dir <dir>` | `/Applications` | 启动器的存放位置，例如 `~/Applications` |
| `--no-dock` | 关闭 | 不修改 Dock |
| `--link-dev` | 关闭 | 同时链接 `~/.gitconfig`、`~/.ssh`、`~/.zshrc`、`~/.zprofile`、`~/.npmrc` 和 `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | 帮助 / 版本号 |

`uninstall.sh`

| 参数 | 说明 |
|---|---|
| `--name <id>` | 要删除的配置（默认 `b`） |
| `--app-dir <dir>` | 启动器所在位置（默认 `/Applications`） |
| `--purge` | 不再询问，同时删除配置数据、它的钥匙串和保存的密码（该配置会退出登录） |
| `--keep-data` | 只删除启动器和 Dock 图标 |

`scripts/launch.sh [--name <id>] [antigravity 参数…]` 和 `scripts/verify.sh [--name <id>]` 的默认配置都是 `b`。

## 验证隔离效果

```bash
./scripts/verify.sh --name b
```

这个检查是只读的，只输出条目**名称**，不会输出任何密钥：

- 正在使用这个配置 `--user-data-dir` 的进程
- 配置钥匙串的设置（应显示 `no-timeout`）和其中的条目（`svce` / `acct`）
- 你的**登录**钥匙串里与 Antigravity、Gemini、Jetski 相关的条目
- `~/.gemini` 和 `~/.ag-profile-b/.gemini` 里的文件名

**正常的结果**：在配置 B 登录之后，它的条目出现在**配置**钥匙串里，令牌文件出现在 `~/.ag-profile-b/.gemini` 里；主账号的条目留在登录钥匙串里。
如果配置 B 的条目反而出现在登录钥匙串里，说明你的系统没有用上配置钥匙串。请[提交 issue](https://github.com/Xkongai/antigravity-2-users/issues)，并附上 macOS 和 Antigravity 的版本号。你也可以手动检查：打开**钥匙串访问** → 文件 → 添加钥匙串… → 选择 `~/.ag-profile-b/Library/Keychains/login.keychain-db`。

## 更新

- **Antigravity 更新时**：不用做任何事，启动器运行的就是 `--app-source` 里的程序。如果图标没跟着变，重新运行一次 `./install.sh` 即可。它可以重复运行，不会丢失登录状态。
- **更新本工具**：执行 `git pull && ./install.sh --name b`，参数和之前保持一致。原来的配置数据和钥匙串会继续使用。
- **从早期原型迁移**（`Antigravity Pro 2.app`、`~/.antigravity-pro2-home`）：原型用的是固定、公开的钥匙串密码。先删除 `/Applications/Antigravity Pro 2.app` 和它的 Dock 图标，然后二选一：删除 `~/.antigravity-pro2-home`，在新配置里重新登录；或者把它改名为 `~/.ag-profile-b` 再运行 `./install.sh`，安装脚本会把旧密码换成随机密码。

## 卸载

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

只会停止用这个配置的 `--user-data-dir` 启动的进程。主程序 Antigravity、它的数据和你的登录钥匙串都不会被动到；唯一的例外是加 `--purge` 时会删除 `antigravity-2-users` 这个条目。

## 常见问题

**这是沙盒吗？** 不是。两个配置以同一个 macOS 用户身份运行，文件权限也一样。它隔离的是**账号和应用状态**，不是安全边界。

**重启后会串号吗？** 不应该会。每个配置读取各自的 HOME、数据目录和钥匙串。可以用 `verify.sh` 在你自己的电脑上确认。

**为什么配置 B 能看到我的桌面和文稿？** 因为它们被软链接进了配置的 HOME，方便你打开项目。配置 HOME 之外的东西本来也能用绝对路径访问。

**配置 B 的终端里 git 或 SSH 用不了。** 因为它的 HOME 里没有 `.gitconfig` 和 `.ssh`。加 `--link-dev` 重新安装，或者为这个账号单独配置。

**找不到 `brew`、`node`、`pyenv` 等命令。** 因为配置 HOME 里没有 `.zshrc`。请使用 `--link-dev`；另外启动器也会把 `/opt/homebrew/bin` 和 `/usr/local/bin` 加进 PATH。

**能开两个以上吗？** 可以，每个配置用一个不同的 `--name`。

**会修改 Antigravity.app 吗？** 不会。只会读取它的程序文件，并复制图标。

## 故障排除

### 提示 "AG Profile B" 已损坏或无法打开
重新签名，并清除隔离标记：
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
或者右键点击应用 → 打开。

### 点击启动器后什么都没有打开
在终端运行 `./scripts/launch.sh --name b` 查看报错，并检查 `--app-source` 是否指向一个真实存在的 `Antigravity.app`。

### Dock 图标不见了或出现两个
手动把应用从 `/Applications` 拖到 Dock，或者加 `--no-dock` 重新运行。要恢复原来的 Dock：`defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`。

### 浏览器登录后跳回了错误的窗口
两个配置其实是同一个应用，macOS 会把 `antigravity://` 登录回调交给它自己选的那一个，通常是主程序。解决办法：
1. 先退出主程序 Antigravity，在配置 B 里完成登录，再重新打开主程序。这只需要做一次，登录状态会保留。
2. 如果登录页面提供可以复制回应用的代码或 URL，在配置 B 里粘贴使用。

### macOS 反复要求输入钥匙串密码
对 `security` / `antigravity-2-users` 选择**始终允许**。如果配置钥匙串还是会锁定，运行 `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db`，或者重新运行 `./install.sh`。

### 配置 B 突然退出登录，或者模型显示不可用
从启动器重新打开一次，它会再次解锁钥匙串。然后运行 `verify.sh`。如果配置钥匙串显示有超时设置，重新运行 `./install.sh`。

## 已知限制

- **尚未在真机上测试。** 脚本通过了 shellcheck，开发期间也在 Linux 上用模拟的 macOS 工具完整跑过一遍，但还没有任何版本在装有最新 Antigravity 的真实 Mac 上验证过。请当作实验性工具使用，并反馈你遇到的情况。
- 只改 `HOME` 时，macOS 是否真的会把配置 B 的密钥存进配置钥匙串，**并没有保证**，不同 macOS 版本也可能不一样。`verify.sh` 就是为此准备的。
- `antigravity://` 登录回调可能会跳到错误的窗口（见上文）。
- 钥匙串密码是通过命令行参数传给 `security` 的，在极短的时间内，你这个用户下的其他进程能看到它。
- 只支持 macOS，不支持 Windows 和 Linux。
- Antigravity 的内部实现（文件位置、登录流程）随时可能在更新中改变，导致这个方案失效。

## 安全说明

- 每个配置钥匙串都用 48 位十六进制的随机密码，保存在你自己的登录钥匙串里。没有任何写死的密码，也没有任何数据离开你的 Mac。
- 只要你处于登录状态，配置钥匙串就不会自动锁定。这正是令牌能持续刷新的原因，但也意味着钥匙串解锁后，任何以你的用户身份运行的进程都能读取它。这和登录钥匙串本身的信任模型相同。
- 配置目录的权限是 `700`。
- 脚本不使用 `sudo`，不下载任何东西，除了 Dock 之外不改任何系统设置（Dock 修改前会备份，也可以跳过），也不动 `Antigravity.app`。
- 运行前请先读一遍所有脚本，它们都很短。

如果发现安全问题，请在 GitHub 上提交私密的安全公告（security advisory），不要提公开 issue。

## 参与贡献

欢迎提交 issue 和 PR，尤其欢迎**真机测试报告**：请附上 macOS 版本、芯片、Antigravity 版本，以及去掉邮箱后的 `verify.sh` 输出。

- 只用 macOS 自带的 Bash 3.2 语法，并确保能通过 `shellcheck -S style install.sh uninstall.sh scripts/*.sh`。
- 各语言的 README 要和 `README.md` 保持同步。
- 仓库里不要放任何 Google 的素材。

## 许可证

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
