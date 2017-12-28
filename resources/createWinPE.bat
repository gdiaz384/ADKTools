@echo off
setlocal enabledelayedexpansion

::check if adks are installed
::prompt to install an ADK if one is not already installed
::unzip basic workspace -(create workspace) with pe versions, bootfiles and updates folder (scripts\tools\drivers)c
::run environment setting script (from adk) (set local?)
::copype amd64 pe_x64\iso (must be empty)
::delete extra muis (annoying)
::copy originalpe found under media\sources\boot.wim to pe_x64\originalwim\winpe31.wim
::unarchive boot files to workspace\ root

::ask? to update winpe 5->5.1, then copy 5.1 over sources\boot.wim

::fill tools directory with latest tools available (should already have gimagex/chm/7za/aria2c)
::copy PEscripts to peworkpace\updates\pescripts
::download dell drivers (hp?) -need to test driver dl reliability (hash check) dell3=http:url  dell3crc32hash=crc32hash
::extract drivers appropriately
::update environment.bat
::insert environment.bat in the adks
::run environment setting script (from adk)

::mount boot.wim and update (same as reset scenario) -wait, how does the reset scenario work again?
::mount pe version with it's dism version (use setenv.bat) 
::update drivers
::update packages
::update scripts
::update tools
::delete boot.wim
::save to boot.wim and unmount discard
::call createiso (aik 7 might be tricky), should work
::copy iso

::move on to next adk

if not defined integratePackages goto end
if not defined integrateDrivers goto end
if not defined integrateScripts goto end

set resourcePath=resources
set toolsPath=%resourcePath%\tools
set archivePath=%resourcePath%\archives
set scriptPath=%resourcePath%\scripts
set sevenZ=7z.exe
set aria=aria2c.exe
set WinPEDriversURLtxt=urls.txt

set winPEWorkspaceArchive=winPEWorkspace.7z
set winPEBootFilesArchive=winPEBootFiles.7z
set workspaceDest=%cd%
if /i "%workspaceDest:~-1%" equ "\" set workspaceDest=%workspaceDest:~,-1%
set setEnvironmentScript=setEnvironment.bat
set setEnvironmentTemplate=setEnvironment.template

::AIK stores tools as x86\bcdboot.exe  and  amd64\servicing\dism.exe
::Tools\PETools\amd64\Boot\efisys_noprompt.efi
set AIK7legacyWinPEPath=Tools\PETools
set AIK7legacyToolsPath=Tools
set AIK7legacysetEnvScript=pesetenv.cmd

::ADK stores tools as x86\oscdimg\efisys_noprompt.bin  and amd64\dism\dism.exe
set ADKWinPEPath=Assessment and Deployment Kit\Windows Preinstallation Environment
set ADKDeploymentToolsPath=Assessment and Deployment Kit\Deployment Tools
set ADKsetEnvScript=DandISetEnv.bat

if /i "%processor_architecture%" equ "x86" set architecture=x86
if /i "%processor_architecture%" equ "AMD64" set architecture=x64
if not defined architecture (echo    Error: unsupported architecture
goto end)


call :detectAIK7
call :detectADK81UandADK10
if /i "%AIK7Installed%" equ "true" if /i "%ADK81Uinstalled%" equ "true" if /i "%ADK10installed%" equ "true" set allADKsInstalled=true
if /i "%ADK10installed%" neq "true" (echo.
echo  Error: ADK 10 no installed. ADK10 must be installed to generate .wim files. 
echo  Please install it and run setup again.
goto end)
cls


::extract workspace
"%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%winPEWorkspaceArchive%" -o"%workspaceDest%" -y -aoa
if not exist "%workspaceDest%\winPEWorkspace" (echo   error extracting workspace
goto end)


::unarchive boot files to workspace\ root
::if not exist "%workspaceDest%\winPEWorkspace\winPEBootFiles" "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%winPEBootFilesArchive%" -o"%workspaceDest%\winPEWorkspace" -y -aoa
call :extractBootFilesToWorkspace


:populateWorkspaces
call :addWinPE31ToWorkspace
call :addWinPE50ToWorkspace
call :addWinPE10ToWorkspace


::update winpe 5->5.1, then copy 5.1 over sources\boot.wim
::ask maybe? this takes a very long time
setlocal
if /i "%ADK81UInstalled%" equ "true" call "%scriptPath%\updateWinPE50.bat"
endlocal


::fill tools directory with latest tools available (should already have gimagex/chm/7za/aria2c)
::%workspaceDest%\winPEWorkspace\Updates\tools
::if dism is already there, then assume tools do not need to be copied
::@echo on
::set ADK10Installed=false
::set ADK81UInstalled=false

if exist "%workspaceDest%\winPEWorkspace\Updates\tools\x86\dism\dism.exe" goto afterToolsCopy

