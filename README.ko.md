<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — macOS에서 Antigravity 프로필 두 개를 나란히 실행" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>macOS에서 Antigravity 프로필 두 개를 나란히 실행하세요. 업무용 계정과 개인 계정에 동시에 로그인할 수 있습니다.</b><br>
  프로필마다 HOME, <code>--user-data-dir</code>, 키체인이 따로 있고, Dock에 실행기가 하나 추가됩니다. 순수 Bash로 작성했고 의존성은 없으며, MIT 라이선스입니다.
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <b>한국어</b> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **비공식 커뮤니티 프로젝트입니다.** Google과는 아무 관련이 없으며, Google의 승인이나 지원도 받지 않았습니다. "Antigravity"는 Google LLC의 상표이며, 여기서는 이 도구가 어떤 앱과 함께 쓰이는지 밝히기 위해서만 사용합니다. 이 저장소에는 Google의 코드, 아이콘, 기타 자산이 전혀 들어 있지 않습니다. 본인 소유의 계정으로만 사용하고, 로그인하는 모든 계정의 서비스 약관을 지켜 주세요. 사용량 한도나 그 밖의 제한을 우회하는 용도로 쓰지 마세요.

## 목차

- [왜 필요한가](#왜-필요한가)
- [작동 방식](#작동-방식)
- [요구 사항](#요구-사항)
- [설치](#설치)
- [사용법](#사용법)
- [옵션](#옵션)
- [격리 확인](#격리-확인)
- [업데이트](#업데이트)
- [제거](#제거)
- [자주 묻는 질문](#자주-묻는-질문)
- [문제 해결](#문제-해결)
- [알려진 제한 사항](#알려진-제한-사항)
- [보안 참고 사항](#보안-참고-사항)
- [기여하기](#기여하기)
- [라이선스](#라이선스)

## 왜 필요한가

Antigravity 데스크톱 앱은 한 번에 Google 계정 하나에만 로그인할 수 있습니다. 자격 증명은 사용자 전체에서 쓰는 macOS 키체인과 `~/.gemini/`에 저장됩니다. `--user-data-dir`만 바꿔서 하나 더 실행하면 대개 **같은** 계정으로 로그인된 상태로 열립니다. 백엔드가 Electron 데이터 디렉터리가 아니라 `$HOME`을 읽기 때문입니다.

프로필을 두 개 쓰는 흔한 이유는 다음과 같습니다.

- **업무와 개인 분리**: 회사 코드, 회사 계정, 회사에서 요구하는 확장 프로그램은 한 창에, 개인 프로젝트는 다른 창에 둡니다.
- **고객별 분리**: 프리랜서라면 고객마다 작업 공간, 설정, 기록을 따로 둘 수 있습니다.
- **깨끗한 테스트 환경**: 새 확장 프로그램이나 설정, 미리보기 빌드를 언제든 지울 수 있는 프로필에서 시험하고, 평소 환경은 건드리지 않습니다.
- **강의와 데모**: 깨끗한 데모 계정으로 화면을 공유하는 동안 실제 계정은 그대로 돌아갑니다.

## 작동 방식

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

1. **별도의 HOME**: 실행기가 `HOME=~/.ag-profile-<id>`로 설정합니다. 앱이 `~` 아래에 두던 것들(`.gemini`, 확장 프로그램이 들어 있는 `.antigravity`, 캐시)이 모두 그쪽에 저장됩니다.
2. **별도의 Electron 프로필**: `--user-data-dir`가 그 HOME 안을 가리키므로 창, 설정, 저장소, 단일 인스턴스 잠금도 서로 분리됩니다.
3. **별도의 키체인**: 설치 스크립트가 `~/.ag-profile-<id>/Library/Keychains/login.keychain-db`를 **무작위** 비밀번호로 만듭니다. 그 비밀번호는 평소 쓰는 로그인 키체인에 `antigravity-2-users`라는 항목으로 저장됩니다. 프로필 키체인은 자동으로 잠기지 않도록 설정되므로, 잠자기에서 깨어난 뒤에도 백그라운드 토큰 갱신이 계속됩니다.
4. **실행기 앱**: `osacompile`로 작은 AppleScript 앱 `AG Profile <ID>.app`을 만듭니다. 이 앱은 `~/.ag-profile-<id>/.ag2u/launch.sh`를 실행해 프로필 키체인의 잠금을 푼 다음 실제 Antigravity를 `exec`합니다. 아이콘은 설치할 때 내 Mac에 설치된 Antigravity에서 복사해 올 뿐이며 재배포하지 않습니다. 앱에는 ad-hoc 서명을 하고, 원하면 Dock에도 추가할 수 있습니다.

기본 Antigravity는 전혀 건드리지 않습니다.

## 요구 사항

- macOS 13 이상에서 동작할 것으로 예상합니다(Apple 실리콘 또는 Intel, 아직 실제 기기에서는 테스트하지 않음). 기본 제공되는 `bash`, `python3`, `security`, `osacompile`, `codesign`을 사용합니다.
- Antigravity 데스크톱 앱 설치(기본 위치는 `/Applications/Antigravity.app`)
- `/Applications`에 쓰려면 관리자 계정이 필요합니다. 관리자가 아니라면 `--app-dir ~/Applications`를 사용하세요.
- 로그인에 쓸 두 번째 Google 계정

## 설치

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

설치 스크립트는 다음 순서로 진행합니다.

1. macOS인지, Antigravity가 설치되어 있는지 확인합니다.
2. `~/.ag-profile-b`(권한 700)를 만들고 데스크탑, 문서, 다운로드를 링크합니다. `--link-dev`를 주면 git, ssh, 셸 설정 파일도 링크합니다. 기존의 실제 파일은 덮어쓰지 않으며, 여러 번 실행해도 안전합니다.
3. 무작위 키체인 비밀번호를 만들어 로그인 키체인에 저장하고, 프로필 키체인을 만들어 잠금을 푼 뒤 자동 잠금을 끕니다.
4. `~/.ag-profile-b/.ag2u/launch.sh`와 `config`를 쓰고, `/Applications/AG Profile B.app`을 만든 다음 아이콘을 복사하고 ad-hoc 서명을 합니다.
5. Dock 설정을 `~/.ag-profile-b/.ag2u/dock-backup-*.plist`에 백업한 뒤 실행기를 Antigravity 옆에 추가합니다. Dock을 건드리고 싶지 않다면 `--no-dock`을 주세요.

`security`가 `antigravity-2-users` 항목을 사용해도 되는지 macOS가 한 번 물어볼 수 있습니다. **항상 허용**을 선택하세요.

## 사용법

1. Dock, Launchpad 또는 `/Applications`에서 **AG Profile B**를 엽니다.
2. 처음 열면 로그인하지 않은 깨끗한 Antigravity가 나타납니다. 두 번째 계정으로 로그인하세요. 브라우저가 로그인 결과를 엉뚱한 창으로 넘긴다면 [로그인 콜백](#브라우저-로그인-후-엉뚱한-창으로-돌아갈-때)을 참고하세요.
3. 이후에는 두 창을 동시에 열 수 있습니다. 로그인 상태, 설정, 확장 프로그램, 기록은 각자 따로 유지됩니다.
4. 같은 프로젝트를 양쪽에서 열려면 각 창에서 파일 → 폴더 열기를 사용하세요. 데스크탑, 문서, 다운로드는 양쪽에서 모두 보이고, 다른 절대 경로도 사용할 수 있습니다.

터미널에서 실행할 수도 있어 디버깅할 때 편합니다. 추가 인수는 Antigravity에 그대로 전달됩니다.

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

프로필을 더 만들려면 `./install.sh --name c`를 실행하세요. `~/.ag-profile-c`와 `AG Profile C.app`이 만들어집니다.

## 옵션

`install.sh`

| 옵션 | 기본값 | 설명 |
|---|---|---|
| `--name <id>` | `b` | 프로필 ID(`a-z`, `0-9`, `-`). 데이터는 `~/.ag-profile-<id>`에, 실행기 이름은 `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | 실행할 Antigravity 앱 |
| `--app-dir <dir>` | `/Applications` | 실행기를 만들 위치(예: `~/Applications`) |
| `--no-dock` | 꺼짐 | Dock을 건드리지 않음 |
| `--link-dev` | 꺼짐 | `~/.gitconfig`, `~/.ssh`, `~/.zshrc`, `~/.zprofile`, `~/.npmrc`, `~/.config/git`도 링크 |
| `-h`, `--help` / `-V`, `--version` | | 도움말 / 버전 |

`uninstall.sh`

| 옵션 | 설명 |
|---|---|
| `--name <id>` | 제거할 프로필(기본값 `b`) |
| `--app-dir <dir>` | 실행기를 만든 위치(기본값 `/Applications`) |
| `--purge` | 묻지 않고 프로필 데이터, 해당 키체인, 저장된 비밀번호까지 삭제(그 프로필은 로그아웃됨) |
| `--keep-data` | 실행기와 Dock 항목만 제거 |

`scripts/launch.sh [--name <id>] [antigravity 인수…]`와 `scripts/verify.sh [--name <id>]`의 기본 프로필은 `b`입니다.

## 격리 확인

```bash
./scripts/verify.sh --name b
```

읽기 전용 검사이며, 항목의 **이름**만 출력하고 비밀 값은 절대 출력하지 않습니다.

- 이 프로필의 `--user-data-dir`로 실행 중인 프로세스
- 프로필 키체인의 설정(`no-timeout`으로 표시되어야 함)과 그 안의 항목(`svce` / `acct`)
- **로그인** 키체인에 있는 Antigravity, Gemini, Jetski 관련 항목
- `~/.gemini`와 `~/.ag-profile-b/.gemini`의 파일 이름

**정상적인 결과**: 프로필 B에서 로그인한 뒤, 그 항목은 **프로필** 키체인에, 토큰 파일은 `~/.ag-profile-b/.gemini`에 있어야 합니다. 기본 계정의 항목은 로그인 키체인에 그대로 남습니다.
만약 프로필 B의 항목이 로그인 키체인에 나타난다면, 사용 중인 시스템에서는 프로필 키체인이 쓰이지 않은 것입니다. macOS와 Antigravity 버전을 적어 [issue를 열어](https://github.com/Xkongai/antigravity-2-users/issues) 주세요. 직접 확인하려면 **키체인 접근** → 파일 → 키체인 추가… → `~/.ag-profile-b/Library/Keychains/login.keychain-db`를 선택하세요.

## 업데이트

- **Antigravity 업데이트**: 따로 할 일은 없습니다. 실행기는 `--app-source`에 있는 앱을 그대로 실행합니다. 아이콘이 예전 그대로라면 `./install.sh`를 다시 실행하세요. 여러 번 실행해도 되고 로그인 상태도 유지됩니다.
- **이 도구 업데이트**: 이전과 같은 옵션으로 `git pull && ./install.sh --name b`를 실행합니다. 프로필 데이터와 키체인은 그대로 다시 사용됩니다.
- **초기 프로토타입에서 옮겨 오는 경우**(`Antigravity Pro 2.app`, `~/.antigravity-pro2-home`): 프로토타입은 고정된, 공개적으로 알려진 키체인 비밀번호를 썼습니다. 먼저 `/Applications/Antigravity Pro 2.app`과 그 Dock 아이콘을 지우세요. 그다음 `~/.antigravity-pro2-home`를 삭제하고 새 프로필에서 다시 로그인하거나, `./install.sh`를 실행하기 전에 `~/.ag-profile-b`로 옮기세요. 옮긴 경우 설치 스크립트가 예전 비밀번호를 무작위 비밀번호로 바꿉니다.

## 제거

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

해당 프로필의 `--user-data-dir`로 시작된 프로세스만 종료합니다. 기본 Antigravity와 그 데이터, 로그인 키체인은 건드리지 않습니다(`--purge`를 주면 `antigravity-2-users` 항목을 지우는 것만 예외입니다).

## 자주 묻는 질문

**샌드박스인가요?** 아닙니다. 두 프로필 모두 같은 macOS 사용자, 같은 파일 권한으로 실행됩니다. 분리하는 것은 **계정과 앱 상태**이며, 보안 경계가 아닙니다.

**재부팅하면 계정이 섞이지 않나요?** 그럴 일은 없을 것입니다. 각 프로필은 자기 HOME, 데이터 디렉터리, 키체인을 읽습니다. 내 컴퓨터에서 `verify.sh`로 확인해 보세요.

**프로필 B에서 왜 내 데스크탑과 문서가 보이나요?** 프로젝트를 열 수 있도록 프로필 HOME 안에 심볼릭 링크를 걸어 두었기 때문입니다. 프로필 HOME 밖에 있는 것도 원래 절대 경로로 접근할 수 있습니다.

**프로필 B의 터미널에서 git이나 SSH가 안 됩니다.** 그 HOME에는 `.gitconfig`와 `.ssh`가 없기 때문입니다. `--link-dev`로 다시 설치하거나, 그 계정용으로 따로 설정하세요.

**`brew`, `node`, `pyenv` 같은 명령을 찾을 수 없습니다.** 프로필 HOME에 `.zshrc`가 없기 때문입니다. `--link-dev`를 사용하세요. 실행기는 `/opt/homebrew/bin`과 `/usr/local/bin`도 PATH에 추가합니다.

**세 개 이상 실행할 수 있나요?** 네. 프로필마다 다른 `--name`을 쓰면 됩니다.

**Antigravity.app을 수정하나요?** 아니요. 실행 파일을 읽고 아이콘을 복사할 뿐입니다.

## 문제 해결

### "AG Profile B"가 손상되었거나 열 수 없다고 나올 때
실행기에 다시 서명하고 격리(quarantine) 속성을 지우세요.
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
또는 앱을 오른쪽 클릭 → 열기.

### 실행기를 눌러도 아무것도 열리지 않을 때
터미널에서 `./scripts/launch.sh --name b`를 실행해 오류를 확인하고, `--app-source`가 실제로 있는 `Antigravity.app`을 가리키는지 확인하세요.

### Dock 아이콘이 없거나 두 개일 때
`/Applications`에서 앱을 Dock으로 직접 끌어다 놓거나, `--no-dock`으로 다시 실행하세요. Dock을 원래대로 되돌리려면 `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`를 실행합니다.

### 브라우저 로그인 후 엉뚱한 창으로 돌아갈 때
두 프로필은 사실 같은 앱이라서 macOS는 `antigravity://` 로그인 콜백을 자기가 고른 쪽(보통 기본 앱)으로 보냅니다. 해결 방법:
1. 기본 Antigravity를 종료하고 프로필 B에서 로그인한 뒤, 기본 앱을 다시 엽니다. 로그인 상태가 유지되므로 한 번만 하면 됩니다.
2. 로그인 페이지에 앱에 붙여 넣을 코드나 URL이 나오면 프로필 B에 붙여 넣으세요.

### macOS가 키체인 비밀번호를 계속 물어볼 때
`security` / `antigravity-2-users`에 대해 **항상 허용**을 선택하세요. 그래도 프로필 키체인이 잠기면 `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db`를 실행하거나 `./install.sh`를 다시 실행하세요.

### 프로필 B가 갑자기 로그아웃되거나 모델을 쓸 수 없게 될 때
실행기로 다시 열면 키체인 잠금이 다시 풀립니다. 그다음 `verify.sh`를 실행하고, 프로필 키체인에 시간 제한이 설정되어 있으면 `./install.sh`를 다시 실행하세요.

## 알려진 제한 사항

- **아직 실제 기기에서 테스트하지 않았습니다.** 스크립트는 shellcheck를 통과했고, 개발 중에 Linux에서 macOS 도구를 모의(mock)로 대체해 처음부터 끝까지 실행해 봤습니다. 하지만 최신 Antigravity가 설치된 실제 Mac에서 확인한 릴리스는 아직 없습니다. 실험적인 도구로 여기고, 겪은 내용을 알려 주세요.
- `HOME`만 바꿨을 때 macOS가 프로필 B의 비밀 정보를 정말 프로필 키체인에 저장하는지는 **보장되지 않으며**, macOS 버전마다 다를 수 있습니다. `verify.sh`는 바로 그 때문에 있습니다.
- `antigravity://` 로그인 콜백이 엉뚱한 창으로 갈 수 있습니다(위 참고).
- 키체인 비밀번호는 명령줄 인수로 `security`에 전달되므로, 아주 잠깐 같은 사용자의 다른 프로세스에서 보일 수 있습니다.
- macOS 전용입니다. Windows와 Linux는 지원하지 않습니다.
- Antigravity의 내부 구조(파일 위치, 로그인 흐름)는 업데이트로 언제든 바뀔 수 있고, 그러면 이 방식이 동작하지 않을 수 있습니다.

## 보안 참고 사항

- 프로필 키체인마다 16진수 48자리의 무작위 비밀번호를 쓰고, 그 비밀번호는 내 로그인 키체인에 저장됩니다. 하드코딩된 값은 없으며, 어떤 데이터도 Mac 밖으로 나가지 않습니다.
- 로그인해 있는 동안 프로필 키체인은 자동으로 잠기지 않습니다. 그래서 토큰 갱신이 계속될 수 있지만, 잠금이 풀린 뒤에는 내 사용자로 실행되는 어떤 프로세스든 읽을 수 있다는 뜻이기도 합니다. 로그인 키체인과 같은 신뢰 모델입니다.
- 프로필 디렉터리는 권한 `700`으로 만들어집니다.
- 스크립트는 `sudo`를 쓰지 않고, 아무것도 내려받지 않으며, Dock 외의 시스템 설정은 바꾸지 않고(Dock도 먼저 백업하며 건너뛸 수 있음), `Antigravity.app`도 건드리지 않습니다.
- 실행하기 전에 모든 스크립트를 읽어 보세요. 모두 짧습니다.

보안 문제를 발견하면 공개 issue 대신 GitHub의 비공개 보안 권고(security advisory)로 알려 주세요.

## 기여하기

Issue와 PR을 환영합니다. 특히 **실제 Mac에서의 테스트 보고**(macOS 버전, 칩, Antigravity 버전, 이메일을 가린 `verify.sh` 출력)가 큰 도움이 됩니다.

- macOS 기본 Bash 3.2에서 돌아가는 문법을 지키고, `shellcheck -S style install.sh uninstall.sh scripts/*.sh`를 통과하게 해 주세요.
- 각 언어의 README는 `README.md`와 내용을 맞춰 주세요.
- 저장소에 Google 자산을 넣지 마세요.

## 라이선스

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
