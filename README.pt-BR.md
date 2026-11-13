<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — rode dois perfis do Antigravity lado a lado no macOS" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>Rode dois perfis do Antigravity lado a lado no macOS: a conta do trabalho e a conta pessoal, ambas conectadas ao mesmo tempo.</b><br>
  Cada perfil tem o próprio HOME, o próprio <code>--user-data-dir</code> e o próprio keychain, além de um atalho no Dock. Bash puro, sem dependências, licença MIT.
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <b>Português (Brasil)</b> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **Projeto comunitário não oficial.** Não é afiliado ao Google, nem aprovado ou suportado por ele. "Antigravity" é uma marca registrada da Google LLC e aparece aqui só para dizer com qual app esta ferramenta funciona. Este repositório não contém código, ícones ou outros recursos do Google. Use apenas com contas que são suas e siga os termos de serviço de cada conta em que você entrar. Não use para contornar limites de uso ou outras restrições.

## Sumário

- [Por quê](#por-quê)
- [Como funciona](#como-funciona)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
- [Opções](#opções)
- [Verificar o isolamento](#verificar-o-isolamento)
- [Atualização](#atualização)
- [Desinstalação](#desinstalação)
- [Perguntas frequentes](#perguntas-frequentes)
- [Solução de problemas](#solução-de-problemas)
- [Limitações conhecidas](#limitações-conhecidas)
- [Notas de segurança](#notas-de-segurança)
- [Como contribuir](#como-contribuir)
- [Licença](#licença)

## Por quê

O app de desktop do Antigravity só aceita uma conta Google conectada por vez. As credenciais ficam no keychain do macOS do seu usuário e em `~/.gemini/`. Se você abrir uma segunda cópia mudando só o `--user-data-dir`, ela normalmente já abre conectada na **mesma** conta, porque o backend lê `$HOME`, e não o diretório de dados do Electron.

Motivos comuns para manter dois perfis:

- **Trabalho e vida pessoal separados.** Código, conta e extensões da empresa ficam em uma janela; projetos pessoais, na outra.
- **Separação de clientes.** Quem é freelancer pode manter o workspace, as configurações e o histórico de cada cliente separados.
- **Testes do zero.** Teste extensões, configurações ou versões de prévia em um perfil descartável sem mexer no seu ambiente do dia a dia.
- **Aulas e demonstrações.** Apresente com uma conta de demonstração limpa enquanto sua conta real continua rodando.

## Como funciona

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

1. **HOME separado.** O atalho define `HOME=~/.ag-profile-<id>`. Tudo o que o app guarda em `~` (`.gemini`, `.antigravity` com as extensões, caches) passa a ser guardado lá.
2. **Perfil do Electron separado.** O `--user-data-dir` aponta para dentro desse HOME, então janelas, configurações, armazenamento e a trava de instância única também ficam separados.
3. **Keychain separado.** O instalador cria `~/.ag-profile-<id>/Library/Keychains/login.keychain-db` com uma senha **aleatória**. Essa senha fica guardada no seu keychain de login normal, no item `antigravity-2-users`. O keychain do perfil é configurado para não travar sozinho, então a renovação de tokens em segundo plano continua funcionando depois que o Mac sai do repouso.
4. **App de atalho.** O `osacompile` gera um pequeno app AppleScript, `AG Profile <ID>.app`. Ele roda `~/.ag-profile-<id>/.ag2u/launch.sh`, que destrava o keychain do perfil e depois faz `exec` do binário real do Antigravity. O ícone é copiado do Antigravity instalado no seu próprio Mac durante a instalação e nunca é redistribuído. O app recebe assinatura ad hoc e, se você quiser, é adicionado ao Dock.

Sua instalação principal do Antigravity não é alterada.

## Requisitos

- A expectativa é que funcione no macOS 13 ou mais recente (Apple silicon ou Intel; ainda não testado em hardware real), com as ferramentas que já vêm no sistema: `bash`, `python3`, `security`, `osacompile` e `codesign`
- O app de desktop do Antigravity instalado, por padrão em `/Applications/Antigravity.app`
- Uma conta de administrador para gravar em `/Applications`. Sem permissão de administrador, use `--app-dir ~/Applications`.
- Uma segunda conta Google para entrar

## Instalação

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

O que o instalador faz, passo a passo:

1. Verifica se você está no macOS e se o Antigravity está instalado.
2. Cria `~/.ag-profile-b` (permissão 700) e cria links para Mesa, Documentos e Downloads. Com `--link-dev`, também cria links para seus arquivos de configuração do git, do ssh e do shell. Arquivos reais nunca são sobrescritos, e rodar de novo é seguro.
3. Gera uma senha aleatória para o keychain, guarda no seu keychain de login, cria e destrava o keychain do perfil e desativa o travamento automático dele.
4. Grava `~/.ag-profile-b/.ag2u/launch.sh` e `config`, cria `/Applications/AG Profile B.app`, copia o ícone e assina o app com assinatura ad hoc.
5. Faz backup das configurações do Dock em `~/.ag-profile-b/.ag2u/dock-backup-*.plist` e adiciona o atalho ao lado do Antigravity. Use `--no-dock` para pular esta etapa.

O macOS pode perguntar uma vez se o `security` pode usar o item `antigravity-2-users`. Escolha **Sempre Permitir**.

## Uso

1. Abra o **AG Profile B** pelo Dock, pelo Launchpad ou por `/Applications`.
2. Na primeira vez, abre um Antigravity limpo, sem conta conectada. Entre com sua segunda conta. Se o navegador entregar o login para a janela errada, veja [o retorno do login](#o-login-no-navegador-volta-para-a-janela-errada).
3. Daí em diante, as duas janelas podem ficar abertas ao mesmo tempo. Cada uma mantém o próprio login, configurações, extensões e histórico.
4. Para abrir o mesmo projeto nas duas, use Arquivo → Abrir Pasta em cada janela. Mesa, Documentos e Downloads aparecem nas duas, e qualquer outro caminho absoluto também funciona.

Você também pode abrir pelo terminal, o que ajuda na depuração. Argumentos extras são repassados ao Antigravity:

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

Para mais perfis, `./install.sh --name c` cria `~/.ag-profile-c` e `AG Profile C.app`.

## Opções

`install.sh`

| Opção | Padrão | Significado |
|---|---|---|
| `--name <id>` | `b` | Identificador do perfil (`a-z`, `0-9`, `-`). Os dados ficam em `~/.ag-profile-<id>`; o atalho é `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | O app do Antigravity que será executado |
| `--app-dir <dir>` | `/Applications` | Onde o atalho é criado, por exemplo `~/Applications` |
| `--no-dock` | desligado | Não mexer no Dock |
| `--link-dev` | desligado | Também criar links para `~/.gitconfig`, `~/.ssh`, `~/.zshrc`, `~/.zprofile`, `~/.npmrc` e `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | Ajuda / versão |

`uninstall.sh`

| Opção | Significado |
|---|---|
| `--name <id>` | Perfil a remover (padrão `b`) |
| `--app-dir <dir>` | Onde o atalho foi criado (padrão `/Applications`) |
| `--purge` | Apagar também, sem perguntar, os dados do perfil, o keychain dele e a senha guardada (desconecta esse perfil) |
| `--keep-data` | Remover só o atalho e o ícone do Dock |

`scripts/launch.sh [--name <id>] [argumentos do Antigravity…]` e `scripts/verify.sh [--name <id>]` usam `b` por padrão.

## Verificar o isolamento

```bash
./scripts/verify.sh --name b
```

É uma verificação somente leitura, que mostra apenas os **nomes** dos itens, nunca segredos:

- processos em execução que usam o `--user-data-dir` deste perfil
- as configurações do keychain do perfil (deve mostrar `no-timeout`) e os itens dele (`svce` / `acct`)
- itens de Antigravity, Gemini ou Jetski no seu keychain de **login**
- nomes de arquivos em `~/.gemini` e em `~/.ag-profile-b/.gemini`

**O que você quer ver:** depois de entrar no perfil B, os itens dele aparecem no keychain **do perfil** e os arquivos de token em `~/.ag-profile-b/.gemini`. Os itens da sua conta principal continuam no keychain de login.
Se os itens do perfil B aparecerem no seu keychain de login, o macOS não está usando o keychain do perfil no seu sistema. [Abra uma issue](https://github.com/Xkongai/antigravity-2-users/issues) informando suas versões do macOS e do Antigravity. Você também pode conferir manualmente no **Acesso às Chaves** → Arquivo → Adicionar Chaveiro… → `~/.ag-profile-b/Library/Keychains/login.keychain-db`.

## Atualização

- **Atualizações do Antigravity:** não precisa fazer nada. O atalho executa o app que estiver em `--app-source`. Se o ícone ficar desatualizado, rode `./install.sh` de novo; ele pode ser rodado várias vezes e mantém seu login.
- **Esta ferramenta:** `git pull && ./install.sh --name b` com as mesmas opções de antes. Os dados e o keychain do perfil são reaproveitados.
- **Vindo do protótipo antigo** (`Antigravity Pro 2.app`, `~/.antigravity-pro2-home`): ele usava uma senha de keychain fixa e conhecida publicamente. Remova `/Applications/Antigravity Pro 2.app` e o ícone dele no Dock. Depois, ou apague `~/.antigravity-pro2-home` e entre de novo no perfil novo, ou mova a pasta para `~/.ag-profile-b` antes de rodar `./install.sh`; nesse caso, o instalador troca a senha antiga por uma aleatória.

## Desinstalação

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

Só são encerrados os processos iniciados com o `--user-data-dir` daquele perfil. Seu Antigravity principal, os dados dele e seu keychain de login nunca são tocados (exceto o item `antigravity-2-users`, com `--purge`).

## Perguntas frequentes

**Isto é um sandbox?** Não. Os dois perfis rodam com o mesmo usuário do macOS e as mesmas permissões de arquivo. O que fica separado são as **contas e o estado do app**; não é uma barreira de segurança.

**As contas vão se misturar depois de reiniciar?** Não deveriam. Cada perfil lê o próprio HOME, o próprio diretório de dados e o próprio keychain. Use o `verify.sh` para confirmar na sua máquina.

**Por que o perfil B enxerga minha Mesa e meus Documentos?** Porque eles têm links simbólicos dentro do HOME do perfil, para você conseguir abrir seus projetos. O que estiver fora do HOME do perfil continua acessível por caminhos absolutos.

**Git ou SSH não funcionam no terminal do perfil B.** O HOME dele não tem `.gitconfig` nem `.ssh`. Rode de novo com `--link-dev` ou configure separadamente para essa conta.

**Não encontra `brew`, `node` ou `pyenv`.** O HOME do perfil não tem `.zshrc`. Use `--link-dev`; o atalho também adiciona `/opt/homebrew/bin` e `/usr/local/bin` ao PATH.

**Dá para ter mais de dois?** Sim, um `--name` diferente para cada perfil.

**Ele modifica o Antigravity.app?** Não. Só lê o binário e copia o ícone.

## Solução de problemas

### "AG Profile B" está danificado ou não pode ser aberto
Assine o atalho de novo e remova o atributo de quarentena:
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
Ou clique com o botão direito no app → Abrir.

### O atalho não abre nada
Rode `./scripts/launch.sh --name b` no Terminal para ver os erros. Confira se `--app-source` aponta para um `Antigravity.app` que existe.

### O ícone do Dock sumiu ou aparece duas vezes
Arraste o app de `/Applications` para o Dock manualmente, ou rode de novo com `--no-dock`. Para restaurar o Dock: `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`.

### O login no navegador volta para a janela errada
Os dois perfis são o mesmo app, então o macOS envia o retorno de login `antigravity://` para a cópia que ele escolher, geralmente a principal. Alternativas:
1. Feche o Antigravity principal, entre no perfil B e depois abra o principal de novo. Isso só é necessário uma vez; o login fica salvo.
2. Se a página de login oferecer um código ou URL para colar no app, cole no perfil B.

### O macOS fica pedindo a senha do keychain
Escolha **Sempre Permitir** para `security` / `antigravity-2-users`. Se o keychain do perfil continuar travando, rode `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db` ou rode `./install.sh` de novo.

### O perfil B desconectou de repente ou não mostra modelos
Abra de novo pelo atalho; isso destrava o keychain outra vez. Depois rode `verify.sh`. Se o keychain do perfil mostrar um tempo limite, rode `./install.sh` de novo.

## Limitações conhecidas

- **Ainda não testado em hardware real.** Os scripts passam no shellcheck e, durante o desenvolvimento, foram executados de ponta a ponta no Linux com ferramentas do macOS simuladas. Nenhuma versão foi conferida ainda em um Mac de verdade com uma versão atual do Antigravity. Trate como experimental e conte o que você observar.
- **Não há garantia** de que o macOS realmente guarde os segredos do perfil B no keychain do perfil quando só o `HOME` muda, e isso pode variar entre versões do macOS. É exatamente para isso que o `verify.sh` existe.
- O retorno de login `antigravity://` pode cair na janela errada (veja acima).
- A senha do keychain é passada ao `security` na linha de comando, então por uma fração de segundo fica visível para outros processos do seu usuário.
- Só macOS. Windows e Linux não são suportados.
- Detalhes internos do Antigravity (locais de arquivos, fluxo de login) podem mudar em qualquer atualização e quebrar esta abordagem.

## Notas de segurança

- Cada keychain de perfil usa uma senha aleatória de 48 caracteres hexadecimais, guardada no seu próprio keychain de login. Nada fica fixo no código, e nada sai do seu Mac.
- O keychain do perfil não trava sozinho enquanto você está com a sessão aberta. É isso que mantém a renovação de tokens funcionando, mas também significa que, depois de destravado, qualquer processo rodando com o seu usuário pode lê-lo. É o mesmo modelo de confiança do seu keychain de login.
- O diretório do perfil é criado com permissão `700`.
- Os scripts nunca usam `sudo`, nunca baixam nada, não alteram configurações do sistema além do Dock (com backup antes, e é possível pular) e nunca mexem no `Antigravity.app`.
- Leia todos os scripts antes de rodar. Eles são curtos.

Encontrou um problema de segurança? Abra um aviso de segurança privado (security advisory) no GitHub em vez de uma issue pública.

## Como contribuir

Issues e PRs são bem-vindos, principalmente **relatos de testes em um Mac real** (versão do macOS, chip, versão do Antigravity e a saída do `verify.sh` com os e-mails ocultos).

- Mantenha o código em Bash 3.2 (a versão que vem no macOS) e garanta que ele passe em `shellcheck -S style install.sh uninstall.sh scripts/*.sh`.
- Mantenha as traduções do README em dia com o `README.md`.
- Nenhum recurso do Google no repositório.

## Licença

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