::if ADK10Installed, copy from adk10 (bcdboot/dism), then goto afterToolsCopy
if /i "%ADK10Installed%" neq "true" goto afterADK10ToolsCopy
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\dism" "%workspaceDest%\winPEWorkspace\Updates\tools\x86\dism" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\dism" "%workspaceDest%\winPEWorkspace\Updates\tools\x64\dism" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\bcdboot" "%workspaceDest%\winPEWorkspace\Updates\tools\x86\bcdboot" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\bcdboot" "%workspaceDest%\winPEWorkspace\Updates\tools\x64\bcdboot" /e >nul

robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\dism" "%toolsPath%\x86\dism" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\dism" "%toolsPath%\x64\dism" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\bcdboot" "%toolsPath%\x86\bcdboot" /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\bcdboot" "%toolsPath%\x64\bcdboot" /e >nul
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\oscdimg\oscdimg.exe" "%toolsPath%\x86\oscdimg\oscdimg.exe" >nul
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\oscdimg\oscdimg.exe" "%toolsPath%\x64\oscdimg\oscdimg.exe" >nul
goto afterToolsCopy
:afterADK10ToolsCopy

:: if not skipped yet, and if ADK81Uinstalled, copy from adk81U, then goto afterToolsCopy
if /i "%ADK81UInstalled%" neq "true" goto afterToolsCopy
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\dism" "%workspaceDest%\winPEWorkspace\Updates\tools\x86\dism" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\dism" "%workspaceDest%\winPEWorkspace\Updates\tools\x64\dism" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\bcdboot" "%workspaceDest%\winPEWorkspace\Updates\tools\x86\bcdboot" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\bcdboot" "%workspaceDest%\winPEWorkspace\Updates\tools\x64\bcdboot" /e >nul

robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\dism" "%toolsPath%\x86\dism" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\dism" "%toolsPath%\x64\dism" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\bcdboot" "%toolsPath%\x86\bcdboot" /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\bcdboot" "%toolsPath%\x64\bcdboot" /e >nul
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\oscdimg\oscdimg.exe" "%toolsPath%\x86\oscdimg\oscdimg.exe" >nul
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\oscdimg\oscdimg.exe" "%toolsPath%\x64\oscdimg\oscdimg.exe" >nul
:afterToolsCopy


::copy PEscripts to peworkpace\updates\pescripts
if /i "%integrateScripts%" equ "true" robocopy "%scriptPath%\peRuntime"  "%workspaceDest%\winPEWorkspace\Updates\peRuntime" /e >nul

if /i "%integrateDrivers%" neq "true" goto afterExtractingDrivers
::download dell and hp drivers, dell3=http://url  dell3crc32hash=crc32hash
::download drivers to winPEWorkspace\Updates\drivers\3_x
::read URLs from file
::try downloading using both URLs
::need to test driver dl reliability (hash check)
::blind-retry once using second URL2 if download hash fails, warn user if second attempt fails

::extract into specified folders
::-extract with to name with _ at the end of filename (is new foldername)
::-move contents of drivers_\winpe\x86 and drivers_\winpe\x64 directories into winPEWorkspace\Updates\drivers\3_x\x86\dell
::-delete original extracted folder, leave .cab file in place
set winPEDriverDLs=
call :readPEDrivers
if defined winPEDriverDLs goto afterExtractingDrivers

set pe2downloadPath=%workspaceDest%\winPEWorkspace\Updates\drivers\2_x
set pe3downloadPath=%workspaceDest%\winPEWorkspace\Updates\drivers\3_x
set pe4downloadPath=%workspaceDest%\winPEWorkspace\Updates\drivers\4_x
set pe5downloadPath=%workspaceDest%\winPEWorkspace\Updates\drivers\5_x
set pe10downloadPath=%workspaceDest%\winPEWorkspace\Updates\drivers\10_x

::need...filename, url downloadPath, crc
::download
if not exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE3_Dell_%WinPE3_Dell_latest%_URL!" --dir="%pe3downloadPath%"
if not exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE5_Dell_%WinPE5_Dell_latest%_URL!" --dir="%pe5downloadPath%"
if not exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE10_Dell_%WinPE10_Dell_latest%_URL!" --dir="%pe10downloadPath%"

if not exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE3_HP_%WinPE3_HP_latest%_URL!" --dir="%pe3downloadPath%"
if not exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE5_HP_%WinPE5_HP_latest%_URL!" --dir="%pe5downloadPath%"
if not exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE10_HP_%WinPE10_HP_latest%_URL!" --dir="%pe10downloadPath%"

