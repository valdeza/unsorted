; Press Esc to termiante script, Pause/Break to "pause"

; MANUAL VARIABLES
; Set these and recompile.
Global $TimeBetweenClicks = 0 ; (in milliseconds) default: 0
; To change the action performed, redefine PerformAction().

; AUTO-VARIABLES
Global $UseCustomCtr = false ; false=Click infinitely.
Global $CustomCtr = 20 ; Number of times to click.

If MsgBox(4, "Click infinitely?", "") = 7 Then ;6=Yes, 7=No
   $UseCustomCtr = True
   $CustomCtr = InputBox("How many times to click?", " ", "20", " M")
EndIf

Global $Paused = true

HotKeySet("{ESC}", "Terminate")
HotKeySet("{PAUSE}", "TogglePause")

If $Paused Then
   ToolTip("AutoRepeater ready. Awaiting program execution. [Pause/Break] to begin. [Esc] to terminate.", 0, 0)
   ;ToolTip("DEBUG:"&WinGetTitle("[active]"))
   While $Paused
       Sleep(100)
   WEnd
EndIf

While 1
   Sleep($TimeBetweenClicks)
   If $UseCustomCtr Then ; 1=Use CustomCtr, 0=Do not use
	  For $i = 0 To ($CustomCtr - 1)
		 Call("PerformAction")
	  Next
	  Call("TogglePause")
   Else
	  Call("PerformAction")
   EndIf
WEnd

Func TogglePause()
   $Paused = Not $Paused
   While $Paused
	  Sleep(100)
	  ToolTip('Script is "Paused"', 0, 0)
   WEnd
   ToolTip("")
EndFunc   ;==>TogglePause

Func PerformAction()
   MouseClick("") ; Normal CookieClicker function
   
;~    ;; Normal non-"Select All" checkbox items function
;~    Send("{SPACE}")
;~    Send("{DOWN}")
   
;~    ;; Load KB articles for all Windows Update items.
;~    Send("{TAB}")
;~    Send("{SPACE}")
;~    WinWaitNotActive("Select updates to install")
;~    WinActivate("Select updates to install")
;~    Send("+{TAB}")
;~    Send("{DOWN}")
EndFunc	;==>PerformAction

Func Terminate()
    Exit 0
EndFunc   ;==>Terminate
