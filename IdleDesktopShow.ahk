#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
InstallMouseHook()

; ── Default media apps ────────────────────────────────────────────────────────
; Any of these with active audio output will block minimization.
; Add your own via Settings → Custom apps.
global DEFAULT_MEDIA_APPS := [
    "chrome.exe", "firefox.exe", "msedge.exe", "brave.exe",
    "opera.exe",  "vivaldi.exe",                           ; browsers
    "wmplayer.exe",                                         ; Windows Media Player
    "vlc.exe", "mpv.exe",                                   ; common players
    "mpc-hc.exe", "mpc-hc64.exe",                          ; Media Player Classic
    "potplayer.exe", "potplayermini64.exe",                 ; PotPlayer
    "kmplayer.exe", "gomplayer.exe", "bsplayer.exe",
]

; ── Audio-only apps ───────────────────────────────────────────────────────────
; Pure music players — their presence on an endpoint signals that the audio
; coming through is music, not video, so minimization is allowed.
global AUDIO_ONLY_APPS := Map(
    "spotify.exe",    1, "spotifywebhelper.exe", 1,
    "foobar2000.exe", 1,
    "winamp.exe",     1,
    "musicbee.exe",   1,
    "aimp.exe",       1,
    "itunes.exe",     1,
    "music.exe",      1,  ; Apple Music on Windows
    "tidal.exe",      1,
    "deezer.exe",     1,
)

; ── Constants ─────────────────────────────────────────────────────────────────
global APP_NAME := "IdleDesktopShow"
global APP_VER  := "1.0.2"
global CFG_FILE := A_AppData "\" APP_NAME "\config.ini"

global SKIP_CLASSES := Map(
    "Progman", 1, "WorkerW", 1, "Shell_TrayWnd", 1, "DV2ControlHost", 1
)

; Core Audio API GUIDs
global _CLSID_MMDevEnum  := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
global _IID_MMDevEnum    := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
global _IID_ASManager2   := "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"
global _IID_ASControl2   := "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}"
global _IID_MeterInfo    := "{C02216F6-8C67-4B5B-9D00-D008E73E0064}"

; ── Mutable state ─────────────────────────────────────────────────────────────
global idleMinutes   := 5
global customApps    := []    ; user-added app list (loaded from config)
global MEDIA_APPS    := Map() ; built from DEFAULT_MEDIA_APPS + customApps
global triggered     := false
global komorebiMode     := false
global _komorebicPaused := false
global _minimizedHwnds  := []

; ── Startup ───────────────────────────────────────────────────────────────────
LoadConfig()
_BuildMediaApps()

TraySetIcon("shell32.dll", 35)
A_IconTip := APP_NAME " v" APP_VER
A_TrayMenu.Delete()
A_TrayMenu.Add("Settings", OpenSettings)
A_TrayMenu.Add()
A_TrayMenu.Add("Quit", (*) => ExitApp())

SetTimer(CheckIdle, 5000)


; ── Idle check ────────────────────────────────────────────────────────────────

CheckIdle() {
    global triggered, idleMinutes, komorebiMode, _komorebicPaused
    idle := A_TimeIdlePhysical
    if (idle >= idleMinutes * 60000 && !_ShouldBlock()) {
        if !triggered {
            triggered := true
            if komorebiMode {
                _KomorebiShowDesktop()
            } else {
                Send "#d"
            }
        }
    } else if idle < 5000 {
        if triggered && komorebiMode && _komorebicPaused
            _KomorebiRestore()
        triggered := false
    }
}

_ShouldBlock() {
    return _HasFullscreenApp() || _IsMediaAppActive()
}

_KomorebiShowDesktop() {
    global _komorebicPaused, _minimizedHwnds, SKIP_CLASSES
    _komorebicPaused := true
    _minimizedHwnds  := []
    for hwnd in WinGetList() {
        try {
            if WinGetMinMax("ahk_id " hwnd) = -1       ; already minimized — skip
                continue
            if !(WinGetStyle("ahk_id " hwnd) & 0x10000000)  ; not WS_VISIBLE — skip
                continue
            if SKIP_CLASSES.Has(WinGetClass("ahk_id " hwnd))
                continue
            _minimizedHwnds.Push(hwnd)
            WinMinimize("ahk_id " hwnd)
        }
    }
}

_KomorebiRestore() {
    global _komorebicPaused, _minimizedHwnds
    for hwnd in _minimizedHwnds
        try WinRestore("ahk_id " hwnd)
    _minimizedHwnds := []
    Sleep(200)
    try Run("komorebic.exe retile",, "Hide")
    _komorebicPaused := false
}


; ── Fullscreen detection ──────────────────────────────────────────────────────

_HasFullscreenApp() {
    global SKIP_CLASSES
    sw := SysGet(0)
    sh := SysGet(1)
    for hwnd in WinGetList() {
        try {
            WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
            if w < sw || h < sh
                continue
            if SKIP_CLASSES.Has(WinGetClass("ahk_id " hwnd))
                continue
            return true
        }
    }
    return false
}


