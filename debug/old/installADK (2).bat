@echo off
setlocal enabledelayedexpansion

if /i "%~1" equ "/?" goto usagehelp
if /i "%~1" equ "" goto usagehelp
if /i "%~2" equ "" goto usagehelp

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

::set winPERoot=D:\WinPE
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

:mikumode
echo @color 0B > "%mountPoint%\Windows\system32\temp.txt"
type "%mountPoint%\Windows\system32\startnet.cmd" >> "%mountPoint%\Windows\system32\temp.txt"
del "%mountPoint%\Windows\system32\startnet.cmd"
ren "%mountPoint%\Windows\system32\temp.txt" startnet.cmd
if exist "%winPERoot%\winpe_miku.bmp" takeown /f "%mountPoint%\windows\system32\winpe.bmp" >nul 2>nul
if exist "%winPERoot%\winpe_miku.bmp" icacls "%mountPoint%\windows\system32\winpe.bmp" /grant "%username%":(F) >nul 2>nul
if exist "%winPERoot%\winpe_miku.bmp" copy "%winPERoot%\winpe_miku.bmp" "%mountPoint%\windows\system32\winpe.bmp" /y >nul 2>nul
if exist "%winPERoot%\winpe_miku.jpg" takeown /f "%mountPoint%\windows\system32\winpe.jpg" >nul 2>nul
if exist "%winPERoot%\winpe_miku.jpg" icacls "%mountPoint%\windows\system32\winpe.jpg" /grant "%username%":(F) >nul 2>nul
if exist "%winPERoot%\winpe_miku.jpg" copy "%winPERoot%\winpe_miku.jpg" "%mountPoint%\windows\system32\winpe.jpg" /y >nul 2>nul
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

if /i "%architecture%" equ "x86" (
set default_adk5installpath=C:\Program Files\Windows Kits\8.1
set default_adk10installpath=C:\Program Files\Windows Kits\10
) else (
set default_adk5installpath=C:\Program Files ^(x86^)\Windows Kits\8.1
set default_adk10installpath=C:\Program Files ^(x86^)\Windows Kits\10
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
set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %kitsRootRegValueName%') do set ADKInstallPath=%%j
::path includes a trailing backslash \
if not defined ADKInstallPath set ADKInstallPath=%default_adk5installpath%
if /i "%ADKInstallPath:~-1%" equ "\" set ADKInstallPath=%ADKInstallPath:~,-1%

if /i "%architecture%" equ "x86" (set packagesPath=%default_x86packagesPath%) else (
set packagesPath=%default_x64packagesPath%)

if exist "%ADKInstallPath%" if /i "%architecture%" equ "x86" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
if exist "%ADKInstallPath%" if /i "%architecture%" equ "x64" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%

goto doneConfiguringPackageInfo

:detectADK10
set KitsRootRegValueName=KitsRoot10
set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %kitsRootRegValueName%') do set ADKInstallPath=%%j
::path includes a trailing backslash \
if not defined ADKInstallPath set ADKInstallPath=%default_adk10installpath%
if /i "%ADKInstallPath:~-1%" equ "\" set ADKInstallPath=%ADKInstallPath:~,-1%

if /i "%architecture%" equ "x86" (set packagesPath=%default_x86packagesPath%) else (
set packagesPath=%default_x64packagesPath%)

if exist "%ADKInstallPath%" if /i "%architecture%" equ "x86" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
if exist "%ADKInstallPath%" if /i "%architecture%" equ "x64" set path=%ADKInstallPath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%

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

goto end
::dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%basicWMIpackage%"
::dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%htmlPackage%"
::dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%basicScriptingPackage%"
if "%version%" neq "3" dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%secureStartupPackage%"
if "%version%" neq "3" dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%fileMgmtPackage%"
::dism /add-Package /image:"%mountPoint%" /packagePath:"%ADKAndPackagesPath%\%databasePackage%"
