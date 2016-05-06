@echo off
setlocal enabledelayedexpansion
pushd %~dp0

::requirements to run script
:: 1) valid dart and pe images *somewhere* (need to know where they currently are)
:: 2) R must be mapped, make sure dart and pe images are at R:\recovery\oem\resources\recovery (need to know where to put them)
:: 3) need to know which bcd store to modify, can modify unspecified store as well, but need to check 
::can also just blindly modify all BCD stores, like S:\boot\bcd S:\efi\microsoft\boot\bcd, same ones at B:\ and C:\
::but doing so might produce duplicate entries
:: (error modifying unspecified bcdstore, please specify bcd store with registerRE /store:
:: if store is valid, R exists, and source directory for tools is valid/found somewhere, then
:: 4) need to copy appropriate tools, so need to know (4) version and (5) architecture

::Offline required:
:: 2) destdir offline - required to be present so know which drive to copy to
:: 4) version offline- syntax of version required so know which version to copy
:: 5) architecture offline- architecture required since need to know which version to copy

::Offline optional:
:: 1) sourcedir offline optional since they should be found easily
:: 3) bcdstore offline- optional, can just modify sys store, but modifying S:\ sys stores prefered

::Online required:
:: 2) destdir online- required to be present so know which drive to copy to

::Online optional:
:: 1) sourcedir online- optional, but more important to know where copying .wims from or if already copied
:: 3) bcdstore online- is optional, (just modify sys store), can also search for it, duplicates issue
:: 4) version online- optional, since version should be easy to find from currently running version
:: 5) architecture online- architecture not needed since obvious to find currently running architecture (but might want to include extra x86 image for TC)

:: registerRE 
::need to find boot.sdi
::need to find Re  (RE can also be in C:\windows\system32\recovery\winre.wim)
::find dart
::find winpe 
::copy boot.sdi to , copy to R:\recovery\windowsre and R:\recovery\oem\resources\recovery
::copy re to \Recovery\WindowsRE\winre.wim
::register RE
::copy PE
::register PE
::copy dart
::register DaRT


::echo registerRE [destinationDrive] {PEversion} {architecture} {bcd store path} {winPETools}
::echo registerRE R: 5 x64 C:\boot\bcd E:\sources\win8\winPETools

::prerequsites
if "%~1" equ "" goto usageHelp
if not exist "%~1" goto usageHelp
set destDrive=%~1

::check to make sure either bcd output is valid or that a bcdstore was specified
if "%~4" equ "" set callback=postbcdSysStoreVerification
if "%~4" equ "" set useSysStore=true
if "%~4" equ "" goto bcdSysStoreVerification
if "%~4" neq "" if not exist "%~4" (echo Error: bcdstore not found at %~4
goto end)
if "%~4" neq "" if exist "%~4" (set bcdpath=%~4
set useSysStore=false)
:postbcdSysStoreVerification
if /i "%useSysStore%" neq "true" if /i "%useSysStore%" neq "false" (echo unspecified bcdstore error
goto end)

:: Sanity check: make sure some \Windows directory exists (besides at x) 
set windowsValid=false
for %%i in (B,C,D,R,T,W) do (if exist %%i:\Windows (set windowsValid=true))
if /i "%windowsValid%" neq "true" (echo error finding a valid Windows directory, please make sure Windows is installed
goto end)

::other variables
set recoverypath=%destDrive%\Recovery\OEM\resources\recovery
set ramdisk=boot.sdi

::pe version
::if user specified peversion and architecture, use those
::if user specified peversion but not architecture, set pe/os version and discover architecture
::if user specified neither, discover both
if /i "%~2" neq "" (set PEversion=%~2
goto setOSversion)

::find current OS version and use it to define the PE version
diskpart /s nonexist.txt > temp.txt
for /f "tokens=4" %%i in ('find /n "version" temp.txt') do set rawversion=%%i
::rawversion=6.0.6001
for /f "tokens=1,2 delims=." %%i in ("%rawversion%") do set rawversion=%%i.%%j
::rawversion=6.0
del temp.txt

set version=%rawversion%
if /i "%rawVersion%" equ "6.0" set PEversion=2
if /i "%rawVersion%" equ "6.1" set PEversion=3
if /i "%rawVersion%" equ "6.2" set PEversion=4
if /i "%rawVersion%" equ "6.3" set PEversion=5
if /i "%rawVersion%" equ "10.0" set PEversion=10

