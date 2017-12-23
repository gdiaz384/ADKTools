@echo off
setlocal enabledelayedexpansion
pushd "%systemroot%\system32"

::1) scan for a .wim files
::should compile a list of all .wims in every location. Stick in a file or file(s)

echo.
echo   Searching for Windows installation files (wim/swm/esd) please wait...
echo.

::set all locations to search for .wim images
set wimSearchDir1=\
set wimSearchDir2=\images
set wimSearchDir3=\images\Vista
set wimSearchDir4=\images\win7
set wimSearchDir5=\images\win8
set wimSearchDir6=\images\win81
set wimSearchDir7=\images\win10
set wimSearchDir8=\sources
set wimSearchDir9=\sources\Vista
set wimSearchDir10=\sources\win7
set wimSearchDir11=\sources\win8
set wimSearchDir12=\sources\win81
set wimSearchDir13=\sources\win10
set wimSearchDir14=\winVista
set wimSearchDir15=\win7
set wimSearchDir16=\win8
set wimSearchDir17=\win81
set wimSearchDir18=\win10


::select which drives to search for them in
set networkDrives=X,Z,T,Y
set osDrives=W,T,D,E,C,B,S,R,Z
set removableDrives=X,Z,W,V,U,T,S,R,Q,P,O,N,M,L,K,J,I,H,Y,G,F,C,B,D,E

set foundWimList=foundWimList.txt
set validWimList=validWimList.txt
if exist "%foundWimList%" del "%foundWimList%"
if exist "%validWimList%" del "%validWimList%"

::search the drives\paths and dump and .wim/esd/swm files into foundwimlist
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir1% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir2% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir3% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir4% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir5% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir6% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir7% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir8% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir9% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir10% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir11% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir12% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir13% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir14% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir15% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir16% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir17% %foundWimList%)
for %%i in (%removableDrives%) do (call :searchForWims %%i:%wimSearchDir18% %foundWimList%)

::
::2) parse file to determine valid categories, based upon dism output into version and architecture specific filenames
::

::make sure the files found are valid and put the valid ones into a curated list
for /f "tokens=*" %%a in (%foundWimList%) do (
dism /get-wiminfo /wimfile:"%%a" /index:1 >nul 2>nul
if "!errorlevel!" equ "0" echo %%a>>"%validWimList%"
)
::if "!errorlevel!" neq "0" echo Unable to open:"%%a"
del "%foundWimList%"

::echo Found:
::if exist "%validWimList%" (type "%validWimList%")

::filterPEwims creates a filteredPE.txt
::for /f "tokens=*" %%a in (%validWimList%) do (call :filterPEwim %%a)
::if exist "%validWimList%" del %validWimList%
::ren filteredPE.txt %validWimList%

set winVistaList=winVistaList.txt
set win7List=win7List.txt
set win8List=win8List.txt
set win81List=win81List.txt
set win10List=win10List.txt

if exist "%winVistaList%" del "%winVistaList%"
if exist "%win7List%" del "%win7List%"
if exist "%win8List%" del "%win8List%"
if exist "%win81List%" del "%win81List%"
if exist "%win10List%" del "%win10List%"

::parse the list into windowsVersion, consider only the first index for simplicity
if not exist "%validWimList%" goto end
for /f "tokens=*" %%a in (%validWimList%) do (call :sortWims %%a)
del "%validWimList%"

set winVistaStatus=INVALID
set win7Status=INVALID
set win8Status=INVALID
set win81Status=INVALID
set win10Status=INVALID

if exist "%winVistaList%" (set winVistaStatus=valid)
if exist "%win7List%" (set win7Status=valid)
if exist "%win8List%" (set win8Status=valid)
if exist "%win81List%" (set win81Status=valid)
if exist "%win10List%" (set win10Status=valid)

:: if there isn't a single valid option, then just go to end
if /i "%winVistaStatus%" neq "valid" if /i "%win7Status%" neq "valid" if /i "%win8Status%" neq "valid" if /i "%win81Status%" neq "valid" if /i "%win10Status%" neq "valid" goto end

