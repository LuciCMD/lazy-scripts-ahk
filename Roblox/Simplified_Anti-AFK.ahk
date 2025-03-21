#Requires AutoHotkey v2.0
#SingleInstance Force

TargetProgram := "RobloxPlayerBeta.exe"
Interval := 300000 ; 5 minutes

SetTimer JumpInRoblox, Interval

JumpInRoblox() {
    global TargetProgram
    
    ; Check if Roblox is running
    robloxWindows := WinGetList("ahk_exe " TargetProgram)
    if robloxWindows.Length = 0
        return
    
    ; Store current active window
    previousWindow := WinGetID("A")
    
    for window in robloxWindows {
        wasMinimized := WinGetMinMax("ahk_id " window) = -1
        
        WinSetTransparent 0, "ahk_id " window
        WinActivate "ahk_id " window
        
        Send "{Space down}"
        Sleep 50
        Send "{Space up}"
        
        WinSetTransparent "OFF", "ahk_id " window
        if wasMinimized
            WinMinimize "ahk_id " window
    }
    
    ; Reactivate previous window
    WinActivate "ahk_id " previousWindow
    
    randVariation := Random(-10000, 10000)  ; 10 seconds
    SetTimer JumpInRoblox, Interval + randVariation
}

; Exit the script with End key
End::ExitApp()