:setOSversion
if /i "%PEversion%" equ "2" (set internalPEversion=2
set osVersion=Vista)
if /i "%PEversion%" equ "3" (set internalPEversion=31
set osVersion=7)
if /i "%PEversion%" equ "4" (set internalPEversion=4
set osVersion=8)
if /i "%PEversion%" equ "5" (set internalPEversion=51
set osVersion=81)
if /i "%PEversion%" equ "10" (set internalPEversion=10
set osVersion=10)


::some checks to make sure everything is just peachy
if /i "%PEversion%" neq "10" if /i "%PEversion%" neq "5" if /i "%PEversion%" neq "4" if /i "%PEversion%" neq "3" if /i "%PEversion%" neq "2" goto usageHelp
if /i "%internalPEversion%" neq "10" if /i "%internalPEversion%" neq "51" if /i "%internalPEversion%" neq "4" if /i "%internalPEversion%" neq "31" if /i "%internalPEversion%" neq "2" goto usageHelp
if /i "%osVersion%" neq "10" if /i "%osVersion%" neq "81" if /i "%internalPEversion%" neq "8" if /i "%osVersion%" neq "7" if /i "%osVersion%" neq "Vista" goto usageHelp

::architecture
if /i "%processor_architecture%" equ "AMD64" (set currentArchitecture=x64) else (set currentArchitecture=x86)
if /i "%~3" equ "" (set architecture=%currentArchitecture%) else (set architecture=%~3)
if /i "%architecture%" neq "x64" if /i "%architecture%" neq "x86" goto usageHelp

::User specified custom source path to look for DaRT/PE (but still search for sdi and winre)
if /i "%~5" neq "" (if not exist "%~5" (echo Error: source path "%~5" does not exist, please check the path and try again
goto end))
if /i "%~5" neq "" if exist "%~5" set (winPEToolsPath=%~5
set winPEToolsPathSpecified=true)
if /i "%~5" equ "" set winPEToolsPathSpecified=false

:: define where to look (3 types of locations)
:: Network drives (likely to be mapped) Z, T,Y
:: OS drives (likely to have an OS)
:: removable drives (everything besides A and X)
set networkDrives=X,Z,T,Y
set osDrives=W,T,D,E,C,B,S,R
set removableDrives=X,Z,W,V,U,T,S,R,Q,P,O,N,M,L,K,J,I,H,Y,G,F,C,B,D,E

::define what to look for
set winre=winre!internalPEversion!_!architecture!.wim
set dart=dart!OSversion!_!architecture!.wim
set winpe=winPE!internalPEversion!_!architecture!.wim

echo winre:%winre%
echo dart:%dart%
echo winpe:%winpe%

::find images
::boot.sdi
::least preferred::
set searchPath5=\boot\%ramdisk%
set searchPath4=\Windows\System32\scripts\resources\%ramdisk%
set searchPath3=\Windows\System32\RemInst\boot\%ramdisk%
set searchPath2=\Recovery\oem\resources\recovery\%ramdisk%
set searchPath1=\Windows\boot\dvd\pcat\%ramdisk%
set searchPath0=\Recovery\WindowsRE\%ramdisk%
::most preferred::

