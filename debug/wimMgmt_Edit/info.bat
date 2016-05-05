@echo off
setlocal
if /i "%~1" equ "" goto usagehelp
if /i "%~1" equ "/?" goto usagehelp

set ext=%~x1
if /i "%ext%" equ ".wim" goto wimfile
if /i "%ext%" equ ".esd" goto wimfile
if /i "%ext%" equ ".swm" goto wimfile

::assume dealing with a directory then
set mountpath=%~1
::remove any trailing \
if /i "%mountpath:~-1%" equ "\" set mountpath=%mountpath:~,-1%

if not exist "%mountpath%\Windows" (echo error detecting mounted image at %mountpath%
goto end)
if exist "%mountpath%\Windows\SysWOW64" (set architecture=x64) else (set architecture=x86)
echo.
dism /get-mountedwiminfo
echo Image Architecture: %architecture%
dism /image:"%mountpath%" /get-currentedition
goto end


:wimfile
set wimfile=%~1
if /i "%~2" neq "" (set index=%~2)
if /i "%index%" neq "" goto detailed

dism /get-wiminfo /wimfile:"%wimfile%"
goto end

:detailed
dism /get-wiminfo /wimfile:"%wimfile%" /index:"%index%"
goto end

:usageHelp
echo.
echo   Syntax:
echo   info D:\images\win7\Win7Sp1_x64_RTM.wim
echo   info D:\images\win7\Win7Sp1_x64_RTM.wim 2
echo   info D:\Mount

:end
endlocal