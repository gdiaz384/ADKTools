@echo off
setlocal enabledelayedexpansion

::D:\WinPE\3_x\PE_x64\ISO\media\sources\boot.wim

::set winPERoot=D:\WinPE
::set peFileName=boot
::set default_mountPath=D:\mount

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
if /i "%~2" equ "/x64" (set architecture=x64
goto prepare)


:: assume %1 is .wim
if /i "%~x1" neq ".wim" if /i "%~x1" neq ".swm" (echo   Not a valid wimfile, cannot mount: %~1 
goto end)

set wimfile=%~1
if /i "%~2" equ "" (set wimindex=1
) else (set wimindex=%~2)
if /i "%~3" equ "" (set mountPath=%default_mountPath%
) else (set mountPath=%~3)
goto mount


:prepare
set version=%~1
set wimFile=%winPERoot%\!%architecture%PEwimPath%version%!\%peFileName%.wim
set mountPath=%winPERoot%\!%architecture%PEmountPath%version%!
if /i "%~3" neq "" (set mountPath=%3)
if /i "%~4" equ "" (set wimindex=1
) else (set wimindex=%4)


:mount
if not exist "%mountPath%" mkdir "%mountPath%" >nul 2>nul
dism /mount-wim /wimfile:"%wimFile%" /index:"%wimindex%" /mountdir:"%mountPath%"
goto end


:info
dism /get-mountedwiminfo
goto end

:clean
dism /cleanup-wim
goto end


:usagehelp
echo.
echo   Usage: mountwim.bat uses dism to mount either WinPE or a custom image
echo.
echo   Syntax:
echo   mountwim [PE_version] [PE_architecture] {mountPoint}
echo   Examples:
echo   mountwim  5  x86
echo   mountwim  3  x64  D:\mount
echo   mountwim  10 x86  D:\WinPE\10_x\PE_x86\ISO\mount
echo   Syntax:
echo   mountwim [wimPath] {index} {mountpoint}
echo   Examples:
echo   mountwim  D:\Win7Sp1x64_Rtm\install.wim
echo   mountwim  D:\Win81Prox64_Rtm\install.wim  4 
echo   mountwim  D:\Win81Prox64_Rtm\install.wim  1 D:\mount  
echo   Utility commands:
echo   mountwim  info     //displays all current mount points
echo   mountwim  clean    //removes invalid mount points
echo.
echo   Note: Using "mountwim 5 x86" or "mountwim D:\image.wim" without more 
echo   arguments will ask mountwim.bat to perform the specified action using default
echo   values. The default mount directory is D:\mount and wim index is 1.
goto end

:end
endlocal