#Requires AutoHotkey v2.0
#SingleInstance Force

; configuration
OverlayX := 10             
OverlayY := 10                
OverlayColor := "c2c2c2"      ; light gray text
OverlayBgColor := "425862"    ; dark gray background
UpdateInterval := 50          ; milliseconds between updates

; ensure proper dpi scaling
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

; create overlay GUI with wider width
overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
overlay.BackColor := OverlayBgColor
WinSetTransparent(200, overlay)
overlay.SetFont("s12", "Yu Gothic UI")
overlay.Add("Text", "w200 vCoords " "c" OverlayColor, "Mouse: Waiting...")
overlay.Show("x" OverlayX " y" OverlayY " NoActivate")

; start coordinate tracking
SetTimer(UpdateMousePos, UpdateInterval)

UpdateMousePos() {
    ; use screen coordinates for multi-monitor support
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    
    ; get current monitor info
    monitorCount := MonitorGetCount()
    currentMonitor := MonitorGetPrimary()
    
    ; format coordinates with padding for consistency
    coordText := Format("Mouse: {:6}, {:6}", x, y)
    
    try overlay["Coords"].Text := coordText
}

F1::
{
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    A_Clipboard := x " " y
}

; cleanup on exit
OnExit(ExitFunc)

ExitFunc(ExitReason, ExitCode) {
    if IsSet(overlay)
        overlay.Destroy()
}