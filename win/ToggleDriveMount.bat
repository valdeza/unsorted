@ECHO OFF

:: User-Defined Variables
SET drive=Z:
:: Volume: You can obtain this value by running `mountvol`.
SET volume=\\?\Volume{abcdefgh-ijkl-mnop-qrst-uvwxyz012345}\



ECHO ==ToggleDriveMount==

:: SETs %errorlevel% to 1 if non-existent 
VOL %drive% > NUL 2> NUL

IF ERRORLEVEL 1 (
	CALL:PerformOperation 0
) ELSE (
	CALL:PerformOperation 1
)
GOTO end

:: %1=boolIsMounted
:PerformOperation
ECHO drive  = %drive%
ECHO volume = %volume%
ECHO.
IF %1==1 (
	ECHO mounted? Y 
) ELSE (
	ECHO mounted? N
)
ECHO.
ECHO Before proceeding, 
ECHO (1) please confirm the above values,
ECHO (2) ensure no running programs are accessing the drive, 
ECHO (3) have ToggleDriveMount running as admin.
PAUSE

IF %1==1 (
	:: Do umount
	MOUNTVOL %drive% /p
) ELSE (
	:: Do mount
	MOUNTVOL %drive% %volume%
)

IF ERRORLEVEL 1 (
	ECHO Operation failed.
) ELSE (
	ECHO Done.
)
GOTO:EOF

:end
:: Uncomment to pause before exiting.
ping 127.0.0.1 -n 2 -w 1000 > NUL