::3) present crazy UI here
cls
echo.
echo   Hello. %~nx0 will attempt to automatically detect install Windows
echo.
echo   Part A) Select Version
echo   Part B) Select Edition
echo   Part C) Choose Install Options (Normal or Minimal)
echo   Part D) Confirm Install Options
echo.
echo   At any point enter "b" or "back" return to the previous section 
echo   or "main" to return here (part A)
echo.
::select windows verison to install (based upon valid ones detected) (Windows Vista, Windows 7,8/81, Windows 10)
::select architecture/edition to install of available .wim files
:://display Windows version at the top, then architecture/edition/sourcefilename
:mainMenu
echo Part A                       Select Version                             Part A
echo.
echo   Please select one of the following to install:
echo   0: Exit %~nx0
if "%winVistaStatus%" equ "valid" echo   1: Install Windows Vista
if "%win7Status%" equ "valid" echo   2: Install Windows 7
if "%win8Status%" equ "valid" echo   3: Install Windows 8
if "%win81Status%" equ "valid" echo   4: Install Windows 8.1
if "%win10Status%" equ "valid" echo   5: Install Windows 10
::need to know which version to select from
set /p userInput=
if /i "%userInput%" equ "0" goto end
if /i "%userInput%" equ "exit" goto end
if /i "%userInput%" equ "t" goto troubleshoot
if /i "%userInput%" equ "" goto mainMenu
if /i "%userInput%" equ "1" (set chosenWindowsVersion=Vista
goto chooseEdition)
if /i "%userInput%" equ "vista" (set chosenWindowsVersion=Vista
goto chooseEdition)
if /i "%userInput%" equ "2" (set chosenWindowsVersion=7
goto chooseEdition)
if /i "%userInput%" equ "7" (set chosenWindowsVersion=7
goto chooseEdition)
if /i "%userInput%" equ "3" (set chosenWindowsVersion=8
goto chooseEdition)
if /i "%userInput%" equ "8" (set chosenWindowsVersion=8
goto chooseEdition)
if /i "%userInput%" equ "4" (set chosenWindowsVersion=81
goto chooseEdition)
if /i "%userInput%" equ "81" (set chosenWindowsVersion=81
goto chooseEdition)
if /i "%userInput%" equ "8.1" (set chosenWindowsVersion=81
goto chooseEdition)
if /i "%userInput%" equ "5" (set chosenWindowsVersion=10
goto chooseEdition)
if /i "%userInput%" equ "10" (set chosenWindowsVersion=10
goto chooseEdition)
goto mainMenu

::4) list all predefined images, then custom .wim/swm/esd images found (display filename + parsed info)

:chooseEdition
cls
echo.
::sanity check
if "!win%chosenWindowsVersion%status!" neq "valid" (echo Unable to find valid Windows %chosenWindowsVersion% .wim, please select another
goto mainMenu)
::present architecture matching that of winPE first -can't
if not exist "!win%chosenWindowsVersion%List!" (echo Unable to find Windows %chosenWindowsVersion% .wim list, please select another
goto mainMenu)
::type !win%chosenWindowsVersion%List!

:chooseEditionMenu
echo Part B                       Select Edition                              Part B
echo.
echo   Please select one of the following Editions to install:
echo.
::if exist !win%chosenWindowsVersion%List! type !win%chosenWindowsVersion%List!
if not exist !win%chosenWindowsVersion%List! (echo unspecified error 
goto end)

::assign all lines in file to environmental variables: file[0-n]
set wimCount=1
for /f "tokens=1,2 delims=[] " %%i in (!win%chosenWindowsVersion%List!) do (
set wimFile[!wimCount!]=%%i
set wimFile[!wimCount!]TotalIndexes=%%j
set /a wimCount+=1
)

set /a wimCount-=1
::echo  .wimCount in !win%chosenWindowsVersion%List!:%wimCount%
::enumerate all variables: wimFile[0-n]  &  wimFile[0-n]TotalIndexes
::for /L %%i in (1,1,%wimCount%) do echo wimFile%%i:!wimFile[%%i]!  Indexes:!wimFile[%%i]TotalIndexes!

::@echo on
echo   0: Exit %~nx0
echo   B: Go Back
for /L %%i in (1,1,%wimCount%) do (
echo   From: !wimFile[%%i]!
call :displayWimFile !wimFile[%%i]! !wimFile[%%i]TotalIndexes! %%i
echo.
)
::echo Note: core=Home, EnterpriseS = LTSB
::if %wimCount% equ 2 echo Image21: !Image21!
::echo Image25: %Image25%

::echo rawmemorycontents:
::for /l %%i in (11,1,%wimCount%6) do echo. Image%%i: !Image%%i!