::crcCheck
if exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" call :hashCheck "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" "!WinPE3_Dell_%WinPE3_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!"
if exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" call :hashCheck "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" "!WinPE5_Dell_%WinPE5_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!"
if exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" call :hashCheck "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" "!WinPE10_Dell_%WinPE10_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!"

if exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" call :hashCheck "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" "!WinPE3_HP_%WinPE3_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!"
if exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" call :hashCheck "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" "!WinPE5_HP_%WinPE5_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!"
if exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" call :hashCheck "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" "!WinPE10_HP_%WinPE10_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!"

::download again
if not exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE3_Dell_%WinPE3_Dell_latest%_URL2!" --dir="%pe3downloadPath%"
if not exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE5_Dell_%WinPE5_Dell_latest%_URL2!" --dir="%pe5downloadPath%"
if not exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE10_Dell_%WinPE10_Dell_latest%_URL2!" --dir="%pe10downloadPath%"

if not exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE3_HP_%WinPE3_HP_latest%_URL2!" --dir="%pe3downloadPath%"
if not exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE5_HP_%WinPE5_HP_latest%_URL2!" --dir="%pe5downloadPath%"
if not exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" "%toolsPath%\%architecture%\aria2\%aria%" "!WinPE10_HP_%WinPE10_HP_latest%_URL2!" --dir="%pe10downloadPath%"

::hash check again
if exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" call :hashCheck "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" "!WinPE3_Dell_%WinPE3_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!"
if exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" call :hashCheck "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" "!WinPE5_Dell_%WinPE5_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!"
if exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" call :hashCheck "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" "!WinPE10_Dell_%WinPE10_Dell_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!"

if exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" call :hashCheck "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" "!WinPE3_HP_%WinPE3_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!"
if exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" call :hashCheck "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" "!WinPE5_HP_%WinPE5_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!"
if exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" call :hashCheck "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" "!WinPE10_HP_%WinPE10_HP_latest%_crc32!" crc32
if /i "%hash%" neq "valid" del "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!"

::report errors
if not exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" (echo   unable to download Dell WinPE3 drivers, please dl manually
echo  !WinPE3_Dell_%WinPE3_Dell_latest%_URL2!)
if not exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" (echo   unable to download Dell WinPE5 drivers, please dl manually
echo  !WinPE5_Dell_%WinPE5_Dell_latest%_URL2!)
if not exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" (echo   unable to download Dell WinPE10 drivers, please dl manually
echo  !WinPE10_Dell_%WinPE10_Dell_latest%_URL2!)

if not exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" (echo   unable to download HP WinPE3 drivers, please dl manually
echo  !WinPE3_HP_%WinPE3_HP_latest%_URL2!)
if not exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" (echo   unable to download HP WinPE5 drivers, please dl manually
echo  !WinPE5_HP_%WinPE5_HP_latest%_URL2!)
if not exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" (echo   unable to download HP WinPE10 drivers, please dl manually
echo  !WinPE10_HP_%WinPE10_HP_latest%_URL2!)

::extract into specified folders
:: call extractDriverArchive "%archive%" "%destination%" hp-dell
::-extract with to name with _ at the end of filename (is new foldername)
::-move contents of drivers_\winpe\x86 and drivers_\winpe\x64 directories into winPEWorkspace\Updates\drivers\3_x\x86\dell
:: delete original extracted folder, leave .cab file in place

::extractOutDriverArchives
::if the driver cab exists and an oem folder both architectures exist, then assume the drivers have already been extracted
if exist "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" if not exist "%pe3downloadPath%\x86\Dell" if not exist "%pe3downloadPath%\x64\Dell" call :extractOutDriverArchivesFunct "%pe3downloadPath%\!WinPE3_Dell_%WinPE3_Dell_latest%!" "%pe3downloadPath%" "Dell"
if exist "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" if not exist "%pe5downloadPath%\x86\Dell" if not exist "%pe5downloadPath%\x64\Dell" call :extractOutDriverArchivesFunct "%pe5downloadPath%\!WinPE5_Dell_%WinPE5_Dell_latest%!" "%pe5downloadPath%" "Dell"
if exist "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" if not exist "%pe10downloadPath%\x86\Dell" if not exist "%pe10downloadPath%\x64\Dell" call :extractOutDriverArchivesFunct "%pe10downloadPath%\!WinPE10_Dell_%WinPE10_Dell_latest%!" "%pe10downloadPath%" "Dell" 

