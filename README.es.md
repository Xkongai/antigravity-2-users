<p align="center">
  <img src="docs/banner.png" alt="antigravity-2-users — ejecuta dos perfiles de Antigravity en paralelo en macOS" width="100%">
</p>

<h1 align="center">antigravity-2-users</h1>

<p align="center">
  <b>Ejecuta dos perfiles de Antigravity en paralelo en macOS: tu cuenta del trabajo y tu cuenta personal, con sesión iniciada a la vez.</b><br>
  Cada perfil tiene su propio HOME, su propio <code>--user-data-dir</code> y su propio llavero, además de un lanzador en el Dock. Bash puro, sin dependencias, licencia MIT.
</p>

<p align="center">
  <a href="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml"><img src="https://github.com/Xkongai/antigravity-2-users/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="macOS">
  <img src="https://img.shields.io/badge/shell-bash-4EAA25.svg" alt="Bash">
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja.md">日本語</a> | <b>Español</b> | <a href="README.pt-BR.md">Português (Brasil)</a> | <a href="README.fr.md">Français</a> | <a href="README.de.md">Deutsch</a> | <a href="README.ko.md">한국어</a> | <a href="README.ru.md">Русский</a>
</p>

> [!IMPORTANT]
> **Proyecto comunitario no oficial.** No está afiliado a Google, ni cuenta con su aprobación o soporte. «Antigravity» es una marca de Google LLC y aquí solo se usa para indicar con qué aplicación funciona esta herramienta. Este repositorio no contiene código, iconos ni otros recursos de Google. Úsalo solo con cuentas que sean tuyas y respeta los términos de servicio de cada cuenta con la que inicies sesión. No lo uses para eludir límites de uso u otras restricciones.

## Contenido

