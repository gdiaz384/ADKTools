@echo off
setlocal enabledelayedexpansion

if /i "%~1" equ "/?" goto usagehelp
if /i "%~1" equ "" goto usagehelp
if /i "%~2" equ "" goto usagehelp

set MikuModeEnabled=true
set default_updateType=scripts
::set peToolsPath_x86=D:\updates\tools\x86
::set peToolsPath_x64=D:\updates\tools\x64

::set peDriverRoot=D:\updates\drivers\winPE
::set pe3driverDirectory=3_x
::set pe4driverDirectory=4_x
::set pe5driverDirectory=5_x
::set pe10driverDirectory=10_x
::%peDriverRoot%\!pe%version%driverDirectory!\%architecture%
::D:\updates\drivers\winPE\10_x\x86

::set winPERoot2=D:\WinPE
::set peFileName=boot
::set mountPath=D:\mount
::set peRuntimeScripts=D:\scripts\peRuntime
::set peMgmtScripts=D:\scripts\wimMgmt

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


if /i "%~2" equ "x86" (set architecture=x86
goto prepare)
if /i "%~2" equ "/x86" (set architecture=x86
goto prepare)
if /i "%~2" equ "x64" (set architecture=x64
goto prepare)
if /i "%~2" equ "/x64" (set architecture=x64
goto prepare)
if /i "%~1" equ "other" goto other
goto usageHelp

::update other::
:: verify update type
:: copy mount point
:: copy source dir (if none assume scripts)
:: if scripts update type goto scripts
:: if drivers update goto drivers

::update pe::
:: set version
:: set updateType
:: if mount point specified copy mount point
:: if scripts update type: set script copy dir
:: if source dir specified, copy source dir
:: goto updateScripts
:: if drivers, set driver copy directory, 
:: if source dir specified, copy source dir
:: goto copy drivers

:: copy scrips -> copy scripts -> end 
:: copy drivers -> copy drivers -> end

:prepare
set version=%~1
if /i "%~3" equ "" (set updateType=%default_updateType%) else (set updateType=%~3)
if /i "%updateType%" neq "scripts" if /i "%updateType%" neq "drivers" if /i "%updateType%" neq "packages" (echo error setting updateType to:"%~3"
goto troubleshoot)

::mount Point is special and needs quotes if inside comparison operator ()'s
if /i "%~4" equ "" (set mountPoint=%winPERoot2%\!%architecture%PEmountPath%version%!) else (set mountPoint=%~4)
::set mountPoint="c:\mount"

if /i "%updateType%" equ "scripts" (
if /i "%~5" equ "" (set copySource=%peRuntimeScripts%) else (set copySource=%~5)
goto updateScripts
)
if /i "%updateType%" equ "drivers" (
if /i "%~5" equ "" (set copySource=%peDriverRoot%\!pe%version%driverDirectory!\%architecture%) else (set copySource=%~5)
goto updateDrivers
)
if /i "%updateType%" equ "packages" (
if /i "%~5" equ "" (set winPEPackagesSource=invalid) else (set winPEPackagesSource=%~5)
goto updatePackages
)
echo troubleshoot in "PE" module
goto end


:other
if /i "%~2" equ "" (goto usagehelp) else (set updateType=%~2)
if /i "%~3" equ "" (goto usagehelp) else (set mountPoint=%~3)
if exist %mountPoint%\windows\syswow64 (set architecture=x64) else (set architecture=x86)

if /i "%updateType%" equ "scripts" (
if /i "%~4" equ "" (set copySource=%peRuntimeScripts%) else (set copySource=%~4)
goto updateScripts
)
if /i "%updateType%" equ "drivers" (
if /i "%~4" equ "" (goto usagehelp) else (set copySource=%~4)
goto updateDrivers
)
echo troubleshoot in "other" module
goto troubleshoot


:updateScripts
set toolSource=!peToolsPath_%architecture%!
if exist "%mountPoint%\windows" (
if exist "%mountPoint%\windows\system32\scripts" rmdir "%mountPoint%\windows\system32\scripts" /s /q
robocopy "%copySource%" "%mountPoint%\windows\system32" /e >nul
if exist "%mountPoint%\windows\system32\tools" rmdir "%mountPoint%\windows\system32\tools" /s /q
if exist "%toolSource%" robocopy "%toolSource%" "%mountPoint%\windows\system32\tools" /e >nul
echo Scripts copied to "%mountPoint%"
echo Updated PEv%version% %architecture% successfully.
if /i "%MikuModeEnabled%" equ "true" if /i "%architecture%" equ "x64" goto mikumode
goto end
)
echo.
echo Could not find image at specified directory: %mountPoint%
echo Did not update scripts.
goto troubleshoot


