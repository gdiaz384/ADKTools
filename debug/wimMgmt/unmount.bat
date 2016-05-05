@echo off
setlocal enabledelayedexpansion

::D:\WinPE\3_x\PE_x86\ISO\mount

set discardOrCommit=commit

::set default_mountPath=D:\mount
::set RemoteInstallPath=D:\RemoteInstall
::set PEfileName=boot

::set winPERoot=D:\WinPE
::set x86PEwimPath3=3_x\PE_x86\ISO\media\sources
::set x64PEwimPath3=3_x\PE_x64\ISO\media\sources
::set x86PEmountPath3=3_x\PE_x86\ISO\mount
::set x64PEmountPath3=3_x\PE_x64\ISO\mount

::set x86PEwimPath4=4_x\PE_x86\ISO\media\sources
::set x64PEwimPath4=4_x\PE_x64\ISO\media\sources
::set x86PEmountPath4=4_x\PE_x86\ISO\mount
::set x64PEmountPath4=4_x\PE_x64\ISO\mount

::set x86PEwimPath5=5_x\PE_x86\ISO\media\sources
::set x64PEwimPath5=5_x\PE_x64\ISO\media\sources
::set x86PEmountPath5=5_x\PE_x86\ISO\mount
::set x64PEmountPath5=5_x\PE_x64\ISO\mount

::set x86PEwimPath10=10_x\PE_x86\ISO\media\sources
::set x64PEwimPath10=10_x\PE_x64\ISO\media\sources
::set x86PEmountPath10=10_x\PE_x86\ISO\mount
::set x64PEmountPath10=10_x\PE_x64\ISO\mount


if /i "%~1" equ "/?" goto usagehelp
if /i "%~1" equ "" goto usagehelp
if /i "%~1" equ "/info" goto info
if /i "%~1" equ "info" goto info
if /i "%~1" equ "/clean" goto clean
if /i "%~1" equ "clean" goto clean
if /i "%~2" equ "x86" (set architecture=x86
goto prepare)
if /i "%~2" equ "/x86" (set architecture=x86
goto prepare)
if /i "%~2" equ "x64" (set architecture=x64
goto prepare)
if /i "%~2" equ "/64" (set architecture=x64
goto prepare)


::assume other directory
:other
set copySource=
set unmountPath=%~1
if /i "%~2" neq "" set discardOrCommit=%~2
if /i "%discardOrCommit%" neq "commit" if /i "%discardOrCommit%" neq "discard" (echo error setting discardOrCommit status to: "%~2"
goto end)
goto unmount


:prepare
set version=%~1
set copySource=%winPERoot%\!%architecture%PEwimPath%version%!
set unmountPath=%winPERoot%\!%architecture%PEmountPath%version%!
if "%~3" neq "" set discardOrCommit=%~3
if /i "%discardOrCommit%" neq "commit" if /i "%discardOrCommit%" neq "discard" (echo error setting discardOrCommit status to: "%~3"
goto end)
::if /i not "%~3" equ "" (set discardOrCommit=discard)
goto unmount


:unmount
dism /unmount-wim /mountdir:"%unmountPath%" /%discardOrCommit%


if "%errorlevel%" equ "0" if "%errorlevel%" geq "1" (
::UpdatePXE stuffs
if /i "%discardOrCommit%" equ "commit" if not "%copySource%" equ "" if /i "%architecture%" neq "" (
del %RemoteInstallPath%\boot\%architecture%\Images\boot.wim /q
echo.
echo    copying from: %copySource%\%PEfileName%.wim
echo    copying to:     %RemoteInstallPath%\boot\%architecture%\Images\boot%architecture%.wim
copy %copySource%\%PEfileName%.wim %RemoteInstallPath%\boot\%architecture%\Images\boot%architecture%.wim /y
echo.
echo    Please restart PXE for the updated %1 boot.wim to take effect.
)) else if "0" neq "0" (
echo.
echo   Close apps and run unmount.bat again using discard.
echo   unmount x86 3 discard    or    unmount d:\path discard
)
goto end

::Add these lines to replace the "echo Please restart PXE..." above to reset PXE automatically
::WDSUTIL /stop-transportserver
::WDSUTIL /Start-TransportServer


:info
dism /get-mountedwiminfo
goto end

:clean
dism /cleanup-wim
goto end


:usagehelp
echo.
echo   Usage: unmount.bat uses dism to unmount either WinPE or a custom image
echo. 
echo   unmount  [version]  [WinPE_architecture]  {discard}
echo   unmount  [mount directory]  {discard}
echo   Examples:
echo   unmount  3  x86
echo   unmount  5  x64  discard
echo   unmount  D:\mount
echo   unmount  D:\mount  discard
echo   unmount  info    //displays all current mount points
echo   unmount  clean   //removes invalid mount points
echo.
echo   Note: Using "unmount 3 x64" or "unmount D:\mount" without more arguments 
echo   will ask unmount.bat to perform the specified action using default values.
echo   Default is to commit changes; use discard if not desired. If dismounting
echo   fails, close apps and run "unmount d:\path discard" and then "unmount clean"
goto end

:end
endlocal