set /p userInput=
if /i "%userInput%" equ "0" goto end
if /i "%userInput%" equ "exit" goto end
if /i "%userInput%" equ "t" goto troubleshoot
if /i "%userInput%" equ "b" goto mainMenu
if /i "%userInput%" equ "back" goto mainMenu
if /i "%userInput%" equ "m" goto mainMenu
if /i "%userInput%" equ "main" goto mainMenu
if /i "%userInput%" equ "" goto chooseEdition

::check to make sure user input valid .wim image
for /f "tokens=1,2" %%i in ("!Image%userInput%!") do (set wimImage=%%i
set wimIndex=%%j)
::echo wimImage: %wimImage%
::echo wimIndex: %wimIndex%
dism /get-wiminfo /wimfile:%wimImage% /index:%wimIndex% >nul 2>nul
::if valid, proceed, if not valid, go back to choose edition
if "!errorlevel!" equ "0" (goto next2) else (echo   Unable to open selected edition, please pick another
echo.
goto chooseEditionMenu)
:next2
echo Selected: !Image%userInput%!

::5) lots of menu options

::start auto-detection of variables
::currently have wimImage (fully qualified) and wimIndex

::get more details about the selected image
dism /get-wiminfo /wimfile:"%wimImage%" /index:"%wimIndex%" > tempWimInfo.txt
for /f "tokens=1,2,*" %%a in (tempWimInfo.txt) do if "%%a" equ "Name" set wimName=%%c
for /f "tokens=1,2,*" %%a in (tempWimInfo.txt) do if "%%a" equ "Description" set wimDescription=%%c
for /f "tokens=1-5" %%a in (tempWimInfo.txt) do if "%%a" equ "Architecture" set wimArchitecture=%%c
for /f "tokens=1-5" %%a in (tempWimInfo.txt) do if "%%a" equ "Edition" set wimEdition=%%c
for /f "tokens=1-5" %%a in (tempWimInfo.txt) do if "%%a" equ "Version" set rawWimOSVersion=%%c
for /f "tokens=1,2 delims=." %%i in ("%rawWimOSVersion%") do set rawWimOSVersion=%%i.%%j
del tempWimInfo.txt
if /i "%wimEdition%" equ "<undefined>" set wimEdition=undefined
if /i "%wimDescription%" equ "<undefined>" set wimDescription=undefined
::chosen OS: (legacy=Vista, 7, modern=8, 8.1, 10)
set wimOSVersion=%rawWimOSVersion%
if /i "%rawWimOSVersion%" equ "6.0" (set wimOSVersion=Vista
set wimOSType=legacy)
if /i "%rawWimOSVersion%" equ "6.1" (set wimOSVersion=7
set wimOSType=legacy)
if /i "%rawWimOSVersion%" equ "6.2" (set wimOSVersion=8
set wimOSType=modern)
if /i "%rawWimOSVersion%" equ "6.3" (set wimOSVersion=81
set wimOSType=modern)
if /i "%rawWimOSVersion%" equ "10.0" (set wimOSVersion=10
set wimOSType=modern)
if /i "%wimArchitecture%" neq "x86" if /i "%wimArchitecture%" neq "x64" echo error determining .wim architecture "%wimArchitecture%" is not valid
if /i "%wimOSType%" neq "legacy" if /i "%wimOSType%" neq "modern" echo error determining wimOS version "%wimOSType%"

::get details about PE
::winPEArchitecture: (x86 or x64)
::currentboot edition (2,3,4,5,10)
::currentbootmode (bios, uefi, unk)
call getPEInfo > peInfo.txt
for /f "tokens=1-10" %%a in (peInfo.txt) do (set winPEVersion=%%e
set winPEArchitecture=%%f
set winPEBootMode=%%g)
for /f "delims=." %%i in ("%winPEVersion%") do set winPEVersion=%%i
if /i "%winPEVersion%" equ "2" (set winPEOSVersion=Vista
set peOSType=legacy)
if /i "%winPEVersion%" equ "3" (set winPEOSVersion=7
set peOSType=legacy)
if /i "%winPEVersion%" equ "4" (set winPEOSVersion=8
set peOSType=modern)
if /i "%winPEVersion%" equ "5" (set winPEOSVersion=81
set peOSType=modern)
if /i "%winPEVersion%" equ "10" (set winPEOSVersion=10
set peOSType=modern)
if /i "%winPEArchitecture%" equ "AMD64" set winPEArchitecture=x64
if /i "%winPEArchitecture%" neq "x86" if /i "%winPEArchitecture%" neq "x64" echo error "%winPEArchitecture%" is not a valid architecture
if /i "%peOSType%" neq "legacy" if /i "%peOSType%" neq "modern" echo error determining winPE version "%peOSType%"