:updateDrivers
dism /image:"%mountPoint%" /add-driver /driver:"%copySource%" /recurse
if %errorlevel% equ 0 (echo All drivers added to %~1 PE or image successfully.
) else (goto troubleshoot)
goto end


:mikumode
echo @color 0B > "%mountPoint%\Windows\system32\temp.txt"
type "%mountPoint%\Windows\system32\startnet.cmd" >> "%mountPoint%\Windows\system32\temp.txt"
del "%mountPoint%\Windows\system32\startnet.cmd"
ren "%mountPoint%\Windows\system32\temp.txt" startnet.cmd
if exist "%winPERoot2%\Updates\winpe_miku.bmp" takeown /f "%mountPoint%\windows\system32\winpe.bmp" >nul 2>nul
if exist "%winPERoot2%\Updates\winpe_miku.bmp" icacls "%mountPoint%\windows\system32\winpe.bmp" /grant "%username%":(F) >nul 2>nul
if exist "%winPERoot2%\Updates\winpe_miku.bmp" copy "%winPERoot2%\Updates\winpe_miku.bmp" "%mountPoint%\windows\system32\winpe.bmp" /y >nul 2>nul
if exist "%winPERoot2%\Updates\winpe_miku.jpg" takeown /f "%mountPoint%\windows\system32\winpe.jpg" >nul 2>nul
if exist "%winPERoot2%\Updates\winpe_miku.jpg" icacls "%mountPoint%\windows\system32\winpe.jpg" /grant "%username%":(F) >nul 2>nul
if exist "%winPERoot2%\Updates\winpe_miku.jpg" copy "%winPERoot2%\Updates\winpe_miku.jpg" "%mountPoint%\windows\system32\winpe.jpg" /y >nul 2>nul
echo Miku mode activated.
goto end


:updatePackages
::to update packages
::1) find version to update
:: use the specified path?
:: check if that adk is installed
:: assume the image is already mounted at %mountPoint%
:: update the packages using dism
:: dism /add-Package /image:"C:\WinPE_amd64\mount" /packagePath:"C:\ADK\WinPE\amd64\WinPE_OCs\en-us\WinPE-HTA.cab"

::set defaults
set default_adk3installpath=C:\Program Files\Windows AIK

if /i "%processor_architecture%" equ "x86" (
set default_adk5installpath=%ProgramFiles%\Windows Kits\8.1
set default_adk10installpath=%ProgramFiles%\Windows Kits\10
) else (
set default_adk5installpath=%programfiles(x86)%\Windows Kits\8.1
set default_adk10installpath=%programfiles(x86)%\Windows Kits\10
)

set default_legacyx86packagesPath=Tools\PETools\x86\WinPE_FPs
set default_legacyx64packagesPath=Tools\PETools\amd64\WinPE_FPs

set default_x86packagesPath=Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs
set default_x64packagesPath=Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs

set basicWMIpackage=WinPE-WMI.cab
set htmlPackage=WinPE-HTA.cab
set basicScriptingPackage=WinPE-Scripting.cab
::secure startup cab not available for PEv3
set secureStartupPackage=WinPE-SecureStartup.cab
::file management cab not available for PEv3
set fileMgmtPackage=WinPE-FMAPI.cab
set databasePackage=WinPE-MDAC.cab

::the version specifies the adk to look for
if /i "%version%" equ "3" goto detectADK3 
if /i "%version%" equ "4" (echo winPE version 4 not currently supported for updating packages
goto end)
if /i "%version%" equ "5" goto detectADK5
if /i "%version%" equ "10" goto detectADK10

:detectADK3
set ADKInstallPath=%default_adk3installpath%

if /i "%architecture%" equ "x86" (set packagesPath=%default_legacyx86packagesPath%) else (
set packagesPath=%default_legacyx64packagesPath%)
goto doneConfiguringPackageInfo

:detectADK5
set KitsRootRegValueName=KitsRoot81
if /i "%processor_architecture%" equ "x86" set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
if /i "%processor_architecture%" equ "amd64" set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %kitsRootRegValueName%') do set ADKInstallPath=%%j
::path includes a trailing backslash \
if not defined ADKInstallPath set ADKInstallPath=%default_adk5installpath%
if /i "%ADKInstallPath:~-1%" equ "\" set ADKInstallPath=%ADKInstallPath:~,-1%