if exist "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" if not exist "%pe3downloadPath%\x86\HP" if not exist "%pe3downloadPath%\x64\HP" call :extractOutDriverArchivesFunct "%pe3downloadPath%\!WinPE3_HP_%WinPE3_HP_latest%!" "%pe3downloadPath%" "HP"
if exist "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" if not exist "%pe5downloadPath%\x86\HP" if not exist "%pe5downloadPath%\x64\HP" call :extractOutDriverArchivesFunct "%pe5downloadPath%\!WinPE5_HP_%WinPE5_HP_latest%!" "%pe5downloadPath%" "HP"
if exist "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" if not exist "%pe10downloadPath%\x86\HP" if not exist "%pe10downloadPath%\x64\HP" call :extractOutDriverArchivesFunct "%pe10downloadPath%\!WinPE10_HP_%WinPE10_HP_latest%!" "%pe10downloadPath%" "HP"
:afterExtractingDrivers


::update/create environment.bat
if not exist "%scriptPath%\wimMgmt\resources\%setEnvironmentTemplate%" (echo   unable to set environment
goto end)
echo set ADKToolsRoot=%cd%>"%scriptPath%\wimMgmt\resources\%setEnvironmentScript%"
echo. >>"%scriptPath%\wimMgmt\resources\%setEnvironmentScript%"
type "%scriptPath%\wimMgmt\resources\%setEnvironmentTemplate%">>"%scriptPath%\wimMgmt\resources\%setEnvironmentScript%"

::update environment.bat in the adks
::Okay, so this change will mess up the copype.cmd commands. That makes it difficult to rebuild the workspace environment later.
::might want to figure out the conflict and change variable names so they don't conflict

::if /i "%AIK7Installed%" equ "true" (
::echo. >>"%AIK7InstallPath%\%AIK7legacyWinPEPath%\%AIK7legacysetEnvScript%"
::echo "%cd%\resources\scripts\wimMgmt\resources\setEnvironment.bat" >>"%AIK7InstallPath%\%AIK7legacyWinPEPath%\%AIK7legacysetEnvScript%"
::echo. >>"%AIK7InstallPath%\%AIK7legacyWinPEPath%\%AIK7legacysetEnvScript%"
::)

if /i "%ADK81UInstalled%" equ "true" (
echo. >>"%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
echo "%cd%\resources\scripts\wimMgmt\resources\setEnvironment.bat" >>"%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
echo. >>"%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
)

if /i "%ADK10Installed%" equ "true" (
echo. >>"%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
echo "%cd%\resources\scripts\wimMgmt\resources\setEnvironment.bat" >>"%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
echo. >>"%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
)


::run environment setting script (from adk)
::mount boot.wim and update (same as reset scenario) -wait, how does the reset scenario work again?
::mount pe version with it's dism version (use setenv.bat) -skip building pe3 if no newer ADK is installed, (cuz lazy)
::update drivers
::update packages
::update scripts
::update tools
::delete boot.wim
::save to boot.wim and unmount discard
::call createiso (aik 7 might be tricky), should work
::copy iso

pushd "%cd%"
if /i "%AIK7Installed%" neq "true" goto afterBuildingPE3
setlocal
if /i "%ADK81UInstalled%" neq "true" if /i "%ADK10Installed%" equ "true" call "%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
if /i "%ADK81UInstalled%" equ "true" call "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
call massupdate reset 3 x86
call massupdate reset 3 x64
call massupdate export 3 x86
call massupdate export 3 x64
endlocal
:afterBuildingPE3


if /i "%ADK81UInstalled%" neq "true" goto afterBuildingPE5
setlocal
call "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
call massupdate reset 5 x86
call massupdate reset 5 x64
call massupdate export 5 x86
call massupdate export 5 x64
endlocal
:afterBuildingPE5


if /i "%ADK10Installed%" neq "true" goto afterBuildingPE10
setlocal
call "%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
call massupdate reset 10 x86
call massupdate reset 10 x64
call massupdate export 10 x86
call massupdate export 10 x64
endlocal
:afterBuildingPE10
popd


::copy and rename all existing winpe.wim's into .\WININSTALLER
call exportToWININSTALLER


goto end
::start functions::


:extractBootFilesToWorkspace
mkdir "%workspaceDest%\winPEWorkspace\isoBootSector
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x86\Boot
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x86\EFI\Boot
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x86\EFI\Microsoft\Boot
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x64\Boot
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x64\EFI\Boot
for /d %%i in (2,3,4,5,10) do mkdir %workspaceDest%\winPEWorkspace\bootmanager\%%i\x64\EFI\Microsoft\Boot

::copy PEv3 bootfiles
if /i "%AIK7Installed%" equ "true" (
copy /y "%AIK7InstallPath%\Tools\PETools\x86\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\3\x86\"
copy /y "%AIK7InstallPath%\Tools\PETools\x86\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\3\x86\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\x86\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\3\x86\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\x86\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\3\x86\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\x86\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\3\x86\EFI\Microsoft\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\bootmgr.efi" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\EFI\Boot\bootx64.efi" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\EFI\Boot\"
copy /y "%AIK7InstallPath%\Tools\PETools\amd64\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\3\x64\EFI\Microsoft\Boot\"
)

