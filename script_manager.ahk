; ---------- SCRIPT COMMANDS
#NoEnv                  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn                   ; Hopefully Usefull Warnings
#SingleInstance, force  ; Always just one instance running
SendMode, Input         ; Recommended for new scripts due to its superior speed and reliability.

; ---------- GLOBAL VARS
global ScriptsPath := SubStr(A_WorkingDir, 1, InStr(SubStr(A_WorkingDir,1,-1), "\", 0, 0)-1)
global TabNames := "Temp|AutoRun|Hotkeys"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TESTING AREA
gosub link_autoruns_to_startup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; ---------- HOTKEY BINDINGS
#h::gosub initalize_main ; Super + H -> open Manager
#IfWinActive script_manager.ahk ; while Manager open, ctrl + r / f5 -> refresh lv list
^r::
F5::
gosub update_lv
return


; ---------- INSTANCE THE GUI, GENERATE_TABS, GENERATE BUTTONS, UPDATE LISTVIEW
initalize_main:
{
    ; Generate the Main Gui window
    Gui, ScriptManager:New ; Gui is named Script manager and accessed with colon syntax
    Gui, ScriptManager:Default
    ; Generate the tabs and listview
    ; Gui, LVTabs:+ParentScriptManager
    Gui, Add, Tab3, w330 h340 vLVTabs, %TabNames% ; Make a new tab container in the window
    Gui, Tab, Temp ; select tab Temp
    Gui, Add, ListView, h300 w305 AltSubmit glv_click vTemp Checked, ScriptName|LastChange
    Gui, Tab, AutoRun ; select tab AutoRun
    Gui, Add, ListView, h300 w305  AltSubmit glv_click vAutoRun, ScriptName|LastChange
    Gui, Tab, Hotkeys ; select tab Hotkeys
    Gui, Add, ListView, h300 w305 glv_click vHotkeys, HotkeyName|ContainingScript
    ; Gui, Add, GroupBox, w475 h100 vButtonBox section, % "Manage Scripts"
    Gui, Tab ; Tab command without further params exits the tab container
    Gui, Add, Button, y+20 w150 ginitialize_new_script_dialogue Default, % "&New temp script"
    Gui, Add, Button, x+m w150 gopen_folder, % "&Open scripts folder"
    ; update the listviews to show all saved scripts
    gosub update_lv
    Gui, Show, w350 h400
    return
}


; ---------- UPDATE THE LISTED SCRIPTS IN ALL THE LIST VIEWS
update_lv:
{
    Gui, ScriptManager:Default ; very important
    Loop, parse, TabNames, `|` ; Loop through all the tab sections
    {
        Gui, ListView, %A_LoopField% ; Select a tab, all Gui operations apply to it
        LV_Delete() ; delete all entries in the listview
        ; if (A_LoopField in ["Temp","AutoRun"])
        Loop, Files, %ScriptsPath%\%A_LoopField%\*.ahk
        {
            FormatTime, LastModified, A_LoopFileTimeModified, dd. MMM yy
            LV_Add("", A_LoopFileName, LastModified)
        }
        LV_ModifyCol()
    }
    return
}


; ---------- SYNC SHORTCUTS IN SHELL:AUTOSTART TO FILES IN AHK_SCIPTS\AUTORUN
link_autoruns_to_startup:
{
    FilesInAutoRun := "" ; 
    Loop, Files, %ScriptsPath%\AutoRun\*.ahk
    {
        FilesInAutoRun := FilesInAutoRun . StrSplit(A_LoopFileName, ".")[1] . ","
        FileCreateShortcut, %A_LoopFilePath%, %A_Startup%\%A_LoopFileName%.lnk
    }
    Loop, Files, %A_Startup%\*.ahk.lnk
    {
        NameNoExt := StrSplit(A_LoopFileName, ".")[1]
        if NameNoExt not in %FilesInAutoRun%
        {
            FileDelete, %A_LoopFilePath%
        }
    }
}


; ---------- WHEN A GUI EVENT HAPPENS IN THE LISTVIEW
lv_click:
{
    ; very IMPORTANT: SELECT current gui as default, SELECT clicked listview
    Gui, ScriptManager:Default
    Gui, ListView, %A_GuiControl%
    LV_GetText(ScriptName, A_EventInfo)  ; store selected row name in ScriptName var
    if (A_GuiEvent = "DoubleClick")
    {
        edit_script(A_GuiControl, ScriptName)
    }
    else if (A_GuiEvent = "RightClick")
    {
        ; target folder is either temp or autorun, bind arguments to mover func in context menu
        Target := A_GuiControl="Temp" ? "AutoRun" : "Temp"
        ScriptMover := Func("move_script").Bind(ScriptName, A_GuiControl, Target)
        ; show the context menu with option to move script using ScriptMover func
        Menu, LVContext, Add, Move Script to %Target%, % ScriptMover
        Menu, LVContext, Show
        Menu, LVContext, DeleteAll ; clean context menu up again
    }
    return
}


; ---------- 
initialize_new_script_dialogue:
{
    Gui, NewScriptDialogue:New
    Gui, NewScriptDialogue:Default
    Gui, Add, Text, , Enter Script Name (no extension)
    Gui, Add, Edit, r1 w160 vNewScriptName, new_script
    Gui, Add, Button, y+m +Default gnew_temp_script, &New Script
    Gui, Add, Button, x+m gNewScriptDialogueGuiClose, &Cancel
    Gui, Show
    return
}


; ---------- 
new_temp_script:
{
    Gui, NewScriptDialogue:Submit ; Capture the NewScriptName variable from the Edit Control
    edit_script("Temp", NewScriptName ".ahk")
    return
}


; ---------- 
edit_script(Location, Name)
{
    Run, "Code" %ScriptsPath%\%Location%\%Name%
    ; Run, "Notepad++" %ScriptsPath%\%Location%\%Name%
    return
}


; ---------- 
open_folder:
{
    Run, %ScriptsPath%
    return
}


; ---------- USE THIS TO MOVE SCRIPTS FROM TEMP TO AUTORUN
move_script(Name, From, To)
{
    ; ADD LABEL TO REFRESH ALL THINGS IN LV
    FileMove, %ScriptsPath%\%From%\%Name%, %ScriptsPath%\%To%\%Name%
    gosub update_lv
    return
}


; ---------- CLOSING THE WINDOWS
NewScriptDialogueGuiEscape:
NewScriptDialogueGuiClose:
ScriptManagerGuiEscape:
ScriptManagerGuiClose:
{
    Gui, Destroy
    return
}