; ── Audio session detection (Windows Core Audio API) ─────────────────────────

_IsMediaAppActive() {
    global MEDIA_APPS, AUDIO_ONLY_APPS, _CLSID_MMDevEnum, _IID_MMDevEnum
    global _IID_ASManager2, _IID_ASControl2, _IID_MeterInfo

    try {
        pEnum := ComObject(_CLSID_MMDevEnum, _IID_MMDevEnum)

        ; EnumAudioEndpoints(eRender=0, DEVICE_STATE_ACTIVE=1, &ppCollection)
        ComCall(3, pEnum, "UInt", 0, "UInt", 1, "Ptr*", &pColl := 0)
        if !pColl
            return false

        ComCall(3, pColl, "UInt*", &devCount := 0)

        found := false
        loop devCount {
            ComCall(4, pColl, "UInt", A_Index - 1, "Ptr*", &pDev := 0)
            if !pDev
                continue
            try {
                ; Check peak — skip silent endpoints
                peak := 0.0
                gMeter := _GUID(_IID_MeterInfo)
                pMeter := 0
                try {
                    ComCall(3, pDev, "Ptr", gMeter, "UInt", 23, "Ptr", 0, "Ptr*", &pMeter)
                    if pMeter {
                        ComCall(3, pMeter, "Float*", &peak)
                        ObjRelease(pMeter)
                    }
                }

                g1 := _GUID(_IID_ASManager2)
                ComCall(3, pDev, "Ptr", g1, "UInt", 23, "Ptr", 0, "Ptr*", &pMgr := 0)
                if pMgr {
                    ComCall(5, pMgr, "Ptr*", &pSessEnum := 0)
                    ObjRelease(pMgr)
                    if pSessEnum {
                        ComCall(3, pSessEnum, "Int*", &count := 0)

                        hasMediaApp  := false
                        hasAudioOnly := false
                        loop count {
                            ComCall(4, pSessEnum, "Int", A_Index - 1, "Ptr*", &pCtrl := 0)
                            if !pCtrl
                                continue
                            try {
                                g2 := _GUID(_IID_ASControl2)
                                pCtrl2 := 0
                                try ComCall(0, pCtrl, "Ptr", g2, "Ptr*", &pCtrl2)
                                if pCtrl2 {
                                    ComCall(14, pCtrl2, "UInt*", &pid := 0)
                                    ObjRelease(pCtrl2)
                                    if pid {
                                        name := _ProcName(pid)
                                        ComCall(9, pCtrl, "UInt*", &state := 0)
                                        ; Active session in MEDIA_APPS blocks even when silent
                                        ; (covers calls/meetings where no one is speaking)
                                        if state = 1 && MEDIA_APPS.Has(name)
                                            found := true
                                        if MEDIA_APPS.Has(name)
                                            hasMediaApp := true
                                        if AUDIO_ONLY_APPS.Has(name)
                                            hasAudioOnly := true
                                    }
                                }
                            }
                            ObjRelease(pCtrl)
                        }
                        ObjRelease(pSessEnum)

                        ; Bluetooth fallback: states are unreliable (all Inactive).
                        ; Block only if there's actual audio AND a media app is present
                        ; without an audio-only app explaining it.
                        if !found && peak > 0.001 && hasMediaApp && !hasAudioOnly
                            found := true
                    }
                }
            }
            ObjRelease(pDev)
            if found
                break
        }
        ObjRelease(pColl)
        return found
    } catch {
        return false
    }
}

_GUID(str) {
    buf := Buffer(16, 0)
    DllCall("ole32\CLSIDFromString", "WStr", str, "Ptr", buf)
    return buf
}