::okay so user has selected a .wim and index to install and all info has been parsed
::time to set the defaults for stuffs like partitiontableformat

::partition structure (mbr or gpt, based upon uefi/bios)
set partitionTableFormat=MBR
if /i "%winPEBootMode%" equ "UEFI" set partitionTableFormat=GPT

::normal/reccomended partition structure or minimalistic
::normal/minimal
set partitionLayout=normal

::default selected disk
set diskNumber=0

::TODO: win10 /compact option (need to add support in image script)
set compactOS=false

::run registerRE or not
set setupRETools=true

::or could make it so that switching partitionLayout changes where the RE tools are installed (onto B:)
set recoveryToolsDestinationDrive=R

::oobe automated or not
set setupUnattend=true

::expose all options with a 3rd menu or not
set advancedMode=false

:setInstallMode
::Present warnings about selected version of windows (incl edition and architecture) and current bootmode
cls
echo.
echo Part C                    Choose Install Options                         Part C
echo.
::especially about bios/uefi compatability if a mis-match exists between selected and current winPE boot image
::-current pe version is a legacy version, cannot detect boot mode reliably
::echo   minor warning goes here
echo   Windows %wimOSVersion% %wimArchitecture% %wimEdition% "%wimName%"
::-User desired OS type does not match the selected index OS version
::-current boot mode is 32bit UEFI, only 32-bit UEFI comptable images are supported using simple/minimalistic
::--32-bit uefi supports 32-bit images only and win 8 or above
::--32-bit uefi does not support Win Vista, or Win 7
::-current boot mode is 64bit UEFI, only 64-bit UEFI comptable images are supported using simple/minimalistic
::--64-bit uefi supports 64-bit images only and Win 7 Pro or above
::--64-bit uefi does not support any 32-bit image, win Vista (?), or win 7-basic/homepremium


::present menu to user  (-detail every option in corner)
echo   0: Exit %~nx0
echo   B: Go Back
echo.
echo   Enter "1" for a Normal install
echo                  (recommended and includes recovery options)
echo.
echo   Enter "2" for a Minimal install
echo                  (recommended for small ssds and enterprises)
echo.
echo   Enter "3" to change the partition table format/recovery/oobe options
echo                  (recommended for advanced users)
echo.
::[selected disk information is displayed, including partitions of selected disk and volumes]
if exist .\scripts\diskpart\listDiskMinimal.bat diskpart /s .\scripts\diskpart\listDiskMinimal.bat > diskOutput.txt
if exist diskOutput.txt (for /f "tokens=* skip=4" %%i in (diskOutput.txt) do echo   %%i >> diskOutput2.txt
del diskOutput.txt)
if exist diskOutput2.txt (type diskOutput2.txt 
del diskOutput2.txt)
echo.
echo   Disk number "%diskNumber%" is currently selected. Enter "3" to select a different disk
set /p userInput=
if /i "%userInput%" equ "0" goto end
if /i "%userInput%" equ "exit" goto end
if /i "%userInput%" equ "t" goto troubleshoot
if /i "%userInput%" equ "b" goto chooseEdition
if /i "%userInput%" equ "back" goto chooseEdition
if /i "%userInput%" equ "m" goto mainMenu
if /i "%userInput%" equ "main" goto mainMenu
if /i "%userInput%" equ "" goto setInstallMode
if /i "%userInput%" equ "1" (goto normalInstall)
if /i "%userInput%" equ "a" (goto normalInstall)
if /i "%userInput%" equ "sim" (goto normalInstall)
if /i "%userInput%" equ "simple" (goto normalInstall)
if /i "%userInput%" equ "2" (goto minimalInstall)
if /i "%userInput%" equ "b" (goto minimalInstall)
if /i "%userInput%" equ "min" (goto minimalInstall)
if /i "%userInput%" equ "minimal" (goto minimalInstall)
if /i "%userInput%" equ "3" (goto advancedInstall)
if /i "%userInput%" equ "c" (goto advancedInstall)
if /i "%userInput%" equ "adv" (goto advancedInstall)
if /i "%userInput%" equ "advanced" (goto advancedInstall)
goto setInstallMode

