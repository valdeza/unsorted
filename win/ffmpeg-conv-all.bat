@ECHO OFF
:: Deprecated. Instead see Invoke-FFmpegConvertToKindleMp3.psm1 for an automated solution that also uses FFprobe.

::ffmpeg-conv-all.bat Quickly mass-convert all files in the current directory of a specified file extension to an audio file.
::
:: Only tested with .mp3 since, well, my Kindle Fire likes .mp3 .

:: CUSTOM-SET CONSTANTS
SET FFMPEG_BIN="%userprofile%\ProgramFiles\ffmpeg\bin\ffmpeg.exe"
SET IN_FILTER=^*.mp4
::  Used as a parametre for DIR. Remember to escape characters with '^'!
SET sample_rate=44100
:: 	Specify the sample rate in Hz, NOT kHz.
SET bitrate=192
:: 	Specify the bitrate in kbps.
SET out_ext=mp3
::  Specify desired output extension.
:: /END CUSTOM-SET CONSTANTS

IF NOT EXIST %FFMPEG_BIN% (
    ECHO ffmpeg.exe could not be found. 
	ECHO Please check the FFMPEG_BIN at the head of this file!
    GOTO:error
)

ECHO MEDIA FILE TO MP3 CONVERSION SCRIPT
ECHO.
ECHO == CURRENT SETTINGS ==
ECHO (Change params by modifying this file)
ECHO Sample rate: %sample_rate% Hz
ECHO Target constant bitrate: %bitrate% kbps
ECHO.
PAUSE
ECHO.
:: Original command. Figuring out syntax was taking too long.
::FORFILES /C "cmd /C CALL:ProcessFile @file @fname"
FOR /F "delims=|" %%F IN ('DIR %IN_FILTER% /B') DO (
    ECHO Source: "%%F"
    ECHO Destination: "%%~nF.%out_ext%"
    ECHO.
    %FFMPEG_BIN% -i "%%F" -ar %sample_rate% -b:a %bitrate%k "%%~nF.%out_ext%"
    ECHO.
    ECHO.
    ECHO.
)
ECHO Finished!
GOTO:EOF

:error
ECHO.
ECHO ERROR: press any key to exit.
PAUSE >nul
GOTO:EOF