_ProcName(pid) {
    try return StrLower(WinGetProcessName("ahk_pid " pid))
    h := DllCall("OpenProcess", "UInt", 0x1000, "Int", false, "UInt", pid, "Ptr")
    if !h
        return ""
    buf := Buffer(520, 0)
    sz  := Buffer(4)
    NumPut("UInt", 260, sz)
    DllCall("QueryFullProcessImageNameW", "Ptr", h, "UInt", 0, "Ptr", buf, "Ptr", sz)
    DllCall("CloseHandle", "Ptr", h)
    full := StrLower(StrGet(buf))
    return SubStr(full, InStr(full, "\",, -1) + 1)
}


; ── Config ────────────────────────────────────────────────────────────────────

_BuildMediaApps() {
    global MEDIA_APPS, DEFAULT_MEDIA_APPS, customApps
    MEDIA_APPS := Map()
    for app in DEFAULT_MEDIA_APPS
        MEDIA_APPS[app] := 1
    for app in customApps
        MEDIA_APPS[StrLower(Trim(app))] := 1
}

LoadConfig() {
    global idleMinutes, customApps, komorebiMode, CFG_FILE
    if !FileExist(CFG_FILE)
        return
    idleMinutes  := Integer(IniRead(CFG_FILE, "Settings", "IdleMinutes", 5))
    komorebiMode := Integer(IniRead(CFG_FILE, "Settings", "KomorebiMode", 0)) != 0
    customApps  := []
    for app in StrSplit(IniRead(CFG_FILE, "MediaApps", "Extra", ""), ",") {
        app := Trim(StrLower(app))
        if app
            customApps.Push(app)
    }
}

SaveConfig() {
    global idleMinutes, customApps, komorebiMode, CFG_FILE
    DirCreate(SubStr(CFG_FILE, 1, InStr(CFG_FILE, "\",, -1) - 1))
    IniWrite(idleMinutes,          CFG_FILE, "Settings", "IdleMinutes")
    IniWrite(komorebiMode ? 1 : 0, CFG_FILE, "Settings", "KomorebiMode")
    extra := ""
    for i, app in customApps
        extra .= (i > 1 ? "," : "") app
    IniWrite(extra, CFG_FILE, "MediaApps", "Extra")
}


; ── Startup registry ──────────────────────────────────────────────────────────

IsStartupEnabled() {
    global APP_NAME
    try {
        RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Run", APP_NAME)
        return true
    } catch {
        return false
    }
}

SetStartup(enable) {
    global APP_NAME
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    if enable
        RegWrite(A_ScriptFullPath, "REG_SZ", key, APP_NAME)
    else
        try RegDelete(key, APP_NAME)
}


; ── Settings window ───────────────────────────────────────────────────────────

OpenSettings(*) {
    global idleMinutes, customApps, komorebiMode, APP_NAME

    sg := Gui("+AlwaysOnTop", APP_NAME " — Settings")
    sg.SetFont("s9", "Segoe UI")
    sg.MarginX := 14
    sg.MarginY := 12

    ; ── Timeout ──────────────────────────────────────────────────────────────
    sg.Add("GroupBox", "x14 y12 w300 h52", "Inactivity timeout")
    sg.Add("Text", "x26 y34", "Show desktop after")
    eMin := sg.Add("Edit", "x+6 yp-3 w46 Number", idleMinutes)
    sg.Add("UpDown", "Range1-120", idleMinutes)
    sg.Add("Text", "x+6 yp+3", "minutes of inactivity")

    ; ── Startup ──────────────────────────────────────────────────────────────
    cbStart := sg.Add("Checkbox", "x16 y74", "Start automatically with Windows")
    cbStart.Value := IsStartupEnabled()

    ; ── Komorebi ─────────────────────────────────────────────────────────────
    cbKomorebi := sg.Add("Checkbox", "x16 y94", "Komorebi / tiling WM mode (preserves workspace layout)")
    cbKomorebi.Value := komorebiMode

    ; ── Media apps ───────────────────────────────────────────────────────────
    sg.Add("GroupBox", "x14 y120 w300 h172", "Apps that prevent minimization")

    sg.Add("Text", "x22 y138 w284 cGray",
        "Built-in: Chrome, Firefox, Edge, Brave, VLC, MPV, MPC-HC, WMP, PotPlayer, KMPlayer")

    sg.Add("Text", "x22 y168", "Custom apps:")

    editList := customApps.Clone()
    lb := sg.Add("ListBox", "x22 y184 w198 h70")
    for app in editList
        lb.Add([app])

    sg.Add("Button", "x224 y184 w80 h24", "Remove").OnEvent("Click", RemoveApp)

    addEdit := sg.Add("Edit", "x22 y258 w150 h24 -Multi")
    sg.Add("Button", "x176 y258 w56 h24", "Add").OnEvent("Click", AddApp)
    sg.Add("Text",   "x236 y261 cGray", "e.g. myapp.exe")

    ; ── Footer ───────────────────────────────────────────────────────────────
    sg.Add("Text", "x16 y300 cGray w296",
        "Fullscreen apps always prevent minimization regardless of this list.")

    sg.Add("Button", "x16 y322 w80", "Save"  ).OnEvent("Click", Save)
    sg.Add("Button", "x+6      w80", "Test"  ).OnEvent("Click", (*) => Send("#d"))
    sg.Add("Button", "x+6      w80", "Cancel").OnEvent("Click", (*) => sg.Destroy())

    sg.Show("w330")

    ; ── Nested handlers ──────────────────────────────────────────────────────

    AddApp(*) {
        app := Trim(StrLower(addEdit.Value))
        if !app
            return
        if !InStr(app, ".")
            app .= ".exe"
        for item in editList
            if item = app
                return
        editList.Push(app)
        lb.Add([app])
        addEdit.Value := ""
    }

    RemoveApp(*) {
        idx := lb.Value
        if idx = 0
            return
        editList.RemoveAt(idx)
        lb.Delete(idx)
    }

    Save(*) {
        global idleMinutes, customApps, komorebiMode
        v := Integer(eMin.Value)
        if v < 1 || v > 120 {
            MsgBox("Please enter a number between 1 and 120.", APP_NAME, 0x30)
            return
        }
        idleMinutes  := v
        customApps   := editList.Clone()
        komorebiMode := cbKomorebi.Value != 0
        SaveConfig()
        _BuildMediaApps()
        SetStartup(cbStart.Value)
        sg.Destroy()
    }
}
