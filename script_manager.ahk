#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, force ; No annoying warnings
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

scripts_path := SubStr(A_WorkingDir, 1, InStr(SubStr(A_WorkingDir,1,-1), "\", 0, 0)-1)

Gui, ScriptManager:New ; Gui is named Script manager and accessed with colon syntax
Gui, ScriptManager:Add, Tab3, w500, AutoRunScripts|TempScripts|ActiveHotkeys ; Make a new tab in the window

Gui, ScriptManager:Tab, AutoRun ; Select a tab, all Gui calls reference this tab now
Gui, Add, ListView, wp-25 AltSubmit gLVClick, ScriptName|LastChange
Loop Files, %scripts_path%\Learning\*.ahk
{
    FormatTime, LastModified, A_LoopFileTimeModified, dd. MMM yy
    LV_Add("", A_LoopFileName, LastModified)
}
LV_ModifyCol()

Gui, ScriptManager:Tab, Temp
Gui, Add, Slider, vMySlider3, 50

Gui, ScriptManager:Show


; When a Gui Event happens in the Listview
LVClick:
if (A_GuiEvent = "DoubleClick") {
    MsgBox, DoubleDick
}
else if (A_GuiEvent = "RightClick") {
    ; function object for context menu click
    LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
    rightclick := Func("test_func").Bind(RowText)

    Menu, LVContext, Add, test, % rightclick
    Menu, LVContext, Show
}

; Use this to move stuff from temp to autorun
test_func(x) {
    MsgBox, %x%
}