# IdleDesktopShow

**[English](#english) · [Español](#español)**

| | |
|---|---|
| **English** | **Español** |
| [The problem](#the-problem) | [El problema](#el-problema) |
| [What it does](#what-it-does) | [Qué hace](#qué-hace) |
| [Download & use](#download--use) | [Descarga y uso](#descarga-y-uso) |
| [Configuration](#configuration) | [Configuración](#configuración) |
| &nbsp;&nbsp;↳ [Adding custom apps](#adding-custom-apps) | &nbsp;&nbsp;↳ [Agregar apps personalizadas](#agregar-apps-personalizadas) |
| &nbsp;&nbsp;↳ [Komorebi / tiling WM mode](#komorebi--tiling-wm-mode) | &nbsp;&nbsp;↳ [Modo Komorebi / tiling WM](#modo-komorebi--tiling-wm) |
| [How it works](#how-it-works) | [Cómo funciona](#cómo-funciona) |
| [Known limitations](#known-limitations) | [Limitaciones conocidas](#limitaciones-conocidas) |

---

## English

### The problem

Users who enjoy custom wallpapers — especially animated ones with tools like Wallpaper Engine — rarely get to actually see them. With a browser, a game, or any other program always open, the desktop stays buried. The only way to see it is to manually click "Show Desktop" in the corner of the taskbar.

Windows does have a screensaver, but it locks the screen — and that's not the same thing. Animated wallpapers don't work on the lock screen, and locking the PC just to see the desktop for a moment isn't practical. What's missing is a simple way for the PC to automatically minimize everything after stepping away, so the wallpaper is visible when coming back, and a quick `Alt+Tab` brings everything back.

---

### What it does

**IdleDesktopShow** runs silently in the system tray and automatically presses `Win+D` (Show Desktop) after a configurable period of inactivity.

**Smart detection:** It detects when you're watching or listening to something and skips minimization. It doesn't matter if the video is fullscreen or in a window — as long as a media app (browser, video player, etc.) is producing audio, it won't interrupt you. Only pure audio apps like Spotify, foobar2000, or Winamp will still allow the desktop to show.

---

### Download & use

Go to the [**Releases**](../../releases/latest) page and download the file that works for you:

| File | Requirements |
|---|---|
| `IdleDesktopShow.exe` | Nothing — just double-click |
| `IdleDesktopShow.ahk` | [AutoHotkey v2](https://www.autohotkey.com/download/) installed |

Once running, a small icon appears in your system tray. Right-click it → **Settings** to configure your idle time.

---

### Configuration

Right-click the tray icon → **Settings**:

| Setting | Description |
|---|---|
| **Idle time** | Minutes of inactivity before showing desktop (default: 5) |
| **Start with Windows** | Launch automatically when you log in |
| **Komorebi / tiling WM mode** | Minimizes windows individually to preserve workspace layouts |
| **Custom apps** | Add extra apps that should prevent minimization when playing audio |

Click **Test** to trigger Show Desktop immediately and verify it works.

Config is saved to `%AppData%\IdleDesktopShow\config.ini` the first time you click **Save**. If you never open Settings, the app uses the defaults and the file is never created.

#### Komorebi / tiling WM mode

If you use a tiling window manager like [komorebi](https://github.com/LGUG2Z/komorebi), enable this option to prevent workspace layouts from being disrupted.

**Without this option:** the app sends `Win+D`, which is a global minimize-all that bypasses the tiling WM and causes windows to lose their workspace assignments.

**With this option:** each window is minimized individually instead. Tiling WMs track minimize events per window and per workspace, so when you return, every window is restored to its original workspace and `komorebic retile` is called to restore the layout.

> Requires `komorebic.exe` to be available in your system PATH (it normally is if komorebi is installed and running).

---

#### Adding custom apps

The app needs the **executable name** (the `.exe` file name), not the full path. To find it:

1. Open **Task Manager** (`Ctrl+Shift+Esc`)
2. Find the process in the list
3. Look at the **Name** column — that's the executable name

Then enter it in Settings → Custom apps. The `.exe` extension is added automatically if you omit it.

**Examples:**

| App | Add as |
|---|---|
| OBS Studio | `obs64.exe` |
| Twitch app | `twitch.exe` |
| Minecraft (Java) | `javaw.exe` |
| Any browser not built-in | `opera_gx.exe` |

> **What to add:** Apps that play **video or mixed media** — for example, a browser not in the built-in list, a video player, or a streaming app.
>
> **What NOT to add:** Pure music players (Spotify, foobar2000, Winamp, iTunes, etc.). These are intentionally excluded — the app already recognizes them and allows the desktop to show while music plays in the background. Adding them to the custom list would cause the opposite effect and block minimization.

---

### How it works

Every 5 seconds the app checks how long the keyboard and mouse have been idle. If the idle time exceeds your threshold, it checks two things before minimizing:

1. **Fullscreen check** — any fullscreen app (game, video, browser) → don't minimize
2. **Audio check** — if a media app from the list below is actively producing audio → don't minimize

If both checks pass, it sends `Win+D` (Show Desktop). When you come back and move the mouse or press a key, the timer resets.

**Built-in media apps** (produce audio → block minimization):
Chrome, Firefox, Edge, Brave, Opera, Vivaldi, VLC, MPV, MPC-HC, Windows Media Player, PotPlayer, KMPlayer, GOM Player

**Not in the list** (audio-only → allow minimization):
Spotify, foobar2000, Winamp, MusicBee, AIMP, iTunes — and anything else not added to the custom list.

---

### Known limitations

- A video playing with the system volume muted won't be detected by the audio check (fullscreen check still works)

---

---

## Español

### El problema

Los usuarios que disfrutan de fondos de pantalla personalizados — especialmente animados con herramientas como Wallpaper Engine — casi nunca llegan a verlos. Con el navegador, un juego o cualquier otro programa siempre abierto, el escritorio queda enterrado. La única forma de verlo es haciendo clic manualmente en "Mostrar escritorio" en la esquina de la barra de tareas.

Windows tiene el protector de pantalla, pero bloquea la pantalla — y eso no es lo mismo. Los fondos animados no funcionan en la pantalla de bloqueo, y bloquear la PC solo para ver el escritorio un momento no es práctico. Lo que falta es una forma sencilla de que la PC minimice todo automáticamente al alejarse, para que el fondo de pantalla sea visible al volver, y un simple `Alt+Tab` restaure todo.

---

### Qué hace

**IdleDesktopShow** corre silenciosamente en la bandeja del sistema y automáticamente presiona `Win+D` (Mostrar escritorio) después de un tiempo de inactividad configurable.

**Detección inteligente:** Detecta cuando estás viendo o escuchando algo y no minimiza. No importa si el video está en pantalla completa o en ventana — si algún app de medios (navegador, reproductor de video, etc.) está produciendo audio, no te interrumpe. Solo apps de audio puro como Spotify, foobar2000 o Winamp permiten que el escritorio se muestre.

---

### Descarga y uso

Ve a la página de [**Releases**](../../releases/latest) y descargá el archivo que prefieras:

| Archivo | Requisitos |
|---|---|
| `IdleDesktopShow.exe` | Ninguno — solo doble clic |
| `IdleDesktopShow.ahk` | Tener [AutoHotkey v2](https://www.autohotkey.com/download/) instalado |

Al ejecutarlo, aparece un ícono pequeño en la bandeja del sistema. Clic derecho → **Settings** para configurar el tiempo de inactividad.

---

### Configuración

Clic derecho en el ícono de la bandeja → **Settings**:

| Ajuste | Descripción |
|---|---|
| **Idle time** | Minutos de inactividad antes de mostrar el escritorio (por defecto: 5) |
| **Start with Windows** | Iniciar automáticamente al encender la PC |
| **Komorebi / tiling WM mode** | Minimiza las ventanas individualmente para preservar el layout de los workspaces |
| **Custom apps** | Agregar apps extra que deban bloquear la minimización cuando reproduzcan audio |

Usa el botón **Test** para activar "Mostrar escritorio" de inmediato y verificar que funciona.

La configuración se guarda en `%AppData%\IdleDesktopShow\config.ini` la primera vez que haces clic en **Save**. Si nunca abres Settings, la app usa los valores por defecto y el archivo nunca se crea.

#### Modo Komorebi / tiling WM

Si usas un tiling window manager como [komorebi](https://github.com/LGUG2Z/komorebi), activa esta opción para evitar que los layouts de los workspaces se rompan al mostrar el escritorio.

**Sin esta opción:** la app envía `Win+D`, que es un minimize global que bypasea el tiling WM y hace que las ventanas pierdan su asignación de workspace.

**Con esta opción:** cada ventana se minimiza individualmente. Los tiling WMs rastrean los eventos de minimize por ventana y por workspace, así que al volver, cada ventana se restaura en su workspace original y se ejecuta `komorebic retile` para restaurar el layout.

> Requiere que `komorebic.exe` esté disponible en el PATH del sistema (normalmente lo está si komorebi está instalado y corriendo).

---

#### Agregar apps personalizadas

La app necesita el **nombre del ejecutable** (el archivo `.exe`), no la ruta completa. Para encontrarlo:

1. Abre el **Administrador de tareas** (`Ctrl+Shift+Esc`)
2. Busca el proceso en la lista
3. Revisa la columna **Nombre** — ese es el nombre del ejecutable

Luego ingrésalo en Settings → Custom apps. La extensión `.exe` se agrega automáticamente si la omites.

**Ejemplos:**

| App | Agregar como |
|---|---|
| OBS Studio | `obs64.exe` |
| App de Twitch | `twitch.exe` |
| Minecraft (Java) | `javaw.exe` |
| Cualquier navegador no incluido | `opera_gx.exe` |

> **Qué agregar:** Apps que reproduzcan **video o contenido mixto** — por ejemplo, un navegador que no esté en la lista integrada, un reproductor de video, o una app de streaming.
>
> **Qué NO agregar:** Reproductores de música pura (Spotify, foobar2000, Winamp, iTunes, etc.). Estos están excluidos intencionalmente — la app ya los reconoce y permite que el escritorio se muestre mientras la música suena de fondo. Agregarlos a la lista custom tendría el efecto contrario y bloquearía la minimización.

---

### Cómo funciona

Cada 5 segundos la app verifica cuánto tiempo llevan el teclado y el mouse inactivos. Si el tiempo supera el umbral, hace dos verificaciones antes de minimizar:

1. **Pantalla completa** — cualquier app en fullscreen (juego, video, navegador) → no minimiza
2. **Audio activo** — si alguna app de la lista está reproduciendo audio en ese momento → no minimiza

Si ambas verificaciones pasan, envía `Win+D`. Al volver y mover el mouse, el temporizador se reinicia.

**Apps de medios incluidas por defecto** (audio activo → bloquea minimización):
Chrome, Firefox, Edge, Brave, Opera, Vivaldi, VLC, MPV, MPC-HC, Windows Media Player, PotPlayer, KMPlayer, GOM Player

**Fuera de la lista** (solo audio → permite minimización):
Spotify, foobar2000, Winamp, MusicBee, AIMP, iTunes — y cualquier otra que no agregues a la lista custom.

---

### Limitaciones conocidas

- Un video en silencio (volumen en cero) no será detectado por la verificación de audio — aunque el fullscreen sí lo cubre