:normalInstall
::if boot mode bios, format mbr
::if boot mode uefi, format gpt partitionTableFormat
set partitionTableFormat=MBR
if /i "%winPEBootMode%" equ "UEFI" set partitionTableFormat=GPT
::set partition format mode to normal
set partitionLayout=normal
::set retools to enabled
set setupRETools=true
::set oobe to true
set setupUnattend=true
::leave disknumber as-is
goto finalMenu

:minimalInstall
::if boot mode bios, format mbr
::if boot mode uefi, format gpt partitionTableFormat
set partitionTableFormat=MBR
if /i "%winPEBootMode%" equ "UEFI" set partitionTableFormat=GPT
::set partition format mode to minimal for image.bat
set partitionLayout=minimal
::disable retools
set setupRETools=false
::set oobe to true
set setupUnattend=true
::leave disknumber as-is
goto finalMenu

:advancedInstall
::expose everything! (toggle mode)
set advancedMode=true
cls
echo.
echo   Just because you can doesn't mean it's a good idea...
:advancedInstallMenu
echo.
echo   Select an option to toggle settings, Enter "c" or "continue" when done
echo.
::disknumber (diskNumber)
echo   1: disknumber: %disknumber%
::mbr or gpt (partitionTableFormat)
echo   2: Partition Table Format: %partitionTableFormat%
::normal format or minimalistic (if switching to minimalistic, also disable retools) (partitionLayout)
echo   3: partitionLayout (normal or minimal): %partitionLayout%
::move this somewhere else maybe?
call :displayCurrentDiskLayout
::install retools (if switching retools to enabled, switch format mode to simple) (setupRETools)
echo   4: setupRETools: %setupRETools%
::or could make it so that switching partitionLayout changes where the RE tools are installed (onto B:)
echo   5: Recovery Tools Installation Drive: %recoveryToolsDestinationDrive%
::oobe (setupUnattend)
echo   6: Automate OOBE: %setupUnattend%
::windows8/10Only compact (compactOS)
echo   7: Install as a compactOS: %compactOS%
set /p userInput=
if /i "%userInput%" equ "0" goto end
if /i "%userInput%" equ "exit" goto end
if /i "%userInput%" equ "t" goto troubleshoot
if /i "%userInput%" equ "b" goto setInstallMode
if /i "%userInput%" equ "back" goto setInstallMode
if /i "%userInput%" equ "m" goto mainMenu
if /i "%userInput%" equ "main" goto mainMenu
if /i "%userInput%" equ "" goto advancedInstallMenu
if /i "%userInput%" equ "c" goto finalMenu
if /i "%userInput%" equ "continue" goto finalMenu

if /i "%userInput%" equ "1" (
cls
if exist .\scripts\diskpart\listdisk.bat diskpart /s .\scripts\diskpart\listdisk.bat
echo.
echo   Enter new disk number from list above:
echo.
set /p diskNumber=
goto advancedInstallMenu
)
if /i "%userInput%" equ "2" (if /i "%partitionTableFormat%" equ "MBR" (set partitionTableFormat=GPT) else (set partitionTableFormat=MBR)
goto advancedInstallMenu)
if /i "%userInput%" equ "3" (if /i "%partitionLayout%" equ "normal" (set partitionLayout=minimal) else (set partitionLayout=normal)
if /i "%partitionLayout%" equ "minimal" set recoveryToolsDestinationDrive=B
if /i "%partitionLayout%" equ "normal" set recoveryToolsDestinationDrive=R
goto advancedInstallMenu)
if /i "%userInput%" equ "4" (if /i "%setupRETools%" equ "true" (set setupRETools=false) else (set setupRETools=true)
goto advancedInstallMenu)
if /i "%userInput%" equ "5" (
echo.
echo   This will have no effect if setupRETools is false. setupRETools is currently: "%setupRETools%"
echo   Enter "R" to copy Recovery Tools to the dedicated RE partition
echo   Enter "B" to copy Recovery Tools to the OS partition
echo.
set /p recoveryToolsDestinationDrive=
if /i "%recoveryToolsDestinationDrive%" equ "R" set partitionLayout=normal
goto advancedInstallMenu
)
if /i "%userInput%" equ "6" (if /i "%setupUnattend%" equ "true" (set setupUnattend=false) else (set setupUnattend=true)
goto advancedInstallMenu)
if /i "%userInput%" equ "7" (if /i "%compactOS%" equ "true" (set compactOS=false) else (set compactOS=true)
goto advancedInstallMenu)
goto advancedInstallMenu


