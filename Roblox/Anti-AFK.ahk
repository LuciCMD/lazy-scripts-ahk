#Requires AutoHotkey v2.0
#SingleInstance Force
; Version 3.3

; Configuration
Programs := ["RobloxPlayerBeta.exe"]
Timeout := 1                   ; minutes before afk check
Delay := 2                     ; minutes between actions
Poll := 5                      ; seconds between checks
OverlayX := 10                 ; overlay x position
OverlayY := 10                 ; overlay y position
OverlayColor := "c2c2c2"      ; light gray text
OverlayBgColor := "425862"    ; dark background 

MouseWiggle := false          ; will be set by user prompt
WiggleDuration := 2000        ; ms
WiggleRadius := 15            ; pixels radius

; Convert time values to appropriate units
Timeout *= 60
Delay *= 60
poll_ms := Poll * 1000
loop_timeout_count := Map()
loop_delay_count := Map()
next_action_time := Map()
script_status := "disabled"

; Create clickthrough overlay GUI
overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; Added +E0x20 for clickthrough
overlay.BackColor := OverlayBgColor
WinSetTransparent 200, overlay
overlay.SetFont("s12", "Yu Gothic UI")
overlay.Add("Text", "vStatus " "c" OverlayColor, "Status: Initializing...")
overlay.Add("Text", "vTimer " "c" OverlayColor " y+5", "Next Action: Calculating...")
overlay.Show("x" OverlayX " y" OverlayY " NoActivate")

; Admin prompt
if !A_IsAdmin {
    admin_title := "Run as Admin?"
    admin_message := "
    (
        Anti-AFK has the option to temporarily block
        keystrokes when running as Admin.

        This is optional but be aware keystrokes may
        leak into the target window if you are typing
        whilst Anti-AFK is interacting with it.
    )"
    result := MsgBox(admin_message, admin_title, "YesNo")
    if result = "Yes"
        Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"'
}

; Mouse wiggle prompt
mouse_title := "Mouse Wiggle"
mouse_message := "Enable mouse wiggling?"
result := MsgBox(mouse_message, mouse_title, "YesNo")
MouseWiggle := result = "Yes"

; Start anti-AFK
SetTimer UpdateOnPoll, poll_ms
SetTimer UpdateOverlay, 1000
UpdateOnPoll()

ResetTimer() {
    if MouseWiggle {
        ; Store original mouse position
        MouseGetPos(&originalX, &originalY)
        
        ; Wiggle mouse in a circle
        startTime := A_TickCount
        while A_TickCount - startTime < WiggleDuration {
            angle := Mod(A_TickCount, 360)
            x := originalX + WiggleRadius * Sin(angle * 0.017453)  ; Convert to radians
            y := originalY + WiggleRadius * Cos(angle * 0.017453)
            MouseMove x, y, 2
            Sleep 10
        }
        
        ; Return mouse to original position
        MouseMove originalX, originalY, 2
    }
    
    Send "{Space down}"
    Sleep 50
    Send "{Space up}"
}

UpdateOverlay() {
    global script_status, next_action_time
    timeUntilNext := "N/A"
    
    ; Only calculate time until next action if status is active
    if (script_status = "active") {
        ; Calculate time until next action
        for window, nextTime in next_action_time {
            if nextTime && nextTime != 0 {
                timeDiff := DateDiff(nextTime, A_Now, "Seconds")
                if timeDiff > 0
                    timeUntilNext := timeDiff " seconds"
                else if timeDiff <= 0 && next_action_time[window] != 0
                    timeUntilNext := "Now"
            }
        }
    } else {
        ; If status is idle or disabled, always show N/A
        timeUntilNext := "N/A"
    }
    
    ; Update overlay text
    statusText := "Status: " StrTitle(script_status)
    timerText := "Next Action: " timeUntilNext
    
    try {
        overlay["Status"].Text := statusText
        overlay["Timer"].Text := timerText
    }
}

GetWindowState(windowId) {
    state := Map()
    state["style"] := WinGetStyle("ahk_id " windowId)
    state["wasMinimized"] := WinGetMinMax("ahk_id " windowId) = -1
    return state
}

UpdateOnPoll() {
    global loop_timeout_count, loop_delay_count, next_action_time, script_status
    script_active_flag := false
    script_idle_flag := false

    for executable in Programs {
        windows := WinGetList("ahk_exe " executable)
        for window in windows {
            if !loop_timeout_count.Has(window)
                loop_timeout_count[window] := Max(1, Round(Timeout / Poll))
            if !loop_delay_count.Has(window)
                loop_delay_count[window] := 1

            if WinActive("ahk_id " window) {
                if (A_TimeIdlePhysical > Timeout*1000) {
                    loop_delay_count[window] -= 1
                    script_active_flag := true
                } else {
                    loop_timeout_count[window] := Max(1, Round(Timeout / Poll))
                    loop_delay_count[window] := 1
                    script_idle_flag := true
                    next_action_time[window] := 0  ; Reset next action time when idle
                }

                if loop_delay_count[window] = 0 {
                    loop_delay_count[window] := Max(1, Round(Delay / Poll))
                    next_action_time[window] := DateAdd(A_Now, Delay/60, "Minutes")
                    ResetTimer()
                }
            } else {
                if loop_timeout_count[window] > 0
                    loop_timeout_count[window] -= 1

                if loop_timeout_count[window] = 0 {
                    loop_delay_count[window] -= 1
                    script_active_flag := true
                } else {
                    loop_delay_count[window] := 1
                    script_idle_flag := true
                    next_action_time[window] := 0  ; Reset next action time when idle
                }

                if loop_delay_count[window] = 0 {
                    loop_delay_count[window] := Max(1, Round(Delay / Poll))
                    next_action_time[window] := DateAdd(A_Now, Delay/60, "Minutes")
                    
                    BlockInput true
                    old_window := WinGetID("A")
                    window_state := GetWindowState(window)
                    
                    WinSetTransparent 0, "ahk_id " window
                    WinActivate "ahk_id " window
                    
                    ResetTimer()
                    
                    ; Restore window state
                    if window_state["wasMinimized"]
                        WinMoveBottom "ahk_id " window
                    
                    WinSetTransparent "OFF", "ahk_id " window
                    WinActivate "ahk_id " old_window
                    BlockInput false
                }
            }
        }
    }

    script_status := script_active_flag ? "active" : (script_idle_flag ? "idle" : "disabled")
}

; Cleanup on exit
OnExit ExitFunc

ExitFunc(ExitReason, ExitCode) {
    if IsSet(overlay)
        overlay.Destroy()
}

End::ExitApp()