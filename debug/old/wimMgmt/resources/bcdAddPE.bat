@echo off
setlocal enabledelayedexpansion

if /i "%~1" equ "" goto usageHelp
if /i "%~2" equ "" goto usageHelp
if /i "%~x2" neq ".wim" goto usageHelp
::set extension=%~x2

if /i "%~1" equ "/addPE" goto addPE
if /i "%~1" equ "addPE" goto addPE
if /i "%~1" equ "/addMain" (set main=true
goto addTool)
if /i "%~1" equ "addMain" (set main=true
goto addTool)
if /i "%~1" equ "/addTool" (set main=false
goto addTool)
if /i "%~1" equ "addTool" (set main=false
goto addTool)
goto usageHelp

::bcdAddPE /addPE  WinPEv10_x64.wim c:\iso\efi\microsoft\boot\bcd  "Win 10 PE x64"
::bcdedit /store "%store%" /set %guid% device %ramdiskpath%\%bootwim%,%deviceguid%

:addPE
if not exist "%~3" goto usageHelp
set store=%~3
set bootwim=%~nx2
set bootwimpath=%~p2
if /i "%~4" equ "" (set description=%~n2) else (set description=%~4)

bcdedit /store "%store%" /enum all /v > bcdStoreFull.txt
bcdedit /store "%store%" > bcdStoreSummary.txt

set callback=addPE1
goto getDeviceGuid
:addPE1
set callback=addPE2
goto getBootModeExtension
:addPE2
set callback=doneCheckingPE
goto checkForDuplicates
:doneCheckingPE
set callback=addPE3
goto createEntryKnownStore
:addPE3

set ramdiskpath=[boot]%bootwimpath%

bcdedit /store "%store%" /set %guid% device ramdisk=%ramdiskpath%%bootwim%,%deviceguid% >nul
bcdedit /store "%store%" /set %guid% osdevice ramdisk=%ramdiskpath%%bootwim%,%deviceguid% >nul

if /i "%matchfound%" neq "true" bcdedit /store "%store%" /displayorder %guid% /addlast >nul
bcdedit /store "%store%" /timeout 8 >nul

bcdedit /store "%store%" /set {default} bootmenupolicy legacy >nul
bcdedit /store "%store%" /deletevalue %deviceguid% description >nul 2>nul
goto end


::bcdAddPE /addTool C:\Recovery\oem\dart8_x86.wim "Diagnostics and Recovery Tools v8x86" S:\boot\bcd
:addTool
if not exist "%~f2" goto usageHelp
if not exist "%~2" goto usageHelp
set bootwim=%~nx2
set bootwimpath=%~p2
set bootwimdrive=%~d2
if /i "%~3" equ "" (set description=%~n2) else (set description=%~3)

set store=nul
::find out if bcdstore specified %4
::if so use specified bcd store to bcd.txt

if /i "%~4" neq "" (if not exist "%~4" goto usageHelp
set store=%~4)
if /i "%~4" neq ""  (bcdedit /store "%store%" /enum all /v > bcdStoreFull.txt
bcdedit /store "%store%" > bcdStoreSummary.txt)

if /i "%~4" equ "" (bcdedit /enum all /v > bcdStoreFull.txt
bcdedit > bcdStoreSummary.txt)
::echo chosen bcdstore is at:"%store%"

set callback=addTool1
goto getDeviceGuid
:addTool1

set callback=addTool2
goto getBootModeExtension
:addTool2

set callback=doneCheckingTool
goto checkForDuplicates
:doneCheckingTool

set callback=addTool3
if /i "%store%" neq "nul" goto createEntryKnownStore
if /i "%store%" equ "nul" goto createEntrySysStore
:addTool3