:finalMenu
if /i "%advancedMode%" equ "false" goto deploy
echo.
echo Part D                    Confirm Install Options                        Part D
echo.
::check to make sure nothing required is null and certain options don't conflict (like partitionLayout and setupRETools(?))
echo   %~nx0 will install Windows %wimOSVersion% %wimArchitecture% %wimEdition%
echo   Name: "%wimName%"  Description: "%wimDescription%"
echo   source file: %wimImage%  index:%wimindex%
echo.
echo   On Disk: "%diskNumber%" using partition table format: "%partitionTableFormat%"
echo   partitionLayout: "%partitionLayout%"
call :displayCurrentDiskLayout
echo   RecoveryTools enabled: "%setupRETools%" on Drive "%recoveryToolsDestinationDrive%"
echo   Automate OOBE: "%setupUnattend%"
echo   Install as compactOS: "%compactOS%"
echo.
echo   Current winPE %winPEVersion% boot information:
echo   winPEArchitecture: %winPEArchitecture%    winPEBootMode: %winPEBootMode%
echo.
echo   Enter "1" or "c" to continue
echo   Enter "0" or "exit" to exit %~nx0 to a command prompt
echo   Enter "b" or "back" to change the Install Mode (Part C)
echo   Enter "main" to return to the Main Menu (Part A)
set /p userInput=
if /i "%userInput%" equ "0" goto end
if /i "%userInput%" equ "exit" goto end
if /i "%userInput%" equ "t" goto troubleshoot
if /i "%userInput%" equ "b" goto setInstallMode
if /i "%userInput%" equ "back" goto setInstallMode
if /i "%userInput%" equ "m" goto mainMenu
if /i "%userInput%" equ "main" goto mainMenu
if /i "%userInput%" equ "1" goto deploy
if /i "%userInput%" equ "c" goto deploy
if /i "%userInput%" equ "" goto finalMenu
goto :finalMenu

:deploy
if /i "%partitionLayout%" equ "minimal" goto minimalDeploy
if /i "%1" equ "skip" goto reToolsOptions
::echo   image /deploy  Y:\install.swm  1 /noprompt 1 GPT
call image /deploy "%wimImage%" "%wimIndex%" /noprompt %diskNumber% %partitionTableFormat%
goto reToolsOptions

:minimalDeploy
if /i "%1" equ "skip" goto reToolsOptions
::echo   image /deploy  Y:\install.swm  1 /minimal 1 GPT
call image /deploy "%wimImage%" "%wimIndex%" /minimal %diskNumber% %partitionTableFormat%


::8) check if registerRE was set, if so run registerRE

:reToolsOptions
if /i "%setupRETools%" neq "true" goto unattendOptions
if not exist B:\Windows goto unattendOptions
if not exist S: goto unattendOptions
if not exist %recoveryToolsDestinationDrive%: goto unattendOptions

set bcdpath=nul
if /i "%partitionTableFormat%" equ "mbr" set bcdpath=S:\boot\bcd
if /i "%partitionTableFormat%" equ "gpt" set bcdpath=S:\EFI\Microsoft\boot\bcd
if /i "%bcdpath%" equ "nul" goto unattendOptions
if not exist "%bcdpath%" goto unattendOptions

if /i "%wimOSVersion%" equ "Vista" set peVersion=2
if /i "%wimOSVersion%" equ "7" set peVersion=3
::so...don't actually have a version 4 of winPE, cuz like why... so just give win8 winPE v5
if /i "%wimOSVersion%" equ "8" set peVersion=5
if /i "%wimOSVersion%" equ "81" set peVersion=5
if /i "%wimOSVersion%" equ "10" set peVersion=10


echo.
echo    Will now attempt to set up Windows Recovery Environment
echo.
::echo  registerRE %recoveryToolsDestinationDrive%: 5 x64 C:\boot\bcd E:\sources\win8\winPETools
:setupRE
call registerRE %recoveryToolsDestinationDrive%: %peVersion% %wimArchitecture% "%bcdpath%"