- [Por qué](#por-qué)
- [Cómo funciona](#cómo-funciona)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Opciones](#opciones)
- [Comprobar el aislamiento](#comprobar-el-aislamiento)
- [Actualizar](#actualizar)
- [Desinstalar](#desinstalar)
- [Preguntas frecuentes](#preguntas-frecuentes)
- [Solución de problemas](#solución-de-problemas)
- [Limitaciones conocidas](#limitaciones-conocidas)
- [Notas de seguridad](#notas-de-seguridad)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## Por qué

La aplicación de escritorio de Antigravity solo admite una cuenta de Google con sesión iniciada a la vez. Las credenciales se guardan en el llavero de macOS de tu usuario y en `~/.gemini/`. Si abres una segunda copia cambiando solo `--user-data-dir`, normalmente se abre con **la misma** cuenta, porque el backend lee `$HOME` y no el directorio de datos de Electron.

Motivos habituales para tener dos perfiles:

- **Trabajo y vida personal por separado.** El código, la cuenta y las extensiones de la empresa en una ventana; tus proyectos personales en la otra.
- **Separar clientes.** Si trabajas por tu cuenta, puedes mantener el espacio de trabajo, los ajustes y el historial de cada cliente aparte.
- **Pruebas en limpio.** Prueba extensiones, ajustes o versiones preliminares en un perfil desechable sin tocar tu configuración diaria.
- **Clases y demos.** Presenta con una cuenta de demostración limpia mientras tu cuenta real sigue funcionando.

## Cómo funciona

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

1. **HOME propio.** El lanzador define `HOME=~/.ag-profile-<id>`. Todo lo que la aplicación guarda bajo `~` (`.gemini`, `.antigravity` con las extensiones, cachés) pasa a guardarse ahí.
2. **Perfil de Electron propio.** `--user-data-dir` apunta dentro de ese HOME, así que ventanas, ajustes, almacenamiento y el bloqueo de instancia única también quedan separados.
3. **Llavero propio.** El instalador crea `~/.ag-profile-<id>/Library/Keychains/login.keychain-db` con una contraseña **aleatoria**. Esa contraseña se guarda en tu llavero de inicio de sesión habitual, en el elemento `antigravity-2-users`. El llavero del perfil está configurado para no bloquearse solo, de modo que la renovación de tokens en segundo plano sigue funcionando después de la suspensión.
4. **Aplicación lanzadora.** `osacompile` genera una pequeña aplicación AppleScript, `AG Profile <ID>.app`. Ejecuta `~/.ag-profile-<id>/.ag2u/launch.sh`, que desbloquea el llavero del perfil y luego hace `exec` del binario real de Antigravity. El icono se copia de tu Antigravity instalado durante la instalación, en tu propio Mac, y nunca se redistribuye. La aplicación se firma de forma ad hoc y, si quieres, se añade al Dock.

Tu instalación principal de Antigravity no se modifica.

## Requisitos

- Se espera que funcione en macOS 13 o posterior (Apple silicon o Intel; aún no probado en hardware real), con las herramientas que trae el sistema: `bash`, `python3`, `security`, `osacompile` y `codesign`
- La aplicación de escritorio de Antigravity instalada, por defecto en `/Applications/Antigravity.app`
- Una cuenta de administrador para escribir en `/Applications`. Si no eres administrador, usa `--app-dir ~/Applications`.
- Una segunda cuenta de Google con la que iniciar sesión

## Instalación

```bash
git clone https://github.com/Xkongai/antigravity-2-users.git
cd antigravity-2-users
./install.sh            # or: ./install.sh --link-dev --name b
```

Qué hace el instalador, paso a paso:

1. Comprueba que estás en macOS y que Antigravity está instalado.
2. Crea `~/.ag-profile-b` (permisos 700) y enlaza dentro Escritorio, Documentos y Descargas. Con `--link-dev` enlaza también tus archivos de configuración de git, ssh y la shell. Nunca sobrescribe archivos reales, y volver a ejecutarlo es seguro.
3. Genera una contraseña aleatoria para el llavero, la guarda en tu llavero de inicio de sesión, crea y desbloquea el llavero del perfil y desactiva su bloqueo automático.
4. Escribe `~/.ag-profile-b/.ag2u/launch.sh` y `config`, crea `/Applications/AG Profile B.app`, copia el icono y firma la aplicación de forma ad hoc.
5. Hace una copia de seguridad de la configuración del Dock en `~/.ag-profile-b/.ag2u/dock-backup-*.plist` y añade el lanzador junto a Antigravity. Usa `--no-dock` para omitir este paso.

Es posible que macOS pregunte una vez si `security` puede usar el elemento `antigravity-2-users`. Elige **Permitir siempre**.

## Uso

1. Abre **AG Profile B** desde el Dock, el Launchpad o `/Applications`.
2. La primera vez se abre un Antigravity limpio y sin sesión iniciada. Inicia sesión con tu segunda cuenta. Si el navegador entrega el inicio de sesión a la ventana equivocada, consulta [la devolución del inicio de sesión](#el-inicio-de-sesión-del-navegador-vuelve-a-la-ventana-equivocada).
3. A partir de ahí puedes tener las dos ventanas abiertas a la vez. Cada una conserva su propia sesión, ajustes, extensiones e historial.
4. Para abrir el mismo proyecto en ambas, usa Archivo → Abrir carpeta en cada ventana. Escritorio, Documentos y Descargas se ven desde las dos, y cualquier otra ruta absoluta también funciona.

También puedes lanzarlo desde la terminal, lo que es útil para depurar. Los argumentos adicionales se pasan a Antigravity:

```bash
./scripts/launch.sh --name b
./scripts/launch.sh --name b ~/Documents/my-project
```

Para más perfiles, `./install.sh --name c` crea `~/.ag-profile-c` y `AG Profile C.app`.

## Opciones

`install.sh`

| Opción | Valor por defecto | Significado |
|---|---|---|
| `--name <id>` | `b` | Identificador del perfil (`a-z`, `0-9`, `-`). Los datos van a `~/.ag-profile-<id>`; el lanzador es `AG Profile <ID>.app` |
| `--app-source <path>` | `/Applications/Antigravity.app` | La aplicación de Antigravity que se ejecuta |
| `--app-dir <dir>` | `/Applications` | Dónde se crea el lanzador, p. ej. `~/Applications` |
| `--no-dock` | desactivado | No modificar el Dock |
| `--link-dev` | desactivado | Enlazar también `~/.gitconfig`, `~/.ssh`, `~/.zshrc`, `~/.zprofile`, `~/.npmrc` y `~/.config/git` |
| `-h`, `--help` / `-V`, `--version` | | Ayuda / versión |

`uninstall.sh`

| Opción | Significado |
|---|---|
| `--name <id>` | Perfil que se elimina (por defecto `b`) |
| `--app-dir <dir>` | Dónde se creó el lanzador (por defecto `/Applications`) |
| `--purge` | Borrar también, sin preguntar, los datos del perfil, su llavero y la contraseña guardada (cierra la sesión de ese perfil) |
| `--keep-data` | Eliminar solo el lanzador y el icono del Dock |

`scripts/launch.sh [--name <id>] [argumentos de Antigravity…]` y `scripts/verify.sh [--name <id>]` usan `b` por defecto.

## Comprobar el aislamiento

```bash
./scripts/verify.sh --name b
```

Es una comprobación de solo lectura que muestra únicamente **nombres** de elementos, nunca secretos:

- los procesos en ejecución que usan el `--user-data-dir` de este perfil
- la configuración del llavero del perfil (debería indicar `no-timeout`) y sus elementos (`svce` / `acct`)
- los elementos de Antigravity, Gemini o Jetski en tu llavero de **inicio de sesión**
- los nombres de archivo en `~/.gemini` y en `~/.ag-profile-b/.gemini`

**Lo que deberías ver:** después de iniciar sesión en el perfil B, sus elementos aparecen en el llavero **del perfil** y sus archivos de token en `~/.ag-profile-b/.gemini`. Los elementos de tu cuenta principal siguen en el llavero de inicio de sesión.
Si los elementos del perfil B aparecen en tu llavero de inicio de sesión, macOS no está usando el llavero del perfil en tu sistema. [Abre un issue](https://github.com/Xkongai/antigravity-2-users/issues) e indica tus versiones de macOS y de Antigravity. También puedes comprobarlo a mano en **Acceso a Llaveros** → Archivo → Añadir llavero… → `~/.ag-profile-b/Library/Keychains/login.keychain-db`.

## Actualizar

- **Actualizaciones de Antigravity:** no hay que hacer nada. El lanzador ejecuta la aplicación que haya en `--app-source`. Si el icono no se actualiza, vuelve a ejecutar `./install.sh`; puede ejecutarse varias veces y no cierra tu sesión.
- **Esta herramienta:** `git pull && ./install.sh --name b` con las mismas opciones que la vez anterior. Se reutilizan los datos y el llavero del perfil.
- **Si vienes del prototipo anterior** (`Antigravity Pro 2.app`, `~/.antigravity-pro2-home`): usaba una contraseña de llavero fija y conocida públicamente. Elimina `/Applications/Antigravity Pro 2.app` y su icono del Dock. Después, o bien borras `~/.antigravity-pro2-home` y vuelves a iniciar sesión en el nuevo perfil, o bien lo mueves a `~/.ag-profile-b` antes de ejecutar `./install.sh`; en ese caso el instalador sustituye la contraseña antigua por una aleatoria.

## Desinstalar

```bash
./uninstall.sh                 # asks whether to delete profile data
./uninstall.sh --keep-data     # remove launcher + Dock entry only
./uninstall.sh --purge         # remove everything for profile b, no questions
./uninstall.sh --name c --purge
```

Solo se detienen los procesos iniciados con el `--user-data-dir` de ese perfil. Nunca se tocan tu Antigravity principal, sus datos ni tu llavero de inicio de sesión (salvo el elemento `antigravity-2-users`, si usas `--purge`).

## Preguntas frecuentes

**¿Es un sandbox?** No. Ambos perfiles se ejecutan con el mismo usuario de macOS y los mismos permisos de archivo. Lo que se separa son las **cuentas y el estado de la aplicación**; no es una barrera de seguridad.

**¿Se mezclarán las cuentas después de reiniciar?** No debería. Cada perfil lee su propio HOME, su directorio de datos y su llavero. Usa `verify.sh` para confirmarlo en tu equipo.

**¿Por qué el perfil B ve mi Escritorio y mis Documentos?** Porque están enlazados simbólicamente dentro del HOME del perfil para que puedas abrir tus proyectos. Lo que está fuera del HOME del perfil se puede abrir igualmente con rutas absolutas.

**Git o SSH no funcionan en la terminal del perfil B.** Su HOME no tiene `.gitconfig` ni `.ssh`. Vuelve a ejecutar el instalador con `--link-dev`, o configúralos por separado para esa cuenta.

**No encuentra `brew`, `node` o `pyenv`.** El HOME del perfil no tiene `.zshrc`. Usa `--link-dev`; además, el lanzador añade `/opt/homebrew/bin` y `/usr/local/bin` al PATH.

**¿Puedo tener más de dos?** Sí, un `--name` distinto por perfil.

**¿Modifica Antigravity.app?** No. Solo lee el binario y copia el icono.

## Solución de problemas

### «AG Profile B» está dañado o no se puede abrir
Vuelve a firmar el lanzador y quita el atributo de cuarentena:
```bash
codesign --force --deep --sign - "/Applications/AG Profile B.app"
xattr -dr com.apple.quarantine "/Applications/AG Profile B.app"
```
O haz clic derecho en la aplicación → Abrir.

### El lanzador no abre nada
Ejecuta `./scripts/launch.sh --name b` en la Terminal para ver los errores. Comprueba que `--app-source` apunta a un `Antigravity.app` que exista.

### El icono del Dock falta o aparece dos veces
Arrastra la aplicación desde `/Applications` al Dock a mano, o vuelve a ejecutar el instalador con `--no-dock`. Para restaurar el Dock: `defaults import com.apple.dock ~/.ag-profile-b/.ag2u/dock-backup-<time>.plist && killall Dock`.

### El inicio de sesión del navegador vuelve a la ventana equivocada
Los dos perfiles son la misma aplicación, así que macOS envía la devolución de inicio de sesión `antigravity://` a la copia que él elija, normalmente la principal. Alternativas:
1. Cierra el Antigravity principal, inicia sesión en el perfil B y vuelve a abrir el principal. Solo hace falta hacerlo una vez; la sesión se conserva.
2. Si la página de inicio de sesión ofrece un código o una URL para pegar en la aplicación, pégalo en el perfil B.

### macOS pide continuamente la contraseña del llavero
Elige **Permitir siempre** para `security` / `antigravity-2-users`. Si el llavero del perfil sigue bloqueándose, ejecuta `security set-keychain-settings ~/.ag-profile-b/Library/Keychains/login.keychain-db` o vuelve a ejecutar `./install.sh`.

### El perfil B cierra la sesión de repente o no muestra modelos
Vuelve a abrirlo desde el lanzador; así se desbloquea otra vez el llavero. Después ejecuta `verify.sh`. Si el llavero del perfil muestra un tiempo de espera, vuelve a ejecutar `./install.sh`.

## Limitaciones conocidas

- **Todavía no se ha probado en hardware real.** Los scripts pasan shellcheck y, durante el desarrollo, se ejecutaron de principio a fin en Linux con herramientas de macOS simuladas. Aún no se ha comprobado ninguna versión en un Mac real con una versión actual de Antigravity. Trátalo como experimental y cuéntanos lo que veas.
- **No está garantizado** que macOS guarde de verdad los secretos del perfil B en el llavero del perfil cuando solo se cambia `HOME`, y el comportamiento puede variar según la versión de macOS. Para eso existe `verify.sh`.
- La devolución de inicio de sesión `antigravity://` puede llegar a la ventana equivocada (ver arriba).
- La contraseña del llavero se pasa a `security` en la línea de comandos, así que durante una fracción de segundo es visible para otros procesos de tu usuario.
- Solo macOS. No hay soporte para Windows ni Linux.
- Los detalles internos de Antigravity (ubicación de archivos, flujo de inicio de sesión) pueden cambiar en cualquier actualización y romper este método.

## Notas de seguridad

- Cada llavero de perfil usa una contraseña aleatoria de 48 caracteres hexadecimales, guardada en tu propio llavero de inicio de sesión. No hay nada fijo en el código, y nada sale nunca de tu Mac.
- El llavero del perfil no se bloquea solo mientras tienes la sesión iniciada. Gracias a eso la renovación de tokens sigue funcionando, pero también significa que, una vez desbloqueado, cualquier proceso que se ejecute con tu usuario puede leerlo. Es el mismo modelo de confianza que el de tu llavero de inicio de sesión.
- El directorio del perfil se crea con permisos `700`.
- Los scripts nunca usan `sudo`, nunca descargan nada, no cambian ningún ajuste del sistema salvo el Dock (con copia de seguridad previa, y se puede omitir) y nunca tocan `Antigravity.app`.
- Lee todos los scripts antes de ejecutarlos. Son cortos.

¿Has encontrado un problema de seguridad? Abre un aviso de seguridad privado (security advisory) en GitHub en lugar de un issue público.

## Contribuir

Los issues y PR son bienvenidos, sobre todo los **informes de pruebas en un Mac real** (versión de macOS, chip, versión de Antigravity y la salida de `verify.sh` con los correos ocultos).

- Mantén el código en Bash 3.2 (la versión que trae macOS) y asegúrate de que pase `shellcheck -S style install.sh uninstall.sh scripts/*.sh`.
- Mantén las traducciones del README al día con `README.md`.
- Nada de recursos de Google en el repositorio.

## Licencia

[MIT](LICENSE) © 2026 Ai奇异点 (Xkongai)