if /i "%architecture%" equ "x86" (set packagesPath=%default_x86packagesPath%) else (
set packagesPath=%default_x64packagesPath%)

if exist "%ADKInstallPath%" if /i "%processor_architecture%" equ "x86" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
if exist "%ADKInstallPath%" if /i "%processor_architecture%" equ "amd64" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%

goto doneConfiguringPackageInfo

:detectADK10
set KitsRootRegValueName=KitsRoot10
if /i "%processor_architecture%" equ "x86" set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
if /i "%processor_architecture%" equ "amd64" set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %kitsRootRegValueName%') do set ADKInstallPath=%%j
::path includes a trailing backslash \
if not defined ADKInstallPath set ADKInstallPath=%default_adk10installpath%
if /i "%ADKInstallPath:~-1%" equ "\" set ADKInstallPath=%ADKInstallPath:~,-1%

if /i "%architecture%" equ "x86" (set packagesPath=%default_x86packagesPath%) else (
set packagesPath=%default_x64packagesPath%)

if exist "%ADKInstallPath%" if /i "%processor_architecture%" equ "x86" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
if exist "%ADKInstallPath%" if /i "%processor_architecture%" equ "amd64" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%

goto doneConfiguringPackageInfo

:doneConfiguringPackageInfo
::echo ADKInstallPath: %ADKInstallPath%
::echo packagesPath: %packagesPath%
::echo mountPoint: %mountPoint%

if not exist "%ADKInstallPath%" echo could not locate ADK for pe version: %version%
if /i "%winPEPackagesSource%" neq "invalid" set ADKAndPackagesPath=%winPEPackagesSource%
if /i "%winPEPackagesSource%" equ "invalid" set ADKAndPackagesPath=%ADKInstallPath%\%packagesPath%

::echo winPEPackagesSource: %winPEPackagesSource%
::echo ADKAndPackagesPath: %ADKAndPackagesPath%

::goto end
dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%basicWMIpackage%"
dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%htmlPackage%"
dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%basicScriptingPackage%"
if "%version%" neq "3" dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%secureStartupPackage%"
if "%version%" neq "3" dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%fileMgmtPackage%"
dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%databasePackage%"

goto end
::start functions::


:troubleshoot
set > .\dump.txt
echo.
echo Debug info:
echo. 
echo      version argument : %1
echo               version : %version%
echo          architecture : %2
echo          architecture : %architecture%
echo         x86mountPoint : %x86mountPoint%
echo         x64mountPoint : %x64mountPoint%
echo            mountPoint : %mountPoint%
echo.
echo    default_UpdateType : %default_updateType%
echo            updateType : %updateType%
echo.
echo             scriptdir : %scriptdir%
echo.
echo    x86driverdirectory : %x86driverdirectory%
echo    x64driverdirectory : %x64driverdirectory%
echo       driverdirectory : %driverdirectory%
echo.
goto end


:usageHelp
echo.
echo   Usage: update.bat updates the PE scripts or drivers for WinPE and drivers 
echo   for a mounted .wim file. For basic usage: use update x86 or x64 and either
echo   drivers or scripts.  [ ] means required,  and { } means optional
echo.
echo   update [pe_ver] [arch] {updateMode} {mountPoint} {updateSource}
echo   update [other] [scripts] [mountPoint] {scriptSource}
echo   update [other] [drivers] [mountPoint] [driverSource]
echo   Examples:
echo   update 5  x86
echo   update 5  x86 scripts
echo   update 10 x64 drivers
echo   update 10 x86 packages
echo   update 10 x86 packages D:\WinPE_x86\mount
echo   update 10 x86 drivers D:\WinPE_x86\mount
echo   update 3  x86 drivers D:\WinPE_x86\mount  D:\drivers\3_x\x86
echo   update 3  x64 scripts D:\WinPE_x64\mount D:\sources\PE_scripts
echo   update other scripts D:\mount 
echo   update other scripts D:\mount  D:\sources\peScripts
echo   update other drivers D:\mount  D:\updates\drivers\x86
echo   update other drivers D:\Win7\mount  D:\drivers\win7_x64
echo.
echo   Note: Using "update x86 3" or "update x64 5 drivers" without more arguments
echo   will ask update.bat to perform the specified action using default values.
echo   If using advanced arguments, all previous arguments must be present:
echo   "update x64 drivers D:\mount" is invalid since it's missing the PE version.
echo   All arguments must be specified for "update other"
goto end


:end
endlocal