:unattendOptions
::7) check if unattend was set, if so run autounattend
if /i "%setupUnattend%" neq "true" goto postDeploy
if exist w:\windows set wimWinDir=w:\windows
if exist D:\Windows  set wimWinDir=D:\windows
if exist C:\Windows  set wimWinDir=C:\windows
if exist B:\Windows  set wimWinDir=B:\windows
if not exist "%wimWinDir%" goto postDeploy

echo.
echo    Will now attempt to copy unattend.xml to automate oobe
echo.
set unattendStatus=invalid
set unattendSysprepFullPath=%wimWinDir%\system32\sysprep\unattend.xml
::set unattendPantherFullPath=%wimWinDir%\Panther\unattend.xml

if exist ".\scripts\unattendxml\win%wimOSVersion%\unattend_Win%wimOSVersion%_%wimEdition%_%wimArchitecture%_RTM.xml" (
set unattendOobeFile=.\scripts\unattendxml\win%wimOSVersion%\unattend_Win%wimOSVersion%_%wimEdition%_%wimArchitecture%_RTM.xml
set unattendStatus=valid)
::make sure not to copy over any existing unattend.xml file from advanced images
if /i "%unattendStatus%" equ "valid" (
if not exist "%unattendSysprepFullPath%" copy "%unattendOobefile%" "%unattendSysprepFullPath%" & echo   copying:"%unattendOobefile%" & echo   to:"%unattendSysprepFullPath%"
)
if /i "%unattendStatus%" neq "valid" (echo  Could not find win%wimOSVersion%\unattend_Win%wimOSVersion%_%wimEdition%_%wimArchitecture%_RTM.xml)
goto postDeploy


::::start Function List::::
:displayCurrentDiskLayout
if /i "%partitionTableFormat%" equ "MBR" if /i "%partitionLayout%" equ "normal" echo   Current Partition Layout for Disk %diskNumber%: [RE][Windows]
if /i "%partitionTableFormat%" equ "MBR" if /i "%partitionLayout%" equ "minimal"  echo   Current Partition Layout for Disk %diskNumber%: [Windows]
if /i "%partitionTableFormat%" equ "GPT" if /i "%partitionLayout%" equ "normal" echo   Current Partition Layout for Disk %diskNumber%: [EFI][MSR][RE][Windows]
if /i "%partitionTableFormat%" equ "GPT" if /i "%partitionLayout%" equ "minimal"  echo   Current Partition Layout for Disk %diskNumber%: [EFI][MSR][Windows]
goto :eof


::search the drives\paths and dump and .wim/esd/swm files into foundwimlist
::%1 is the path to search in, and %2 is the file to dump the contents in
:searchForWims
if /i "%1" equ "" goto :eof
if not exist "%1" goto :eof
if /i "%2" equ "" goto :eof

set searchpath=%1
if /i "%searchpath:~-1%" equ "\" set searchpath=%searchpath:~,-1%
::echo searching: "%searchpath%"
set masterlist=%2

set templist=tempFileList.txt
if exist "%templist%" del "%templist%"

dir /a:-d /b "%searchpath%\*.wim">> "%templist%" 2>nul
dir /a:-d /b "%searchpath%\*.swm">> "%templist%" 2>nul
dir /a:-d /b "%searchpath%\*.esd">> "%templist%" 2>nul

if exist "%templist%" (for /f "tokens=*" %%a in (%templist%) do (echo %searchpath%\%%a>>"%masterlist%"))
del "%templist%"
goto :eof


::UsageNotes: sortWims parses .wim files given to it into win8List.txt files
::Syntax: sortWims {qualifiedWimPath}
::sortWims B:\images\win81\Win81_Update_x86.wim
:sortWims
if /i "%~1" equ "" goto :eof
if not exist "%~1" goto :eof
set fullWimFilePath=%~1

dism /get-wiminfo /wimfile:"%fullWimFilePath%" /index:1 > tempWimInfo.txt
for /f "tokens=1-5" %%a in (tempWimInfo.txt) do if "%%a" equ "Version" set rawWimVersion=%%c
del tempWimInfo.txt
if /i "%rawWimVersion%" equ "<undefined>" goto :eof
for /f "tokens=1,2 delims=." %%i in ("%rawWimVersion%") do set rawWimVersion=%%i.%%j