set sdiStatus=invalid
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath5%" (set sdiFullPath=%%i:%searchPath5%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath4%" (set sdiFullPath=%%i:%searchPath4%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath3%" (set sdiFullPath=%%i:%searchPath3%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath2%" (set sdiFullPath=%%i:%searchPath2%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath1%" (set sdiFullPath=%%i:%searchPath1%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath0%" (set sdiFullPath=%%i:%searchPath0%))

if not exist "%sdiFullPath%" (echo Error: Unable to find valid %ramdisk%
goto error)
if exist "%sdiFullPath%" (set sdiStatus=valid
echo %ramdisk% found at "%sdiFullPath%")

::copy "%sdiFullPath%" "%destDrive%"
::echo Using boot.sdi found at:  "%sdiFullPath%" 


::WinRE
::7::E:\images\win8\x64\winrex86.wim -old
::6::Y:\images\Win8\winPETools  -network drive (exported source)
::5::Y:\WinPE\3_x\winRE -network drive (non-exported source)
::4::E:\sources\win10\winPETools  -designated
::3::E:\sources\                                     -currently booting from it
::2::B:R:\recovery\oem\resources\recovery  -already deployed backup
::1::C:\windows\system32\recovery\winre.wim current image original source
::0::C:\recovery\windowsre -currently deployed
::least preferred::
set searchPath7=\images\win%osVersion%\%architecture%\winre%version%\%winre%
set searchPath6=\images\Win%osVersion%\winPETools\%winre%
set searchPath5=\WinPE\%PEversion%_x\winRE\%winre%
set searchPath4=\sources\win%osVersion%\winPETools\%winre%
set searchPath3=\sources\%winre%
set searchPath2=\recovery\oem\resources\recovery\%winre%
set searchPath1=\windows\system32\recovery\%winre%
set searchPath0=\Recovery\WindowsRE\winre.wim
::most preferred::

set winreStatus=invalid
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath7%" (set winreFullPath=%%i:%searchPath7%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath6%" (set winreFullPath=%%i:%searchPath6%))
for %%i in (%networkDrives%) do (if exist "%%i:%searchPath5%" (set winreFullPath=%%i:%searchPath5%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath4%" (set winreFullPath=%%i:%searchPath4%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath3%" (set winreFullPath=%%i:%searchPath3%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath2%" (set winreFullPath=%%i:%searchPath2%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath1%" (set winreFullPath=%%i:%searchPath1%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath0%" (set winreFullPath=%%i:%searchPath0%))

if exist %winreFullPath% (set winreStatus=valid
echo %winre% found at %winreFullPath%)
if /i "%winreStatus%" neq "valid" echo  No WinRE image found:"%winre%" 

if /i "%winPEToolsPathSpecified%" equ "true" goto customDetect

::DaRT
::6::C:\recovery\windowsre  -old
::5::E:\images\win8\x64\dartx86.wim -old
::4::Y:\images\Win81\winPETools  -network drive (exported non-original source)
::3::Y:\winpe\10_x\DaRT\  -network drive (iso media original source)
::2::E:\sources\win10\winPETools  -designated place
::1::E:\sources\                                     -current a usb and booting from it
::0::B:R:\recovery\oem\resources\recovery  -already deployed
set searchPath6=\recovery\windowsre\%dart%
set searchPath5=\images\Win%OSversion%\%architecture%\%dart%
set searchPath4=\images\Win%OSversion%\winPETools\%dart%
set searchPath3=\winpe\%PEversion%_x\DaRT\%dart%
set searchPath2=\sources\win%OSversion%\winpetools\%dart%
set searchPath1=\sources\%dart%
set searchPath0=\recovery\oem\resources\recovery\%dart%

set dartStatus=invalid
for %%i in (%osDrives%) do (if exist "%%i:%searchPath6%" (set dartFullPath=%%i:%searchPath6%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath5%" (set dartFullPath=%%i:%searchPath5%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath4%" (set dartFullPath=%%i:%searchPath4%))
for %%i in (%networkDrives%) do (if exist "%%i:%searchPath3%" (set dartFullPath=%%i:%searchPath3%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath2%" (set dartFullPath=%%i:%searchPath2%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath1%" (set dartFullPath=%%i:%searchPath1%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath0%" (set dartFullPath=%%i:%searchPath0%))

if exist %dartFullPath% (set dartStatus=valid
echo %dart% found at %dartFullPath%)
if /i "%dartStatus%" neq "valid" echo  No DaRT image found:"%dart%" 

::WinPE
::6::C:\recovery\windowsre  -old
::5::E:\images\win8\x64\winpe51_x86.wim -old
::4::Y:\images\Win81\winPETools  -network drive (exported non-original source)
::3::Y:\WinPE\10_x\PE_x64\ISO\media\sources\boot.wim  -network drive (iso media original source)
::2::E:\sources\win10\winPETools  -2nd most ideal place
::1::E:\sources\                              -most ideal place (current usb and booting from it)
::0::B:R:\recovery\oem\resources\recovery  -already deployed
set searchPath6=\recovery\windowsre\%winpe%
set searchPath5=\images\Win%OSversion%\%architecture%\%winpe%
set searchPath4=\images\Win%OSversion%\winPETools\%winpe%
set searchPath3=\WinPE\%PEversion%_x\PE_%architecture%\ISO\media\sources\boot.wim
set searchPath2=\sources\win%OSversion%\winpetools\%winpe%
set searchPath1=\sources\%winpe%
set searchPath0=\recovery\oem\resources\recovery\%winpe%

set winpeStatus=invalid
for %%i in (%osDrives%) do (if exist "%%i:%searchPath6%" (set winpeFullPath=%%i:%searchPath6%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath5%" (set winpeFullPath=%%i:%searchPath5%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath4%" (set winpeFullPath=%%i:%searchPath4%))
for %%i in (%networkDrives%) do (if exist "%%i:%searchPath3%" (set winpeFullPath=%%i:%searchPath3%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath2%" (set winpeFullPath=%%i:%searchPath2%))
for %%i in (%removableDrives%) do (if exist "%%i:%searchPath1%" (set winpeFullPath=%%i:%searchPath1%))
for %%i in (%osDrives%) do (if exist "%%i:%searchPath0%" (set winpeFullPath=%%i:%searchPath0%))

if exist %winpeFullPath% (set winpeStatus=valid
echo %winpe% found at %winpeFullPath%)
if /i "%winpeStatus%" neq "valid" echo  No PE image found:"%winpe%" 
goto next


:customDetect
set dartFullPath=%winPEToolsPath%\%dart%
if exist %dartFullPath% (set dartStatus=valid
echo %dart% found at %dartFullPath%)
if /i "%dartStatus%" neq "valid" echo  No DaRT image found:"%dart%" 

set winpeFullPath=%winPEToolsPath%\%winpe%
if exist %winpeFullPath% (set winpeStatus=valid
echo %winpe% found at %winpeFullPath%)
if /i "%winpeStatus%" neq "valid" echo  No winPE image found:"%winpe%" 


:next
::check to make sure at least one image type is valid
if /i "%winREStatus%" neq "valid" if /i "%dartStatus%" neq "valid" if /i "%winPEStatus%" neq "valid" (echo  No winre/dart/winpe images found, cannot set recovery options
goto error)

::set sourceFullPath & set destPath & set destFilename
::check if dest already exists
::echo copy from source to dest
::copy from source to dest
::could also check if a bootloader with a matching description exists, 
::then update the entry/not add a duplicate instead of blindly adding them
::that code might be better off in the bcdAddPE script tho

::@echo off
echo sdiStatus=%sdiStatus%
if /i "%sdiStatus%" equ "valid" (set sourceFullPath=%sdiFullPath%&set destPath=%recoveryPath%&set destFilename=%ramdisk%&set callback=sdi)
if /i "%sdiStatus%" equ "valid" goto copy
:sdi
if /i "%sdiStatus%" equ "valid" (set sourceFullPath=%sdiFullPath%&set destPath=%destDrive%\Recovery\WindowsRE&set destFilename=%ramdisk%&set callback=sdi2)
if /i "%sdiStatus%" equ "valid" goto copy
:sdi2

::if there's already a winre.wim at \recovery\WindowsRE\winre.wim don't copy another one to \recovery\oem\resources\recovery\%winre%
::register at existing location instead (%destdrive%\Recovery\WindowsRE\winre.wim)
if exist "%destDrive%\Recovery\WindowsRE\winre.wim" (
if /i "%useSysStore%" equ "false" (call bcdAddPE /addMain "%destDrive%\Recovery\WindowsRE\winre.wim" "Windows Recovery" "%bcdpath%")
if /i "%useSysStore%" equ "true" (call bcdAddPE /addMain "%destDrive%\Recovery\WindowsRE\winre.wim" "Windows Recovery")
goto startPEcopy)

echo winreStatus=%winREStatus%
if /i "%winreStatus%" equ "valid"  (set sourceFullPath=%winreFullPath%&set destPath=%recoveryPath%&set destFilename=%winre%&set callback=winre)
if /i "%winreStatus%" equ "valid" goto copy
:winre
if /i "%winreStatus%" equ "valid" if /i "%useSysStore%" equ "false" (call bcdAddPE /addMain "%recoverypath%\%winre%" "Windows Recovery" "%bcdpath%")
if /i "%winreStatus%" equ "valid" if /i "%useSysStore%" equ "true" (call bcdAddPE /addMain "%recoverypath%\%winre%" "Windows Recovery")

:startPEcopy
echo winPEStatus=%winPEStatus%
if /i "%winPEStatus%" equ "valid" (set sourceFullPath=%winpeFullPath%&set destPath=%recoveryPath%&set destFilename=%winpe%&set callback=winpe)
if /i "%winPEStatus%" equ "valid" goto copy
:winpe

if /i "%winpeStatus%" equ "valid" if /i "%useSysStore%" equ "false" (call bcdAddPE /addTool "%recoverypath%\%winpe%" "Windows PE v%PEversion%%architecture%" "%bcdpath%")
if /i "%winpeStatus%" equ "valid" if /i "%useSysStore%" equ "true" (call bcdAddPE /addTool "%recoverypath%\%winpe%" "Windows PE v%PEversion%%architecture%")

echo dartStatus=%dartStatus%
if /i "%dartStatus%" equ "valid" (set sourceFullPath=%dartFullPath%&set destPath=%recoveryPath%&set destFilename=%dart%&set callback=dart)
if /i "%dartStatus%" equ "valid" goto copy
:dart
if /i "%dartStatus%" equ "valid" if /i "%useSysStore%" equ "false" (call bcdAddPE /addTool "%recoverypath%\%dart%" "Diagnostics and Recovery Tools v%OSversion%%architecture%" "%bcdpath%")
if /i "%dartStatus%" equ "valid" if /i "%useSysStore%" equ "true" (call bcdAddPE /addTool "%recoverypath%\%dart%"  "Diagnostics and Recovery Tools v%OSversion%%architecture%")

goto end


:copy
if exist "%destPath%\%destFilename%" (echo "%destPath%\%destFilename%" already exists
goto %callback%)

::have to modify some permissions for copy to work, maybeh for mkdir too
attrib -h -s "%sourceFullPath%"
if not exist "%destPath%" mkdir "%destPath%"  1>nul 2>nul
if not exist "%destPath%" (echo error creating %destPath%
goto error)

::copy the images where they need to go, register them after returning
echo copying from: "%sourceFullPath%"
echo      to:"%destPath%\%destFilename%"
copy "%sourceFullPath%" "%destPath%\%destFilename%" /y
goto %callback%


:bcdSysStoreVerification
bcdedit > bcddump.txt
set bcdExtension=nul
for /f "tokens=2 skip=2" %%a in ('find /n "path" bcddump.txt') do set bcdExtension=%%~xa
if /i "%bcdExtension%" equ "nul" (echo error opening system BCD store for editing. Please specify a bcdstore manually
goto error)
if /i "%bcdExtension%" neq ".exe" if /i "%bcdExtension%" neq ".efi" (echo "%bcdextension%" error opening system store. Please specify a bcdstore manually
goto error)
del bcddump.txt
goto %callback%


:prompt
echo Are you sure (yes/no)?
set /p userInput=
if /i "%userInput%" equ "y" goto %callback%
if /i "%userInput%" equ "ye" goto %callback%
if /i "%userInput%" equ "yes" goto %callback%
if /i "%userInput%" equ "n" goto end
if /i "%userInput%" equ "no" goto end
goto prompt

:error
set > \dump.txt
echo.
echo   A fatal error has occured and %~nx0 must not continue. 
echo   Full set local variable information is available at:  \dump.txt
echo.
goto end

:usageHelp
echo.
echo  Usage: registerRE.bat attempts to copy winre.wim, DaRT.wim and WinPE.wim to 
echo  R:\recovery\oem\resources\recovery and then register them with the bcd store
echo  This script can be run from WinPE or online.
echo.
echo  Syntax:
echo  registerRE [destDrive] {PEversn} {architecture} {bcd store path} {winPETools}
echo  Examples:
echo  registerRE R:
echo  registerRE R: 5 x64
echo  registerRE R: 5 x64 C:\boot\bcd
echo  registerRE R: 5 x64 C:\boot\bcd E:\sources\win8\winPETools
echo.
echo  Notes:  If running this in a PE env, specify both the PE version to copy 
echo  and architecture, else the currently running PE version will be used instead
echo  winre format: winrePEver_arch.wim  winre31_x64.wim  winre10_x86.wim
echo  DaRT  format: dartOSver_arch.wim  DaRT7_x86.wim DaRT81_x64.wim
echo  winPE format: winpePEver_arch.wim  WinPE31_x86.wim WinPE51_x64.wim
echo.
:end
popd
endlocal