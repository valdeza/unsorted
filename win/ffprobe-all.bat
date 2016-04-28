@ECHO OFF
::ffprobe-all.bat Quickly obtain a list of bitrates for use in ffmpeg-conv-all.bat

SET FFPROBE_BIN="%userprofile%\ProgramFiles\ffmpeg\bin\ffprobe.exe"
SET FFPROBE_OUTPUT="%systemdrive%\Temp\ffprobe-all.bat.out.txt"
SET FILTER=^*.mp4 
::  Used as a parametre for DIR. Remember to escape characters with '^'!

ECHO Writing to %FFPROBE_OUTPUT% ...
ECHO Brief mass ffprobe: > %FFPROBE_OUTPUT%
FOR /F "delims=|" %%F IN ('DIR %FILTER% /B') DO (
	ECHO Processing: %%F
    ECHO # %%F >> %FFPROBE_OUTPUT%
    %FFPROBE_BIN% "%%F" 2> ffprobe-all.bat.out.tmp.txt
	TYPE ffprobe-all.bat.out.tmp.txt | FIND "Audio" >> %FFPROBE_OUTPUT%
	ECHO. >> %FFPROBE_OUTPUT%
)
DEL ffprobe-all.bat.out.tmp.txt
ECHO Finished!