::copy PEv5 bootfiles
if /i "%ADK81Uinstalled%" equ "true" (
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\bootmgr.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\memtest.exe" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\Resources\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\Boot\Resources\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Boot\bootia32.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\EFI\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\EFI\Microsoft\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\memtest.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\EFI\Microsoft\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\EFI\Microsoft\Boot\Resources"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\5\x86\EFI\Microsoft\Boot\Resources"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\bootmgr.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\memtest.exe" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\Resources\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\Boot\Resources\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Boot\bootx64.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\EFI\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\EFI\Microsoft\Boot\"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\memtest.efi" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\EFI\Microsoft\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\EFI\Microsoft\Boot\Resources"
copy /y "%ADK81Uinstallpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\5\x64\EFI\Microsoft\Boot\Resources"
)

::copy PEv10 bootfiles
if /i "%ADK10installed%" equ "true" (
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\bootmgr.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\memtest.exe" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\Resources\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\Boot\Resources\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Boot\bootia32.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\EFI\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\EFI\Microsoft\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\memtest.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\EFI\Microsoft\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\EFI\Microsoft\Boot\Resources"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\Media\EFI\Microsoft\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\10\x86\EFI\Microsoft\Boot\Resources"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\bootmgr" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\bootmgr.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\boot.sdi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\bootfix.bin" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\memtest.exe" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\Resources\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\Boot\Resources\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Boot\bootx64.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\EFI\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\bcd" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\EFI\Microsoft\Boot\"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\memtest.efi" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\EFI\Microsoft\Boot\"
mkdir "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\EFI\Microsoft\Boot\Resources"
copy /y "%ADK10Installpath%\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media\EFI\Microsoft\Boot\Resources\bootres.dll" "%workspaceDest%\winPEWorkspace\bootmanager\10\x64\EFI\Microsoft\Boot\Resources"
)
goto :eof


::copy WinPE3.1 into workspace
:addWinPE31ToWorkspace
if /i "%AIK7Installed%" neq "true" goto :eof
if exist "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media\sources\boot.wim" goto :eof
pushd "%cd%"
setlocal
call "%AIK7InstallPath%\%AIK7legacyWinPEPath%\%AIK7legacysetEnvScript%"
if not exist "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO" call copype x86 "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO"
if not exist "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO" call copype AMD64 "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO"
endlocal
popd

::standardize directory tree
call :cleanupAIK "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO"
call :cleanupAIK "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO"

::copy winpe to originalwim folder
copy "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\3_x\PE_x86\originalWim\winpe31.wim"
copy "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\3_x\PE_x64\originalWim\winpe31.wim"

::copy boot files
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x86\bootmanager" /mir /xd sources >nul
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x64\bootmanager" /mir /xd sources >nul
goto :eof


::copy WinPE5.0 into workspace
:addWinPE50ToWorkspace
if /i "%ADK81Uinstalled%" neq "true" goto :eof
if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim" goto :eof
pushd "%cd%"
setlocal
call "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
if not exist "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO" call copype x86 "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO"
if not exist "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO" call copype AMD64 "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO"
endlocal
popd

::remove muis
call :cleanupADK "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO"
call :cleanupADK "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO"

::copy winpe to originalwim folder
copy /y "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe50.wim"
copy /y "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe50.wim"

::copy boot files
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\fwfiles\efisys.bin" 
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\bootmanager" /mir /xd sources >nul
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\bootmanager" /mir /xd sources >nul
goto :eof


::copy WinPE10 into workspace
:addWinPE10ToWorkspace
if /i "%ADK10installed%" neq "true" goto :eof
if exist "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media\sources\boot.wim" goto :eof
pushd "%cd%"
setlocal
call "%ADK10installpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
if not exist "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO" call copype x86 "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO"
if not exist "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO" call copype AMD64 "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO"
endlocal
popd

::remove muis
call :cleanupADK "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO"
call :cleanupADK "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO"

::copy winpe to originalwim folder
copy /y "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\originalWim\winpe10.wim"
copy /y "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\originalWim\winpe10.wim"

::copy boot files
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\fwfiles\efisys.bin"
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\bootmanager" /mir /xd sources >nul
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\bootmanager" /mir /xd sources >nul
goto :eof


::expects %1 as the place the PE files were copied to
:cleanupAIK
if not exist "%~1" (echo error, %~1 does not exist
goto :eof)
set targetDir=%~1