set wimVersion=%rawWimVersion%
if /i "%rawWimVersion%" equ "6.0" set wimVersion=Vista
if /i "%rawWimVersion%" equ "6.1" set wimVersion=7
if /i "%rawWimVersion%" equ "6.2" set wimVersion=8
if /i "%rawWimVersion%" equ "6.3" set wimVersion=81
if /i "%rawWimVersion%" equ "10.0" set wimVersion=10
if /i "%wimVersion%" equ "%rawWimVersion%" (echo error sorting:"%fullWimFilePath%"
goto :eof)

dism /get-wiminfo /wimfile:"%fullWimFilePath%" | find /c /i "index" > wimfileindexCount.txt
set /p wimfileindexCount=<wimfileindexCount.txt
del wimfileindexCount.txt
echo [%fullWimFilePath%] [%wimfileindexCount%]>>win%wimVersion%List.txt
goto :eof


::filterPEwims creates a filteredPE.txt
::for /f "tokens=*" %%a in (%validWimList%) do (call :filterPEwim %%a)
:filterPEwims
goto :eof


::%1 is d:\wimfile.wim    %2 is the total number of index in the .wim file    %3 is the curent .wim file number
:displayWimFile
::enumerate each index into wimfiles[0-%2]
for /l %%i in (1,1,%2) do (call dism /get-wiminfo /wimfile:"%1" /index:"%%i" > tempWimInfo%%i.txt)
set indexCounter=1
:startIndexLoop
for /f "tokens=1,2,*" %%a in (tempWimInfo%indexCounter%.txt) do if "%%a" equ "Name" set wimName=%%c
for /f "tokens=1-5" %%a in (tempWimInfo%indexCounter%.txt) do if "%%a" equ "Architecture" set wimArchitecture=%%c
for /f "tokens=1-5" %%a in (tempWimInfo%indexCounter%.txt) do if "%%a" equ "Edition" set wimEdition=%%c
for /f "tokens=1-5" %%a in (tempWimInfo%indexCounter%.txt) do if "%%a" equ "Version" set rawWimVersion=%%c
if /i "%wimEdition%" equ "<undefined>" set wimEdition=undefined
for /f "tokens=1,2 delims=." %%i in ("%rawWimVersion%") do set rawWimVersion=%%i.%%j
del tempWimInfo%indexCounter%.txt
set wimVersion=%rawWimVersion%
if /i "%rawWimVersion%" equ "6.0" set wimVersion=Vista
if /i "%rawWimVersion%" equ "6.1" set wimVersion=7
if /i "%rawWimVersion%" equ "6.2" set wimVersion=8
if /i "%rawWimVersion%" equ "6.3" set wimVersion=81
if /i "%rawWimVersion%" equ "10.0" set wimVersion=10

echo    Enter "%~3%indexCounter%" for Windows %wimVersion% %wimArchitecture% %wimEdition% "%wimName%"
set Image%3%indexCounter%=%1 %indexCounter%
::echo Image%3%indexCounter%=!Image%3%indexCounter%!

if %indexCounter% geq %2 (goto continue) else (set /a indexCounter+=1
goto startIndexLoop)
:continue
for /l %%i in (1,1,%2) do (if exist tempWimInfo%%i.txt del tempWimInfo%%i.txt)
goto :eof


:booleanprompt
echo Are you sure (yes/no)?
set /p userInput=
if /i "%userInput%" equ "y" goto %callback%
if /i "%userInput%" equ "ye" goto %callback%
if /i "%userInput%" equ "yes" goto %callback%
if /i "%userInput%" equ "n" goto end
if /i "%userInput%" equ "no" goto end
goto booleanprompt
::::end Function List::::


::9) check reboot?
:postDeploy
echo     The system will now reboot.
set callback=reboot
goto booleanprompt
:reboot
exit

:troubleshoot
set > x:\dump.txt
echo   A fatal error has occured and %~nx0 must not continue. 
echo   Full set local variable information is available at:  x:\dump.txt
goto end

:end
if exist "%winVistaList%" del "%winVistaList%"
if exist "%win7List%" del "%win7List%"
if exist "%win8List%" del "%win8List%"
if exist "%win81List%" del "%win81List%"
if exist "%win10List%" del "%win10List%"
popd
echo      Enter:
echo      "%~nx0"  -to try to automatically detect and install Windows
echo      "image"  -to manually install a specific .wim file
echo      "help"  -for help with the syntax in performing other common operations
echo.
endlocal