::bcdAddPE /addTool C:\Recovery\oem\dart8_x86.wim "Diagnostics and Recovery Tools v8x86" S:\boot\bcd
::bcdedit /store "%store%" /set %guid% device ramdisk=[c:]\Recovery\DaRT7x64.wim,%deviceguid%
::if bcd store specified do this set
if /i "%store%" neq "nul" (
bcdedit /store "%store%" /set %guid% device ramdisk=[%bootwimdrive%]%bootwimpath%%bootwim%,%deviceguid% >nul
bcdedit /store "%store%" /set %guid% osdevice ramdisk=[%bootwimdrive%]%bootwimpath%%bootwim%,%deviceguid% >nul
bcdedit /store "%store%" /set {default} bootmenupolicy legacy >nul
bcdedit /store "%store%" /deletevalue %deviceguid% description >nul 2>nul
bcdedit /store "%store%" /timeout 3 >nul
if /i "%matchfound%" neq "true" if /i "%main%" equ "true" bcdedit /store "%store%" /displayorder %guid% /addlast >nul
if /i "%matchfound%" neq "true" if /i "%main%" equ "false" bcdedit /store "%store%" /toolsdisplayorder %guid% /addfirst >nul)

::bcdAddPE /addTool C:\Recovery\oem\dart8_x86.wim "Diagnostics and Recovery Tools v8x86"
::bcdedit /set %guid% device ramdisk=[c:]\Recovery\DaRT7x64.wim,%deviceguid%
::if bcdstore not specified, modify system store set
if /i "%store%" equ "nul" (
bcdedit /set %guid% device ramdisk=[%bootwimdrive%]%bootwimpath%%bootwim%,%deviceguid% >nul
bcdedit /set %guid% osdevice ramdisk=[%bootwimdrive%]%bootwimpath%%bootwim%,%deviceguid% >nul
bcdedit /set {default} bootmenupolicy legacy >nul
bcdedit /deletevalue %deviceguid% description >nul 2>nul
bcdedit /timeout 3 >nul
if /i "%matchfound%" neq "true" if /i "%main%" equ "true" bcdedit /displayorder %guid% /addlast >nul
if /i "%matchfound%" neq "true" if /i "%main%" equ "false" bcdedit /toolsdisplayorder %guid% /addfirst >nul)

::check if add main, then bcdedit /displayorder %guid% /addlast, else if tools bcdedit /tooldisplayorder %guid% /addfirst
::cleanup stuffs
goto end



:createEntryKnownStore
if /i "%matchfound%" equ "true" goto skipCreateEntryKnownStore
bcdedit /store "%store%" /create /d "%description%" /application osloader > guid.txt
::guid.txt=The entry {2b211139-43b1-11e5-8b3f-000c29fadf59} was successfully created.
::echo guid.txt contents:
type guid.txt
for /f "tokens=1-5 delims={}" %%a in (guid.txt) do set guid={%%b}
del guid.txt
::echo guid set to: %guid%
:skipCreateEntryKnownStore
bcdedit /store "%store%" /set %guid% path \Windows\system32\boot\winload.%bcdExtension% >nul
bcdedit /store "%store%" /set %guid% systemroot \Windows >nul
bcdedit /store "%store%" /set %guid% winpe Yes >nul
bcdedit /store "%store%" /set %guid% detecthal Yes  >nul
goto %callback%


:createEntrySysStore
if /i "%matchfound%" equ "true" goto skipCreateEntrySysStore
bcdedit /create /d "%description%" /application osloader > guid.txt
::guid.txt=The entry {2b211139-43b1-11e5-8b3f-000c29fadf59} was successfully created.
::echo guid.txt contents:
type guid.txt
for /f "tokens=1-5 delims={}" %%a in (guid.txt) do set guid={%%b}
del guid.txt
::echo guid set to: %guid%
:skipCreateEntrySysStore
bcdedit /set %guid% path \Windows\system32\boot\winload.%bcdExtension% >nul
bcdedit /set %guid% systemroot \Windows  >nul
bcdedit /set %guid% winpe Yes  >nul
bcdedit /set %guid% detecthal Yes >nul
goto %callback%


