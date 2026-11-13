<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — deux profils Antigravity côte à côte sur macOS" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>Lancez deux profils Antigravity côte à côte sur macOS : votre compte pro et votre compte perso, connectés en même temps.</b><br>
  Chaque profil a son propre HOME, son propre <code>--user-data-dir</code> et son propre trousseau, ainsi qu'un lanceur dans le Dock. Du Bash pur, sans dépendances, sous licence MIT.
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <a href="README.es.md">Español</a> | <a href="README.pt-BR.md">Português (Brasil)</a> | <b>Français</b> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **Projet communautaire non officiel.** Il n'est ni affilié à Google, ni approuvé ou pris en charge par Google. « Antigravity » est une marque de Google LLC ; elle n'est citée ici que pour indiquer avec quelle application cet outil fonctionne. Ce dépôt ne contient aucun code, aucune icône ni aucune autre ressource de Google. Utilisez-le uniquement avec des comptes qui vous appartiennent et respectez les conditions d'utilisation de chaque compte que vous connectez. Ne l'utilisez pas pour contourner des limites d'utilisation ou d'autres restrictions.

## Sommaire

- [Pourquoi](#pourquoi)
- [Fonctionnement](#fonctionnement)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Options](#options)
- [Vérifier l'isolation](#vérifier-lisolation)
- [Mise à jour](#mise-à-jour)
- [Désinstallation](#désinstallation)
- [FAQ](#faq)
- [Dépannage](#dépannage)
- [Limites connues](#limites-connues)
- [Notes de sécurité](#notes-de-sécurité)
- [Contribuer](#contribuer)
- [Licence](#licence)

## Pourquoi

L'application de bureau Antigravity ne connecte qu'un seul compte Google à la fois. Les identifiants sont stockés dans le trousseau macOS de votre utilisateur et dans `~/.gemini/`. Si vous lancez une seconde copie en changeant seulement `--user-data-dir`, elle s'ouvre généralement connectée au **même** compte : le backend lit `$HOME`, pas le dossier de données d'Electron.

Raisons courantes d'avoir deux profils :

- **Séparer le pro et le perso.** Le code, le compte et les extensions de l'entreprise dans une fenêtre, les projets personnels dans l'autre.
- **Séparer les clients.** En freelance, vous pouvez garder l'espace de travail, les réglages et l'historique de chaque client à part.
- **Tester sur une base propre.** Essayez des extensions, des réglages ou des préversions dans un profil jetable sans toucher à votre environnement quotidien.
- **Cours et démos.** Présentez avec un compte de démo propre pendant que votre vrai compte continue de tourner.

## Fonctionnement

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

1. **Un HOME à part.** Le lanceur définit `HOME=~/.ag-profile-<id>`. Tout ce que l'application range sous `~` (`.gemini`, `.antigravity` avec les extensions, les caches) est désormais rangé là.
2. **Un profil Electron à part.** `--user-data-dir` pointe à l'intérieur de ce HOME : fenêtres, réglages, stockage et verrou d'instance unique sont donc séparés eux aussi.
3. **Un trousseau à part.** L'installateur crée `~/.ag-profile-<id>/Library/Keychains/login.keychain-db` avec un mot de passe **aléatoire**. Ce mot de passe est stocké dans votre trousseau de session habituel, sous l'élément `antigravity-2-users`. Le trousseau du profil est réglé pour ne pas se verrouiller automatiquement, si bien que le renouvellement des jetons en arrière-plan continue de fonctionner après la veille.
4. **Une application de lancement.** `osacompile` génère une petite application AppleScript, `AG Profile <ID>.app`. Elle exécute `~/.ag-profile-<id>/.ag2u/launch.sh`, qui déverrouille le trousseau du profil puis fait un `exec` du vrai binaire Antigravity. L'icône est copiée depuis votre Antigravity installé, sur votre propre Mac, au moment de l'installation ; elle n'est jamais redistribuée. L'application reçoit une signature ad hoc et peut être ajoutée au Dock si vous le souhaitez.

Votre installation principale d'Antigravity n'est jamais modifiée.

## Prérequis

- macOS 13 ou plus récent devrait fonctionner (Apple silicon ou Intel ; pas encore testé sur du vrai matériel), avec les outils fournis par le système : `bash`, `python3`, `security`, `osacompile` et `codesign`
- L'application de bureau Antigravity installée, par défaut dans `/Applications/Antigravity.app`
- Un compte administrateur pour écrire dans `/Applications`. Sans droits d'administrateur, utilisez `--app-dir ~/Applications`.
- Un second compte Google avec lequel vous connecter

## Installation

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

Ce que fait l'installateur, étape par étape :

1. Il vérifie que vous êtes sous macOS et qu'Antigravity est installé.
2. Il crée `~/.ag-profile-b` (droits 700) et y lie Bureau, Documents et Téléchargements. Avec `--link-dev`, il lie aussi vos fichiers de configuration git, ssh et shell. Les vrais fichiers ne sont jamais écrasés, et le relancer est sans risque.
3. Il génère un mot de passe aléatoire pour le trousseau, le stocke dans votre trousseau de session, crée et déverrouille le trousseau du profil, puis désactive son verrouillage automatique.
4. Il écrit `~/.ag-profile-b/.ag2u/launch.sh` et `config`, crée `/Applications/AG Profile B.app`, copie l'icône et signe l'application de façon ad hoc.
5. Il sauvegarde les réglages du Dock dans `~/.ag-profile-b/.ag2u/dock-backup-*.plist` et ajoute le lanceur à côté d'Antigravity. Passez `--no-dock` pour sauter cette étape.

macOS peut demander une fois si `security` est autorisé à utiliser l'élément `antigravity-2-users`. Choisissez **Toujours autoriser**.

## Utilisation

1. Ouvrez **AG Profile B** depuis le Dock, le Launchpad ou `/Applications`.
2. Au premier lancement, vous obtenez un Antigravity vierge et déconnecté. Connectez-vous avec votre second compte. Si le navigateur renvoie la connexion vers la mauvaise fenêtre, voyez [le retour de connexion](#la-connexion-dans-le-navigateur-revient-vers-la-mauvaise-fenêtre).
3. Ensuite, les deux fenêtres peuvent être ouvertes en même temps. Chacune garde sa propre connexion, ses réglages, ses extensions et son historique.
4. Pour ouvrir le même projet dans les deux, utilisez Fichier → Ouvrir le dossier dans chaque fenêtre. Bureau, Documents et Téléchargements sont visibles des deux côtés, et tout autre chemin absolu fonctionne aussi.

Vous pouvez aussi le lancer depuis un terminal, ce qui est pratique pour déboguer. Les arguments supplémentaires sont transmis à Antigravity :

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

Pour d'autres profils, `./install.sh --name c` crée `~/.ag-profile-c` et `AG Profile C.app`.

## Options

`install.sh`

| Option | Par défaut | Signification |
|---|---|---|
| `--name <id>` | `b` | Identifiant du profil (`a-z`, `0-9`, `-`). Les données vont dans `~/.ag-profile-<id>` ; le lanceur s'appelle `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | L'application Antigravity à lancer |
| `--app-dir <dir>` | `/Applications` | Où créer le lanceur, par exemple `~/Applications` |
| `--no-dock` | désactivé | Ne pas toucher au Dock |
| `--link-dev` | désactivé | Lier aussi `~/.gitconfig`, `~/.ssh`, `~/.zshrc`, `~/.zprofile`, `~/.npmrc` et `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | Aide / version |

`uninstall.sh`

| Option | Signification |
|---|---|
| `--name <id>` | Profil à supprimer (par défaut `b`) |
| `--app-dir <dir>` | Où le lanceur a été créé (par défaut `/Applications`) |
| `--purge` | Supprimer aussi, sans confirmation, les données du profil, son trousseau et le mot de passe stocké (ce profil est déconnecté) |
| `--keep-data` | Supprimer uniquement le lanceur et l'icône du Dock |

`scripts/launch.sh [--name <id>] [arguments d'Antigravity…]` et `scripts/verify.sh [--name <id>]` utilisent `b` par défaut.

## Vérifier l'isolation

```bash
./scripts/verify.sh --name b
```

C'est une vérification en lecture seule, qui n'affiche que les **noms** des éléments, jamais de secrets :

- les processus en cours qui utilisent le `--user-data-dir` de ce profil
- les réglages du trousseau du profil (il devrait indiquer `no-timeout`) et ses éléments (`svce` / `acct`)
- les éléments Antigravity, Gemini ou Jetski de votre trousseau de **session**
- les noms de fichiers dans `~/.gemini` et dans `~/.ag-profile-b/.gemini`

**Ce que vous devriez voir :** une fois connecté au profil B, ses éléments apparaissent dans le trousseau **du profil** et ses fichiers de jeton dans `~/.ag-profile-b/.gemini`. Les éléments de votre compte principal restent dans le trousseau de session.
Si les éléments du profil B apparaissent plutôt dans votre trousseau de session, macOS n'a pas utilisé le trousseau du profil sur votre système. [Ouvrez une issue](https://github.com/Xkongai/antigravity-2-users/issues) en indiquant vos versions de macOS et d'Antigravity. Vous pouvez aussi vérifier à la main dans **Trousseaux d'accès** → Fichier → Ajouter un trousseau… → `~/.ag-profile-b/Library/Keychains/login.keychain-db`.

## Mise à jour

- **Mises à jour d'Antigravity :** rien à faire. Le lanceur exécute l'application qui se trouve dans `--app-source`. Si l'icône n'est plus à jour, relancez `./install.sh` ; il peut être relancé autant de fois que nécessaire et conserve votre connexion.
- **Cet outil :** `git pull && ./install.sh --name b` avec les mêmes options qu'avant. Les données et le trousseau du profil sont réutilisés.
- **Si vous venez de l'ancien prototype** (`Antigravity Pro 2.app`, `~/.antigravity-pro2-home`) : il utilisait un mot de passe de trousseau fixe et connu publiquement. Supprimez `/Applications/Antigravity Pro 2.app` et son icône du Dock. Ensuite, soit vous supprimez `~/.antigravity-pro2-home` et vous vous reconnectez dans le nouveau profil, soit vous le déplacez vers `~/.ag-profile-b` avant de lancer `./install.sh` ; dans ce cas, l'installateur remplace l'ancien mot de passe par un mot de passe aléatoire.

## Désinstallation

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

Seuls les processus lancés avec le `--user-data-dir` de ce profil sont arrêtés. Votre Antigravity principal, ses données et votre trousseau de session ne sont jamais touchés (sauf l'élément `antigravity-2-users`, avec `--purge`).

## FAQ

**Est-ce un bac à sable ?** Non. Les deux profils tournent sous le même utilisateur macOS, avec les mêmes droits sur les fichiers. Ce qui est séparé, ce sont les **comptes et l'état de l'application** ; ce n'est pas une barrière de sécurité.

**Les comptes vont-ils se mélanger après un redémarrage ?** Normalement non. Chaque profil lit son propre HOME, son dossier de données et son trousseau. Utilisez `verify.sh` pour le confirmer sur votre machine.

**Pourquoi le profil B voit-il mon Bureau et mes Documents ?** Parce qu'ils sont liés symboliquement dans le HOME du profil, pour que vous puissiez ouvrir vos projets. Tout ce qui se trouve en dehors du HOME du profil reste de toute façon accessible par chemin absolu.

**Git ou SSH ne fonctionnent pas dans le terminal du profil B.** Son HOME ne contient ni `.gitconfig` ni `.ssh`. Relancez avec `--link-dev`, ou configurez-les séparément pour ce compte.

**`brew`, `node` ou `pyenv` sont introuvables.** Le HOME du profil n'a pas de `.zshrc`. Utilisez `--link-dev` ; le lanceur ajoute aussi `/opt/homebrew/bin` et `/usr/local/bin` au PATH.

**Peut-on en lancer plus de deux ?** Oui, un `--name` différent par profil.

**Est-ce que cela modifie Antigravity.app ?** Non. L'outil se contente de lire le binaire et de copier l'icône.

## Dépannage

### « AG Profile B » est endommagé ou ne peut pas être ouvert
Signez à nouveau le lanceur et retirez l'attribut de quarantaine :
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
Ou faites un clic droit sur l'application → Ouvrir.

### Le lanceur n'ouvre rien
Lancez `./scripts/launch.sh --name b` dans le Terminal pour voir les erreurs. Vérifiez que `--app-source` pointe vers un `Antigravity.app` qui existe.

### L'icône du Dock manque ou apparaît en double
Faites glisser l'application de `/Applications` vers le Dock à la main, ou relancez avec `--no-dock`. Pour restaurer le Dock : `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`.

### La connexion dans le navigateur revient vers la mauvaise fenêtre
Les deux profils sont la même application : macOS envoie donc le retour de connexion `antigravity://` à la copie de son choix, en général la principale. Solutions de contournement :
1. Quittez l'Antigravity principal, connectez-vous dans le profil B, puis rouvrez le principal. Il suffit de le faire une fois ; la connexion est conservée.
2. Si la page de connexion propose un code ou une URL à coller dans l'application, collez-le dans le profil B.

### macOS redemande sans cesse le mot de passe du trousseau
Choisissez **Toujours autoriser** pour `security` / `antigravity-2-users`. Si le trousseau du profil se verrouille encore, lancez `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db` ou relancez `./install.sh`.

### Le profil B est soudain déconnecté ou n'affiche plus de modèles
Rouvrez-le depuis le lanceur ; cela déverrouille de nouveau le trousseau. Puis lancez `verify.sh`. Si le trousseau du profil affiche un délai de verrouillage, relancez `./install.sh`.

## Limites connues

- **Pas encore testé sur du vrai matériel.** Les scripts passent shellcheck et, pendant le développement, ils ont été exécutés de bout en bout sous Linux avec des outils macOS simulés. Aucune version n'a encore été vérifiée sur un vrai Mac avec une version récente d'Antigravity. Considérez l'outil comme expérimental et signalez ce que vous observez.
- **Rien ne garantit** que macOS range vraiment les secrets du profil B dans le trousseau du profil quand seul `HOME` change, et cela peut varier selon la version de macOS. C'est précisément pour cela que `verify.sh` existe.
- Le retour de connexion `antigravity://` peut arriver dans la mauvaise fenêtre (voir plus haut).
- Le mot de passe du trousseau est passé à `security` en ligne de commande : pendant une fraction de seconde, il est visible par les autres processus de votre utilisateur.
- macOS uniquement. Windows et Linux ne sont pas pris en charge.
- Le fonctionnement interne d'Antigravity (emplacement des fichiers, processus de connexion) peut changer à chaque mise à jour et rendre cette méthode inopérante.

## Notes de sécurité

- Chaque trousseau de profil utilise un mot de passe aléatoire de 48 caractères hexadécimaux, conservé dans votre propre trousseau de session. Rien n'est codé en dur, et rien ne quitte jamais votre Mac.
- Le trousseau du profil ne se verrouille pas automatiquement tant que votre session est ouverte. C'est ce qui permet au renouvellement des jetons de continuer, mais cela signifie aussi qu'une fois déverrouillé, n'importe quel processus lancé sous votre utilisateur peut le lire. C'est le même modèle de confiance que votre trousseau de session.
- Le dossier du profil est créé avec les droits `700`.
- Les scripts n'utilisent jamais `sudo`, ne téléchargent jamais rien, ne modifient aucun réglage système à part le Dock (sauvegardé avant, et facultatif) et ne touchent jamais à `Antigravity.app`.
- Lisez chaque script avant de le lancer. Ils sont courts.

Vous avez trouvé un problème de sécurité ? Ouvrez un avis de sécurité privé (security advisory) sur GitHub plutôt qu'une issue publique.

## Contribuer

Les issues et les PR sont les bienvenues, en particulier les **retours de tests sur un vrai Mac** (version de macOS, puce, version d'Antigravity, sortie de `verify.sh` avec les adresses e-mail masquées).

- Restez en Bash 3.2 (la version fournie avec macOS) et vérifiez que le code passe `shellcheck -S style install.sh uninstall.sh scripts/*.sh`.
- Gardez les traductions du README alignées sur `README.md`.
- Aucune ressource de Google dans le dépôt.

## Licence

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