mkdir "%targetDir%\fwfiles"
mkdir "%targetDir%\mount"
if exist "%targetDir%\ISO\Boot\fonts" rmdir /s /q "%targetDir%\ISO\Boot\fonts"
if exist "%targetDir%\ISO\EFI\Microsoft\Boot\fonts" rmdir /s /q "%targetDir%\ISO\EFI\Microsoft\Boot\fonts"
if exist "%targetDir%\etfsboot.com" move "%targetDir%\etfsboot.com"  "%targetDir%\fwfiles\etfsboot.com"
if exist "%targetDir%\efisys_noprompt.bin" if exist "%targetDir%\efisys.bin" (
move /y "%targetDir%\efisys_noprompt.bin" "%targetDir%\fwfiles\efisys.bin"
del "%targetDir%\efisys.bin")
move /y "%targetDir%\winpe.wim" "%targetDir%\ISO\sources\boot.wim"
move /y "%targetDir%\ISO" "%targetDir%\media"
goto :eof


::expects %1 as the place the PE files were copied to
:cleanupADK
if not exist "%~1" (echo error, %~1 does not exist
goto :eof)
set removeList=resources\localizationList.txt
if not exist "%removeList%" (echo "%removeList%" does not exist
goto :eof)
set targetDir=%~1

::copy
for /f %%i in (%removeList%) do (if exist "%targetDir%\media\%%i" rmdir /s /q "%targetDir%\media\%%i"
if exist "%targetDir%\media\Boot\%%i" rmdir /s /q "%targetDir%\media\Boot\%%i"
if exist "%targetDir%\media\EFI\Boot\%%i" rmdir /s /q "%targetDir%\media\EFI\Boot\%%i"
if exist "%targetDir%\media\EFI\Microsoft\Boot\%%i" rmdir /s /q "%targetDir%\media\EFI\Microsoft\Boot\%%i")
goto :eof


:readPEDrivers
if not exist "%resourcePath%\%WinPEDriversURLtxt%" (echo   Unable to find WinPE Driver URLs
echo   from "%resourcePath%\%WinPEDriversURLtxt%"
echo   Will not add drivers to PE images
set winPEDriverDLs=invalid
goto :eof)

for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_Dell_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_Dell_latest=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_Dell_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_Dell_latest=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_Dell_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_Dell_latest=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_Dell_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_Dell_latest=%%j

if not defined WinPE10_Dell_latest (echo   Will not add drivers to PE images
set winPEDriverDLs=invalid
goto :eof)

for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_Dell_%WinPE10_Dell_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_Dell_%WinPE10_Dell_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_Dell_%WinPE10_Dell_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_Dell_%WinPE10_Dell_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_Dell_%WinPE10_Dell_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_Dell_%WinPE10_Dell_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_Dell_%WinPE10_Dell_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_Dell_%WinPE10_Dell_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_Dell_%WinPE5_Dell_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_Dell_%WinPE5_Dell_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_Dell_%WinPE5_Dell_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_Dell_%WinPE5_Dell_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_Dell_%WinPE5_Dell_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_Dell_%WinPE5_Dell_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_Dell_%WinPE5_Dell_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_Dell_%WinPE5_Dell_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_Dell_%WinPE4_Dell_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_Dell_%WinPE4_Dell_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_Dell_%WinPE4_Dell_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_Dell_%WinPE4_Dell_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_Dell_%WinPE4_Dell_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_Dell_%WinPE4_Dell_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_Dell_%WinPE4_Dell_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_Dell_%WinPE4_Dell_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_Dell_%WinPE3_Dell_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_Dell_%WinPE3_Dell_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_Dell_%WinPE3_Dell_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_Dell_%WinPE3_Dell_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_Dell_%WinPE3_Dell_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_Dell_%WinPE3_Dell_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_Dell_%WinPE3_Dell_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_Dell_%WinPE3_Dell_latest%_CRC32=%%j


for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_HP_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_HP_latest=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_HP_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_HP_latest=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_HP_latest==" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_HP_latest==%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_HP_latest=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_HP_latest=%%j

if not defined WinPE10_HP_latest (echo   Will not add drivers to PE images
set winPEDriverDLs=invalid
goto :eof)