:getBootModeExtension
if not exist bcdStoreSummary.txt (echo Error: bcdStoreSummary.txt not found
goto end)
set bcdExtension=nul
for /f "tokens=2 skip=2" %%a in ('find /n "path" bcdStoreSummary.txt') do set bcdExtension=%%~xa
if /i "%bcdExtension%" equ "nul" (echo error determining bcdextension: "%bcdextension%"
goto error)
if /i "%bcdExtension%" neq ".exe" if /i "%bcdExtension%" neq ".efi" (echo error determining bcdextension: "%bcdextension%"
goto error)
::remove the . in .exe
for /f "delims=." %%i in ("%bcdExtension%") do set bcdExtension=%%i
goto %callback%


:checkForDuplicates
if not exist bcdStoreFull.txt (echo  Error: bcdStoreFull.txt not found
goto end)

::before creating a new store entry with a new guid
::check description
::if description matches then do not create new entry, instead
::get guid of duplicate
::set guid to that of the duplicate (one already in the store)
::and merge input data with current store data (set guid and continue normally)
::[73]description             Windows PE v3x86
for /f "tokens=1,2* delims=[] " %%a in ('find /n "description" bcdStoreFull.txt') do (
if "%%c" equ "%description%" set descMatchLine=%%a&set matchfound=true)
::if "%%c" equ "%description%" echo  Line "%%a" match found: "%%c"&set descMatchLine=%%a&set matchfound=true


if /i "%matchfound%" neq "true" goto %callback%
set guid=invalid

set /a descMatchLine-=1
for /f "skip=%descMatchLine%" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next1
set guid=%%b)

:next1
set /a descMatchLine-=1
for /f "skip=%descMatchLine% tokens=1*" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next2
set guid=%%b)

:next2
set /a descMatchLine-=1
for /f "skip=%descMatchLine% tokens=1*" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next3
set guid=%%b)

:next3
set /a descMatchLine-=1
for /f "skip=%descMatchLine% tokens=1*" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next4
set guid=%%b)

:next4
set /a descMatchLine-=1
for /f "skip=%descMatchLine% tokens=1*" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next5
set guid=%%b)

:next5
set /a descMatchLine-=1
for /f "skip=%descMatchLine% tokens=1*" %%a in (bcdStoreFull.txt) do (
if "%%a" neq "identifier" goto next6
set guid=%%b)

:next6
::if match was found but no identifier was found within 6 lines, assume there was some sort of 
::error and just go ahead and duplicate the entry despite the match (fail softly)
if /i "%guid%" equ "invalid" (echo   minor error: A bcd description match was detected but no guid was found
set matchfound=false)
::echo   guid of match is: "%guid%"
goto %callback%


:getDeviceGuid
if not exist bcdStoreFull.txt (echo Error: bcdStoreFull.txt not found
goto end)

::check if device options exist, if not create new store
::if they exist, continue normally
for /f "tokens=1-5" %%a in ('find /c "Device options" bcdStoreFull.txt') do set count=%%c
::---------- BCD_FULL.TXT: 1
if not %count% geq 1 goto createDevOptions

set skiplines=1
for /f "delims=[]" %%a in ('find /n "Device options" bcdStoreFull.txt') do set /a skiplines=%%a+1
::---------- BCD_FULL.TXT
::[165]Device options
::so skiplines should be 1+165, so if it's really small, there's prolly a mistake somewhere
if /i %skiplines% leq 5 (echo unspecified error
goto end)
set deviceguid=nul
if exist device.txt del device.txt
for /f "tokens=1-5 skip=%skiplines%" %%a in (bcdStoreFull.txt) do if /i "%%a" equ "identifier" (
set deviceguid=%%b
goto next)
:next
::del bcdstore.txt
::echo   deviceguid set to: %deviceguid%
if /i "%deviceguid%" neq "nul" goto %callback%


