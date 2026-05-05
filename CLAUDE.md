# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**IdleDesktopShow** is a Windows system-tray app written in **AutoHotkey v2** that automatically presses `Win+D` (Show Desktop) after a configurable idle period. It skips minimization when a fullscreen app is detected or when a media app in the allowlist is actively producing audio.

## Running the script

Requires [AutoHotkey v2](https://www.autohotkey.com/download/) installed.

```bat
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" IdleDesktopShow.ahk
```

## Building the .exe

Requires Ahk2Exe (the compiler, separate from the runtime). Install it once via:

```bat
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" "C:\Program Files\AutoHotkey\UX\install-ahk2exe.ahk"
```

Then compile:

```bat
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in IdleDesktopShow.ahk /out dist\IdleDesktopShow.exe
```

CI (`.github/workflows/release.yml`) handles this automatically on version tags via `choco install autohotkey`.

## Architecture

Single-file script (`IdleDesktopShow.ahk`). Execution flow:

1. `LoadConfig()` + `_BuildMediaApps()` run at startup to populate globals from `config.ini`.
2. `SetTimer(CheckIdle, 5000)` polls every 5 s.
3. `CheckIdle()` reads `A_TimeIdlePhysical`; if idle ≥ threshold and `!_ShouldBlock()`, sends `#d` once (guarded by `triggered` flag). Resets `triggered` when idle < 5 s.
4. `_ShouldBlock()` — returns `_HasFullscreenApp() || _IsMediaAppActive()`.
5. `_HasFullscreenApp()` — iterates `WinGetList()`, skips shell/tray windows via `SKIP_CLASSES` map, returns `true` if any remaining window covers the full primary screen (`SysGet(0)` × `SysGet(1)`).
6. `_IsMediaAppActive()` — uses Windows Core Audio COM API (`IAudioSessionManager2`) to enumerate active audio sessions on the default render endpoint; resolves each session's PID to a process name via `_ProcName()` and checks it against the `MEDIA_APPS` lookup map.

### Key globals

| Global | Purpose |
|---|---|
| `idleMinutes` | Threshold (default 5); persisted in config |
| `triggered` | Prevents repeated `Win+D` during a single idle stretch |
| `MEDIA_APPS` | `Map` of lowercase `.exe` names built from `DEFAULT_MEDIA_APPS` + `customApps` |
| `SKIP_CLASSES` | Shell window classes excluded from fullscreen detection (`Progman`, `WorkerW`, `Shell_TrayWnd`, `DV2ControlHost`) |

### Config & startup

- Config file: `%AppData%\IdleDesktopShow\config.ini` (`IniRead`/`IniWrite`)
- Startup registry key: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- `SaveConfig()` + `_BuildMediaApps()` + `SetStartup()` are all called together from the `Save()` closure inside `OpenSettings()`

## Key AHK v2 details

- All shared state is declared `global` at the top; every function that writes a global must redeclare `global varname` inside the function body.
- `A_TimeIdlePhysical` — milliseconds since last physical keyboard/mouse input.
- `SysGet(0)` / `SysGet(1)` — primary screen width/height (SM_CXSCREEN / SM_CYSCREEN).
- `A_ScriptFullPath` — path to the running `.ahk` or compiled `.exe`; used as the startup registry value.
- COM interop uses raw `ComCall` vtable indices. The audio detection GUIDs are constants at the top of the file; `_GUID()` converts a string GUID to a 16-byte `Buffer` via `ole32\CLSIDFromString`.

## Known limitations

- Audio detection only covers the **default audio output device**.
- A video playing with system volume muted bypasses the audio check (fullscreen check still catches it if fullscreen).