for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_HP_%WinPE10_HP_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_HP_%WinPE10_HP_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_HP_%WinPE10_HP_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_HP_%WinPE10_HP_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_HP_%WinPE10_HP_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_HP_%WinPE10_HP_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE10_HP_%WinPE10_HP_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE10_HP_%WinPE10_HP_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_HP_%WinPE5_HP_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_HP_%WinPE5_HP_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_HP_%WinPE5_HP_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_HP_%WinPE5_HP_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_HP_%WinPE5_HP_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_HP_%WinPE5_HP_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE5_HP_%WinPE5_HP_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE5_HP_%WinPE5_HP_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_HP_%WinPE4_HP_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_HP_%WinPE4_HP_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_HP_%WinPE4_HP_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_HP_%WinPE4_HP_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_HP_%WinPE4_HP_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_HP_%WinPE4_HP_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE4_HP_%WinPE4_HP_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE4_HP_%WinPE4_HP_latest%_CRC32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_HP_%WinPE3_HP_latest%=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_HP_%WinPE3_HP_latest%=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_HP_%WinPE3_HP_latest%_URL=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_HP_%WinPE3_HP_latest%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_HP_%WinPE3_HP_latest%_URL2=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_HP_%WinPE3_HP_latest%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "WinPE3_HP_%WinPE3_HP_latest%_CRC32=" %resourcePath%\%WinPEDriversURLtxt%') do set WinPE3_HP_%WinPE3_HP_latest%_CRC32=%%j
goto :eof


::Expects driver archive to extract %1, path to extract it to %2, and Dell or HP archive style %3
:extractOutDriverArchivesFunct
if /i "%~1" equ "" (echo   error, driver archive to extract not specified
goto :eof)
if not exist "%~1" (echo   error, driver archive not found
echo  at "%~1"
goto :eof)
if /i "%~3" neq "dell" if /i "%~3" neq "hp" (echo   Error extracting %~1
echo   Only Dell and HP driver extraction is supported, oem="%~3" unsupported
goto :eof)
set driverArchiveFullPath=%~1
set driverArchiveName=%~nx1
set extractPath=%~2
set archiveStyle=%~3
"%toolsPath%\%architecture%\7z\%sevenz%" x "%driverArchiveFullPath%" -o"%extractPath%\%driverArchiveName%_" -aoa -y

if /i "%archiveStyle%" equ "HP" goto HPExtractStyle
::this assumes Dell extract style
if not exist "%extractPath%\x86\Dell" mkdir "%extractPath%\x86\Dell"
if not exist "%extractPath%\x64\Dell" mkdir "%extractPath%\x64\Dell"

robocopy "%extractPath%\%driverArchiveName%_\winpe\x86" "%extractPath%\x86\Dell" /move /e
robocopy "%extractPath%\%driverArchiveName%_\winpe\x64" "%extractPath%\x64\Dell" /move /e

if defined extractPath if exist "%extractPath%\%driverArchiveName%_" rmdir /s /q "%extractPath%\%driverArchiveName%_"
goto :eof
::this assumes HP extract style
:HPExtractStyle
if not exist "%extractPath%\x86\HP" mkdir "%extractPath%\x86\HP"
if not exist "%extractPath%\x64\HP" mkdir "%extractPath%\x64\HP"

::this is so hacky, TODO: needs updating
set tempfile=temp.txt
dir /b "%extractPath%\%driverArchiveName%_" >"%tempfile%"
for /f %%i in ('findstr "1.0" %tempfile%') do set weirdDirName=%%i
dir /b "%extractPath%\%driverArchiveName%_\%weirdDirName%" >"%tempfile%"
for /f %%i in ('findstr "x86" %tempfile%') do set weirdDirName2x86=%%i
for /f %%i in ('findstr "x64" %tempfile%') do set weirdDirName2x64=%%i
if exist "%tempfile%" del "%tempfile%"

if exist "%extractPath%\%driverArchiveName%_\%weirdDirName%\%weirdDirName2x86%" robocopy "%extractPath%\%driverArchiveName%_\%weirdDirName%\%weirdDirName2x86%" "%extractPath%\x86\hp" /move /e
if exist "%extractPath%\%driverArchiveName%_\%weirdDirName%\%weirdDirName2x64%" robocopy "%extractPath%\%driverArchiveName%_\%weirdDirName%\%weirdDirName2x64%" "%extractPath%\x64\hp" /move /e

if defined extractPath if exist "%extractPath%\%driverArchiveName%_" rmdir /s /q "%extractPath%\%driverArchiveName%_"
goto :eof


:detectAIK7
set default_AIK7installpath=C:\Program Files\Windows AIK
set default_legacyx86packagesPath=Tools\PETools\x86\WinPE_FPs
set default_legacyx64packagesPath=Tools\PETools\amd64\WinPE_FPs

set AIK7InstallPath=%default_AIK7installpath%
if /i "%architecture%" equ "x86" set AIK7packagesPath=%default_legacyx86packagesPath%
if /i "%architecture%" equ "x64" set AIK7packagesPath=%default_legacyx64packagesPath%

if exist "%AIK7InstallPath%" if exist "%AIK7InstallPath%\Tools\Servicing\dism.exe" set AIK7Installed=true
goto :eof


