; ---------- COMMANDS
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, force ; No annoying warnings
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

; ---------- GLOBAL VARS
ScriptsPath := SubStr(A_WorkingDir, 1, InStr(SubStr(A_WorkingDir,1,-1), "\", 0, 0)-1)
TabNames := "Temp|AutoRun|Hotkeys"
Gui, ScriptManager:New ; Gui is named Script manager and accessed with colon syntax


; ---------- GENERATE THE 3 LIST VIEWS IN THE TABS
generate_tabs:
{
    Gui, ScriptManager:Add, Tab3, w500 vLVTabs, %TabNames% ; Make a new tab container in the window
    ; Select the list view should be put in, create list views with the following properties
        ; wp-25    : width of parent - 25 (fit LV nicely in container)
        ; AltSubmit: Accept right clicks
        ; glv_click: Associate the lv_click label with any action in the listview
        ; v...     : Associate a variable with the listview for easy access to it later
        ; Checked  : Add Checkboxes
    Gui, ScriptManager:Tab, Temp
    Gui, Add, ListView, wp-25 AltSubmit glv_click vTemp Checked, ScriptName|LastChange
    Gui, ScriptManager:Tab, AutoRun
    Gui, Add, ListView, wp-25 AltSubmit glv_click vAutoRun, ScriptName|LastChange
    Gui, ScriptManager:Tab, Hotkeys
    Gui, Add, ListView, wp-25 AltSubmit glv_click vHotkeys, HotkeyName|ContainingScript
    gosub update_lv
    return
}


; ---------- UPDATE THE LISTED SCRIPTS IN ALL THE LIST VIEWS
update_lv:
{
    Gui, ScriptManager:Default ; select the Main gui (ScriptManager) -> all operations apply to it
    Loop, parse, TabNames, `|` ; Loop through all the tab sections
    {
        Gui, ListView, %A_LoopField% ; Select a tab, all Gui operations apply to it
        LV_Delete() ; delete all entries in the listview
        ; if (A_LoopField in ["Temp","AutoRun"])
        Loop Files, %ScriptsPath%\%A_LoopField%\*.ahk
        {
            FormatTime, LastModified, A_LoopFileTimeModified, dd. MMM yy
            LV_Add("", A_LoopFileName, LastModified)
        }
        LV_ModifyCol()
    }
    Gui, ScriptManager:Show
    return
}


; ---------- WHEN A GUI EVENT HAPPENS IN THE LISTVIEW
lv_click:
{
    Gui, ScriptManager:Default ; select the Main gui (ScriptManager) -> all operations apply to it
    Gui, ListView, %A_GuiControl% ; important: select curr. Listview through associated var
    if (A_GuiEvent = "DoubleClick")
    {
        MsgBox, %A_DefaultListView%
    }
    else if (A_GuiEvent = "RightClick")
    {
        LV_GetText(ScriptName, A_EventInfo)  ; store selected row name in ScriptName var
        Target := A_GuiControl="Temp" ? "AutoRun" : "Temp" ; target is opposite folder
        ScriptMover := Func("move_script").Bind(ScriptName, A_GuiControl, Target) ; func to move script
        ; show the context menu with option to move script using ScriptMover func
        Menu, LVContext, Add, Move Script to %Target%, % ScriptMover
        Menu, LVContext, Show
        Menu, LVContext, DeleteAll ; clean context menu up again
    }
}


; ---------- USE THIS TO MOVE SCRIPTS FROM TEMP TO AUTORUN
move_script(Name, From, To)
{
    ; ADD LABEL TO REFRESH ALL THINGS IN LV
    global ScriptsPath
    FileMove, %ScriptsPath%\%From%\%Name%, %ScriptsPath%\%To%\%Name%
    gosub update_lv
}