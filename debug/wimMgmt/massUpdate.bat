@echo off
setlocal enabledelayedexpansion

::set winPERoot=D:\WinPE
::set peFileName=boot
::set default_mountPath=D:\mount
::set peRuntimeScripts=D:\scripts\peRuntime
::set peMgmtScripts=D:\scripts\wimMgmt
::set pxePath=D:\RemoteInstall\boot

::set x86PEwimPath2=2_x\PE_x86\ISO\media\sources
::set x64PEwimPath2=2_x\PE_x64\ISO\media\sources
::set x86PEmountPath2=2_x\PE_x86\ISO\mount
::set x64PEmountPath2=2_x\PE_x64\ISO\mount
::set x86PEisoPath2=2_x\PE_x86
::set x64PEisoPath2=2_x\PE_x64

::set x86PEwimPath3=3_x\PE_x86\ISO\media\sources
::set x64PEwimPath3=3_x\PE_x64\ISO\media\sources
::set x86PEmountPath3=3_x\PE_x86\ISO\mount
::set x64PEmountPath3=3_x\PE_x64\ISO\mount
::set x86PEisoPath3=3_x\PE_x86
::set x64PEisoPath3=3_x\PE_x64

::set x86PEwimPath4=4_x\PE_x86\ISO\media\sources
::set x64PEwimPath4=4_x\PE_x64\ISO\media\sources
::set x86PEmountPath4=4_x\PE_x86\ISO\mount
::set x64PEmountPath4=4_x\PE_x64\ISO\mount
::set x86PEisoPath4=4_x\PE_x86
::set x64PEisoPath4=4_x\PE_x64

::set x86PEwimPath5=5_x\PE_x86\ISO\media\sources
::set x64PEwimPath5=5_x\PE_x64\ISO\media\sources
::set x86PEmountPath5=5_x\PE_x86\ISO\mount
::set x64PEmountPath5=5_x\PE_x64\ISO\mount
::set x86PEisoPath5=5_x\PE_x86
::set x64PEisoPath5=5_x\PE_x64

::set x86PEwimPath10=10_x\PE_x86\ISO\media\sources
::set x64PEwimPath10=10_x\PE_x64\ISO\media\sources
::set x86PEmountPath10=10_x\PE_x86\ISO\mount
::set x64PEmountPath10=10_x\PE_x64\ISO\mount
::set x86PEisoPath10=10_x\PE_x86
::set x64PEisoPath10=10_x\PE_x64


if /i "%~1" equ "/?" goto usageHelp
if /i "%~1" equ "" goto usageHelp
if /i "%~2" equ "" goto usageHelp
if /i "%~2" equ "all" set updateAll=true
if /i "%~2" neq "all" goto prepare
:callback
if /i "%~1" equ "reset" goto reset
if /i "%~1" equ "scripts" goto scripts
if /i "%~1" equ "export" goto export
goto usageHelp


:prepare
if /i "%~3" equ "" goto usageHelp
set updateAll=false
set version=%~2
if /i "%version%" neq "10" if /i "%version%" neq "5" if /i "%version%" neq "4" if /i "%version%" neq "3" if /i "%version%" neq "2" goto usageHelp
set internalVersion=nul
set osVersion=nul
if /i "%version%" equ "2" (set internalVersion=2
set osVersion=Vista)
if /i "%version%" equ "3" (set internalVersion=31
set osVersion=7)
if /i "%version%" equ "4" (set internalVersion=4
set osVersion=8)
if /i "%version%" equ "5" (set internalVersion=51
set osVersion=8)
if /i "%version%" equ "10" (set internalVersion=10
set osVersion=10)
if /i "%internalVersion%" equ "nul" (echo error setting internal version for: %version%
goto end)
if /i "%osVersion%" equ "nul" (echo error setting os version for: %version%
goto end)
set architecture=%~3
if /i "%architecture%" neq "x64" if /i "%architecture%" neq "x86" goto usageHelp
goto callback


:reset
if /i "%updateAll%" equ "true" goto resetAll
::delete 1 image
::copy over image
::mount
::update scripts
::update drivers
::dismount

if /i "%version%" equ "2" (echo  Reset of WinPE version %version% not supported, please update using update.bat
goto end)
if /i "%version%" equ "10" echo  Reset of WinPE version %version% not fully supported. Image reset wil occur but driver updates may error out

::D:\WinPE\5_x\PE_x64\ISO\media\sources\boot.wim
set bootWimPath=%winPERoot%\!%architecture%PEwimPath%version%!\%peFileName%.wim
set origBootWimPath=%winPERoot%\!%architecture%PEisoPath%version%!\originalWim\winpe%internalVersion%.wim
::D:\WinPE\5_x\PE_x64\originalWim\winpe51.wim

if not exist "%origBootWimPath%" (echo   Error: Could not find original boot wim at "%origBootWimPath%"
goto end)
if exist "%default_mountPath%\Windows" (echo   Error: Another image is currently mounted at "%default_mountPath%"
goto end)

