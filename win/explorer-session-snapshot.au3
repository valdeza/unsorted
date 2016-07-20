#include <Array.au3> ; Unnecessary, just wanted to see it in action.

Local $winlist = WinList()
Local $proclist = ProcessList("explorer.exe") ; Assumed to be a small list. Will not be sorted.
;_ArrayDisplay($proclist)

Local $file = FileOpen("C:\Temp\explorer last.session.txt", 2)

For $i = 1 To $winlist[0][0]
   Local $hwnd = $winlist[$i][1]
   Local $pid = WinGetProcess($hwnd)
   
   ; Skip if not an Explorer window.
   If _ArraySearch($proclist, $pid, 0, 0, 0, 0, 1, 1) = -1 Then ContinueLoop
   
   Local $path = ControlGetText($hwnd, "", "[CLASS:ToolbarWindow32; INSTANCE:2]")
   $path = StringReplace($path, "Address: ", "", 1)
   
   ; Discard blank text from hidden explorer windows.
   If $path = "" Then ContinueLoop
   
   FileWriteLine($file, $path)
Next

FileClose($file)