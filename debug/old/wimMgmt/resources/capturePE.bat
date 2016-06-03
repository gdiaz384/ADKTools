@echo off
if /i "%~1" equ "" goto usagehelp

set name=%~1
if /i "%~2" equ "" (set description=%1) else (set description=%~2)
if /i "%~3" equ "" (set capturedir=D:\mount) else (set capturedir=%~3)

echo.
echo dism /capture-image /imagefile:%name%.wim /capturedir:%capturedir% /name:"%description%" /description:"%description%" /compress:max /bootable 

dism /capture-image /imagefile:%name%.wim /capturedir:%capturedir% /name:"%description%" /description:"%description%" /compress:max /bootable 

goto end
:usageHelp
echo.
echo   Syntax:
echo   capturePE DaRT10x64
echo   capturePE DaRT10x64 "Diagnostics and Recovery Tools v10x64"
echo   capturePE DaRT10x64 "Diagnostics and Recovery Tools v10x64" D:\mount
echo.
:end