call mountwim "%origBootWimPath%" "1" "%default_mountPath%"
call update other scripts "%default_mountPath%"
call update other drivers "%default_mountPath%" "%peDriverRoot%\!pe%version%driverDirectory!\%architecture%"
call update %version% %architecture% packages "%default_mountPath%"
::D:\updates\drivers\winPE\3_x\x64

if exist "%bootWimPath%" del "%bootWimPath%"
dism /capture-image /ImageFile:"%bootWimPath%" /Capturedir:"%default_mountPath%" /name:"WinPE%internalVersion%_%architecture%" /description:"WinPE%internalVersion%_%architecture%" /compress:max /bootable /verify
call unmount "%default_mountPath%" discard
goto end

:resetAll
::delete all images
::copy over image
::mount
::update scripts
::update drivers
::dismount
::-repeat
::version 2 x86 drivers will not update, 2 x64 untested
::call massupdate reset 2 x86
::call massupdate reset 2 x64
call massupdate reset 3 x86
call massupdate reset 3 x64
call massupdate reset 5 x86
call massupdate reset 5 x64
::DISMv10 doesn't support adding drivers to PEv10. 
::driver update will fail, wait for bug fix~
call massupdate reset 10 x86
call massupdate reset 10 x64
goto end


:scripts
if "%updateAll%" equ "true" goto scriptsAll
::mount
::update scripts
::dismount
call mountwim "%version%" "%architecture%"
call update "%version%" "%architecture%" scripts
call unmount "%version%" "%architecture%"
goto end

:scriptsAll
::mount
::update scripts
::dismount-repeat
::repeat
call massupdate scripts 2 x86
call massupdate scripts 2 x64
call massupdate scripts 3 x86
call massupdate scripts 3 x64
call massupdate scripts 5 x86
call massupdate scripts 5 x64
call massupdate scripts 10 x86
call massupdate scripts 10 x64
goto end


::D:\WinPE\3_x\PE_x64\ISO\media\sources\boot.wim
::WinPEv31_x64.iso
::wimperoot\x64PEwimPath4\pefilename
:export
if "%updateAll%" equ "true" goto exportAll
::del existing iso
::create new .iso
::del existing .wim in wds
::copy new boot.wim in wds
::copy
set isoPath=%winPERoot%\!%architecture%PEisoPath%version%!\WinPEv%internalVersion%_%architecture%.iso
if exist "%isoPath%" del "%isoPath%"
set isoPath=%winPERoot%\!%architecture%PEisoPath%version%!\WinPE%internalVersion%_%architecture%.iso
set bootWimPathNoExt=%winPERoot%\!%architecture%PEwimPath%version%!\%peFileName%
set pxeWimPath=%pxePath%\%architecture%\Images\WinPE%internalVersion%_%architecture%.wim
set imagesPath=D:\Images\Win%osVersion%\%architecture%\WinPE%internalVersion%_%architecture%.wim

if exist "%isoPath%" del "%isoPath%"
call convertwim toiso "%bootWimPathNoExt%.wim" "%version%" "%architecture%"
echo moving: "%bootWimPathNoExt%.iso"
echo     to: "%isoPath%"
move /y "%bootWimPathNoExt%.iso" "%isoPath%"

::del D:\RemoteInstall\boot\x86\Images\WinPEv31_x86.wim
del "%pxeWimPath%"
echo copying: "%bootWimPathNoExt%.wim"
echo      to: "%pxeWimPath%"
copy /y "%bootWimPathNoExt%.wim" "%pxeWimPath%"

::D:\images\Win10\x64\WinPEv10_x64.wim
if /i "%version%" equ "2" goto end
if /i "%version%" neq "2" goto end
echo copying: "%bootWimPathNoExt%.wim"
echo      to: "%imagesPath%"
copy /y "%bootWimPathNoExt%.wim" "%imagesPath%"
goto end

:exportAll
::del existing iso
::create new .iso
::del existing .wim in wds
::dism export new .wim in wds
::repeat
call massUpdate export 2 x86
call massUpdate export 2 x64
call massUpdate export 3 x86
call massUpdate export 3 x64
call massUpdate export 5 x86
call massUpdate export 5 x64
call massUpdate export 10 x86
call massUpdate export 10 x64
goto end


:UsageHelp
echo   Usage: massUpdate uses mountwim/update/unmount/convertwim to manage
echo   multiple PE wim images simultaneously. massUpdate has 3 usage modes
echo   and each mode supports updating all pe images or a specific one.
echo   -reset-   deletes current, copies original, updates scripts/drivers
echo   -scripts- updates the scripts
echo   -export-  converts the boot.wim files to isos and updates WDS (PXE)
echo.
echo   Syntax:
echo   massupdate reset 5 x86
echo   massupdate reset all
echo   massupdate scripts 3 x86
echo   massupdate scripts all
echo   massupdate export 10 x64
echo   massupdate export all


:end