:detectADK81UandADK10
if /i "%architecture%" equ "x86" set default_ADK81Uinstallpath=C:\Program Files\Windows Kits\8.1
if /i "%architecture%" equ "x64" set default_ADK81Uinstallpath=C:\Program Files ^(x86^)\Windows Kits\8.1
if /i "%architecture%" equ "x86" set default_ADK10installpath=C:\Program Files\Windows Kits\10
if /i "%architecture%" equ "x64" set default_ADK10installpath=C:\Program Files ^(x86^)\Windows Kits\10
set default_x86packagesPath=Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs
set default_x64packagesPath=Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs

if /i "%architecture%" equ "x86" set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
if /i "%architecture%" equ "x64" set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
set KitsRoot81RegValueName=KitsRoot81
set KitsRoot10RegValueName=KitsRoot10

for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %KitsRoot81RegValueName%') do set ADK81Uinstallpath=%%j
::path includes a trailing backslash \
if not defined ADK81Uinstallpath set ADK81Uinstallpath=%default_ADK81Uinstallpath%
if /i "%ADK81Uinstallpath:~-1%" equ "\" set ADK81Uinstallpath=%ADK81Uinstallpath:~,-1%

for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v %KitsRoot10RegValueName%') do set ADK10installpath=%%j
::path includes a trailing backslash \
if not defined ADK10installpath set ADK10installpath=%default_adk10installpath%
if /i "%ADK10installpath:~-1%" equ "\" set ADK10installpath=%ADK10installpath:~,-1%

if /i "%architecture%" equ "x86" set Win81UpackagesPath=%default_x86packagesPath% 
if /i "%architecture%" equ "x64" set Win81UpackagesPath=%default_x64packagesPath%
if /i "%architecture%" equ "x86" set Win10packagesPath=%default_x86packagesPath% 
if /i "%architecture%" equ "x64" set Win10packagesPath=%default_x64packagesPath%

if exist "%ADK81Uinstallpath%" if exist "%ADK81Uinstallpath%\%Win81UpackagesPath%" set ADK81UInstalled=true
if exist "%ADK10installpath%" if exist "%ADK10installpath%\%Win10packagesPath%" set ADK10Installed=true

::if /i "%ADK81UInstalled%" equ "true" if /i "%architecture%" equ "x86" set path=%ADK81Uinstallpath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
::if /i "%ADK81UInstalled%" equ "true" if /i "%architecture%" equ "x64" set path=%ADK81Uinstallpath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%
::if /i "%ADK10Installed%" equ "true" if /i "%architecture%" equ "x86" set path=%ADK10installpath%\Assessment and Deployment Kit\Deployment Tools\x86\DISM;%path%
::if /i "%ADK10Installed%" equ "true" if /i "%architecture%" equ "x64" set path=%ADK10installpath%\Assessment and Deployment Kit\Deployment Tools\amd64\DISM;%path%
goto :eof


::Usage hashCheck myfile.wim hashData hashType   #returns hash=valid or hash=%hashData%
::hashType is crc32, crc64, sha1, sha256
::ex: hashCheck x:\myfile.wim 5AB54248 crc32
:hashCheck 
@echo off
if not exist "%~1" (echo   %~1 does not exist
set hash=invalid
goto :eof)
if /i "%~2" equ "" (echo  no hashData entered
set hash=invalid
goto :eof) else (set hashData=%~2)
if /i "%~3" equ "" (set hashtype=crc32) else (set hashtype=%~3)

set tempfile=rawHashOutput.txt
"%toolsPath%\%architecture%\7z\%sevenz%" h -scrc%hashtype% "%~1">%tempfile%

set errorlevel=0
for /f "tokens=1-10" %%a in ('find /i /c "Cannot open" %tempfile%') do set errorlevel=%%c
if /i "%errorlevel%" neq "0" (echo   Unable to generate hash, file currently in use
if exist "%tempfile%" del "%tempfile%"
goto :eof)

for /f "skip=2 tokens=1-10" %%a in ('find /i "for data" %tempfile%') do (set calculatedHash=%%d)
::echo %%d "%~1"
if exist "%tempfile%" del "%tempfile%"

::echo  comparing: hash:"%hashData%"  %~1
::echo  with       hash:"%calculatedHash%"  %~1
if "%calculatedHash%" equ "%hashData%" (
echo.
echo   %~1% successfully downloaded
set hash=valid
) else (
echo   Hash check failed, please redownload
echo   %~1
set hash=%hashData%
)
goto :eof


:booleanprompt
echo   Enter "yes" or "no"
set /p userInput=
if /i "%userInput%" equ "y" (set input=yes
goto :eof)
if /i "%userInput%" equ "ye" (set input=yes
goto :eof)
if /i "%userInput%" equ "yes" (set input=yes
goto :eof)
if /i "%userInput%" equ "n" (set input=no
goto :eof)
if /i "%userInput%" equ "no" (set input=no
goto :eof)
goto booleanprompt


:end
endlocal