::okay so a device options entry was not found, let's create one
:createDevOptions
echo  Unable to find "Device options" attempting to create a new one...
if /i "%1" equ "/addpe" goto createPEDevice
if /i "%1" equ "addpe" goto createPEDevice

set searchDrives=Z,F,G,P,E,T,W,D,C,B,S,R
set ramdisk=boot.sdi

::if addmain or addtool are specified
::if in live os, or setting up boot options from PE prior to reagentc activation then
::search for a valid .sdi, if not found, tell user to create device options manually or mount recovery drive first
::4::\boot\%ramdisk% -random one from removable media
::3::\Windows\System32\RemInst\boot\boot.sdi    -no idea if this one will work
::2::\Recovery\oem\resources\recovery\boot.sdi -find one in the recovery partition already
::1::\Windows\boot\dvd\pcat\boot.sdi   -windows (10) sometimes moves it post RTM install for auto-RE setup
::0::\recovery\windowsre\boot.sdi    -or one already in use

set searchPath4=\boot\%ramdisk%
set searchPath3=\Windows\System32\RemInst\boot\%ramdisk%
set searchPath2=\Recovery\oem\resources\recovery\%ramdisk%
set searchPath1=\Windows\boot\dvd\pcat\%ramdisk%
set searchPath0=\Recovery\WindowsRE\%ramdisk%

set sdiStatus=invalid
for %%i in (%searchDrives%) do (if exist "%%i:%searchPath4%" (set sdiDrive=%%i:
set sdiSourcePath=%searchPath4%))
for %%i in (%searchDrives%) do (if exist "%%i:%searchPath3%" (set sdiDrive=%%i:
set sdiSourcePath=%searchPath3%))
for %%i in (%searchDrives%) do (if exist "%%i:%searchPath2%" (set sdiDrive=%%i:
set sdiSourcePath=%searchPath2%))
for %%i in (%searchDrives%) do (if exist "%%i:%searchPath1%" (set sdiDrive=%%i:
set sdiSourcePath=%searchPath1%))
for %%i in (%searchDrives%) do (if exist "%%i:%searchPath0%" (set sdiDrive=%%i:
set sdiSourcePath=%searchPath0%))

if not exist "%sdiDrive%%sdiSourcePath%" (echo Error: Please mount recovery drive or create device store "bcdedit /create /device" before using bcdAddPE
goto error)
if exist "%sdiDrive%%sdiSourcePath%" (set sdiStatus=valid
echo %ramdisk% found at "%sdiDrive%%sdiSourcePath%")

::so, is the store specified or not?
if /i "%store%" equ "nul" goto createDeviceSysStore

::assume "%store%" is not nul, and create device in specified bcd store
:createDeviceSpecifiedStore
for /f "tokens=1-5 delims={}" %%a in ('bcdedit /store "%store%" /create /device') do set deviceguid={%%b}
bcdedit /store "%store%" /set %deviceguid% ramdisksdidevice partition=%sdiDrive% >nul
bcdedit /store "%store%" /set %deviceguid% ramdisksdipath %sdiSourcePath% >nul
echo Created entry for "%sdiDrive%%sdiSourcePath%"
goto %callback%

:createDeviceSysStore
for /f "tokens=1-5 delims={}" %%a in ('bcdedit /create /device') do set deviceguid={%%b}
bcdedit /set %deviceguid% ramdisksdidevice partition=%sdiDrive% >nul
bcdedit /set %deviceguid% ramdisksdipath %sdiSourcePath% >nul
echo Created entry for "%sdiDrive%%sdiSourcePath%"
goto %callback%

:createPEDevice
for /f "tokens=1-5 delims={}" %%a in ('bcdedit /store "%store%" /create /device') do set deviceguid={%%b}
bcdedit /store "%store%" /set %deviceguid% ramdisksdidevice boot >nul
bcdedit /store "%store%" /set %deviceguid% ramdisksdipath \boot\boot.sdi >nul
echo Created entry for "\boot\boot.sdi" Please make sure this file exists!
goto %callback%

