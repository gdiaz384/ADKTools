@echo off
setlocal enabledelayedexpansion
pushd %~dp0


if "%~1" equ "" goto usageHelp
if not exist "%~1" goto usageHelp
set destDrive=%~1

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
echo  Usage: addDrivers uses dism
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

echo Syntax:
echo addDrivers /manual {driverSourcePath} {windowsDrive:}
echo Examples:
echo addDrivers /manual Y:\drivers\win7\x64
echo addDrivers /manual Y:\drivers\win7\x64 C:
echo addDrivers /manual "Y:\drivers\dell\lattitude 6400\win7\x64" C:

echo Syntax:
echo addDrivers /autodetect {driverSourceRoot}
echo Examples:
echo addDrivers /autodetect
echo addDrivers /autodetect Y:
echo addDrivers /autodetect Y:\drivers

echo Syntax:
echo addDrivers /extract {windowsDrive:}
echo Examples:
echo addDrivers /extract Y:

::/manual
::if specified, use specified, (error check) 
::if not specified find windows drive (os drives)
::if could not find a windows installation (in os drives) error out
::add drivers

::/autodetect
::find windows drive (os drives)
::if could not find in (os drives) error out
::extract windows image information (version/architecture)
::load WMI information
::if WMI not available, try non-wmi paths, if not found, then error out
::autodetect where drivers are stored
::autodetectPaths:
::win7\x64
::drivers\win7\x64
::updates\drivers\win7\x64
::workspace\updates\drivers\win7\x64
::error out here if no WMI available
::dell\latitude\win7\x64
::drivers\dell\latitude\win7\x64
::updates\drivers\dell\latitude\win7\x64
::workspace\updates\drivers\dell\latitude e6220\win7\x64
::workspace\drivers\dell\latitude\win7\x64
::if could not be found, then error out
::add drivers

::preferred: use the /manual switch and specify the fully qualified path where the drivers are located and the destination drive
::autodetect will look for drivers at either \Win7\x64  or \Dell\Lattitude\Win7\x64
::valid windows versions: {WinVista^|Win7^|Win8^|Win81^|Win10}
::/extract can be used to pull third party drivers from an existing image (experimental)

::addDrivers /extract Y: 
::find windows drive (os drives)
::if could not find in (os drives) error out
::extract windows image information (version/architecture)
::load wmi information
::if available, dump drivers at Y:\manufacturer\model\Win7\architecture  or Y:\mobomanufacturer\product\Win7\architecture
::if not available, dump drivers at Y:\Win7\architecture
::extract to specified directory

::check for x64.7z before applying drivers, if present and if 7z is present, transfer to the local computer and extract to \drivers before applying

:end
popd
endlocal