goto error

::usage planning
::ramdisk=[boot]\  can be used for live disks iso/usb only otherwise
::ramdisk=[C:]\ must be used specifying where the actual boot image is
::add pe to iso/usb
::add re to live os (main)
::add tool to live os (dart)
::1) modify usb bcd store
::2) modify iso bcd store
::3) modify system bcd store to add tools
::4) modify system bcd store to add 2nd boot entry (recovery env)
:: In every case, know entry will be WinPE boot.wim since winre.wims are handled by reagentc instead
:: will not be used to add operating system entries, but not necessary have an os entry
:: for 1 and 2) will need to copy existing {default} to create a guid, 
:: automatically copies exising .sdi so just update paths -> done
:: for 3 and 4) will have a working RE environment already 
:: check if recovery is enabled
:: {default} recoveryenabled yes, or reagentc /info win re enabled: 1 or enabled
:: if enabled get its uuid
:: copy the uuid with the new description
:: modify the new entry to the new path
:: update bcd store by adding dart to tools and setting {default} legacy mode boot
::bcdedit /toolsdisplayorder %guid% /addfirst
::bcdedit /set {default} bootmenupolicy legacy
::bcdedit /timeout 3
:: and make sure the sdi path does not have a description
::bcdedit /deletevalue %deviceguid% description


:error
echo   An error has occured and %~nx0 cannot continue.
goto end

:usageHelp
echo.
echo   bcdAddPE.bat adds a boot.wim file to an existing bcd store
echo.
echo   /addPE populates the bcd store specified for use with isos/usbs
echo   /addMain populates the main boot menu within the bcd store specified
echo   /addTool populates the tools menu within the bcd store specified 
echo   If a bcd store is not specified when using /addMain or /addTool, the entry 
echo   will populate the live system store (useful to add extra recovery options)
echo.
echo   USB/ISO booting (addPE) Syntax:
echo   bcdAddPE /addPE [boot.wim] [bcdstorepath] {description}
echo   bcdAddPE /addPE \sources\WinPEv3_x64.wim c:\boot\bcd
echo   bcdAddPE /addPE \sources\PEv5x64.wim d:\iso\efi\microsoft\boot\bcd WinPEv5x64
echo   bcdAddPE /addPE \sources\WinPEv5x86.wim c:\iso\boot\bcd "Win PEv5 x86"
echo.
echo   Recovery options (addTool and addMain) Syntax:
echo   bcdAddPE /addMain [path\re.wim] {description} {bcdstorepath}
echo   bcdAddPE /addTool [path\dart.wim] {description} {bcdstorepath}
echo   bcdAddPE /addMain C:\Recovery\windowsre\winre.wim
echo   bcdAddPE /addTool C:\Recovery\oem\dart7_x64.wim
echo   bcdAddPE /addMain C:\Recovery\dart7x64.wim "Diagnostics and Recovery v7x64"
echo   bcdAddPE /addTool C:\dart7x64.wim "Diagnostics and Recovery Tools v7x64"
echo   bcdAddPE /addMain C:\Recovery\winre_x86.wim "Recovery Tools" S:\boot\bcd
echo   bcdAddPE /addTool S:\dart7x64.wim "Recovery Tools" S:\EFI\Microsoft\boot\bcd
echo.
echo   Notes: The /addPE path is relative to the root of the usb/iso
echo   Remember the first \ in the /addPE path
echo   The /addMain /addTool path is the current location of the .wim file
echo   A "Boot device" entry specifying ramdisk settings will be created if needed
echo   Duplicate entries, by description match, will get updated
:end
if exist bcdStoreFull.txt del bcdStoreFull.txt
if exist bcdStoreSummary.txt del bcdStoreSummary.txt
endlocal
