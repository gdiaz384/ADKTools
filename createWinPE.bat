@echo off
setlocal enabledelayedexpansion
::check if adks are installed
::prompt to install an ADK if one is not already installed
::unzip basic workspace -(create workspace) with pe versions, bootfiles and updates folder (scripts\tools\drivers)c
::run enviornment setting script (from adk) (set local?)
::copype amd64 pe_x64\iso (must be empty)
::delete extra muis (annoying)
::copy originalpe found under media\sources\boot.wim to pe_x64\originalwim\winpe31.wim
::copy boot files

::ask? to update winpe 5->5.1, then copy 5.1 over sources\boot.wim

::fill tools directory with latest tools available (should already have gimagex/chm/7za/aria2c)
::extract out PEscripts to peworkpace\updates\pescripts
::download dell drivers (hp?) -need to test driver dl reliability (hash check) dell3=http:url  dell3crc32hash=crc32hash
::extract drivers appropriately
::update environment.bat
::update enviornment.bat in the adks
::run enviornment setting script (from adk)

::del boot.wim
::mount originalpe.wim and update (same as reset scenario)
::mount pe version with it's dism version (use setenv.bat)
::update drivers
::update packages
::update scripts
::update tools
::unmount and save
::call createiso (aik 7 might be tricky)
::move iso

::move on to next adk

set resourcePath=resources
set toolPath=%resourcePath%\tools
set archivePath=%resourcePath%\archives
set sevenZ=7z.exe

set winPEWorkspaceArchive=winPEWorkspace.7z
set workspaceDest=%userprofile%\desktop

::AIK stores tools as x86\bcdboot.exe  and  amd64\servicing\dism.exe
::Tools\PETools\amd64\boot\efisys_noprompt.efi
set AIK7legacyWinPEPath=Tools\PETools
set AIK7legacyToolsPath=Tools
set AIK7legacysetEnvScript=pesetenv.cmd

::ADK stores tools as x86\oscdimg\efisys_noprompt.bin  and amd64\dism\dism.exe
set ADKWinPEPath=Assessment and Deployment Kit\Windows Preinstallation Environment
set ADKDeploymentToolsPath=Assessment and Deployment Kit\Deployment Tools
set ADKsetEnvScript=DandISetEnv.bat

if /i "%processor_architecture%" equ "x86" set architecture=x86
if /i "%processor_architecture%" equ "AMD64" set architecture=x64
if not defined architecture (echo    unspecified error
goto end)


if not exist "%workspaceDest%\winPEWorkspace" "%toolPath%\%sevenZ%" x "%archivePath%\%winPEWorkspaceArchive%" -o"%workspaceDest%" -y -aos
if not exist "%workspaceDest%\winPEWorkspace" (echo   error extracting workspace
goto end)

call :detectAIK7
call :detectADK81UandADK10
if /i "%AIK7Installed%" equ "true" if /i "%ADK81Uinstalled%" equ "true" if /i "%ADK10installed%" equ "true" set allADKsInstalled=true

cls

if /i "%AIK7Installed%" neq "true" if exist "installADK.bat" (
echo.
echo   AIK 7 is not installed, download and install it now? ^(y/n^)
call :booleanprompt
if /i "%input%" equ "yes" call installADK 2
call :detectAIK7
)

::set callback=postADK81UPrompt
if /i "%ADK81Uinstalled%" neq "true" if exist "installADK.bat" (
echo.
echo   ADK 8.1 U is not installed, download and install it now? ^(y/n^)
call :booleanprompt
if /i "!input!" equ "yes" call installADK 3
call :detectADK81UandADK10
)


if /i "%ADK10installed%" neq "true" if exist "installADK.bat" (
echo.
echo   ADK 10 is not installed, download and install it now? ^(y/n^)
call :booleanprompt
if /i "!input!" equ "yes" call installADK 4
call :detectADK81UandADK10
)

if /i "%AIK7Installed%" neq "true" if /i "%ADK81Uinstalled%" neq "true" if /i "%ADK10installed%" neq "true" (
echo   Error, no ADKs installed, unable to create WinPE.wim
echo   Please install at least one and run %~nx0 again
goto end)


::copy WinPE3.1 into workspace
if /i "%AIK7Installed%" neq "true" goto afterAddingWinPE31
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
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x64\bootmanager" /mir /xd sources
:afterAddingWinPE31


::copy WinPE5.0 into workspace
if /i "%ADK81Uinstalled%" neq "true" goto afterAddingWinPE50
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
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\fwfiles\efisys.bin" 

::copy winpe to originalwim folder
copy "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe50.wim"
copy "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe50.wim"

::copy boot files
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\bootmanager" /mir /xd sources
:afterAddingWinPE50


::copy WinPE10 into workspace
if /i "%ADK10installed%" neq "true" goto afterAddingWinPE10
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
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\fwfiles\efisys.bin" 

::copy winpe to originalwim folder
copy "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\originalWim\winpe10.wim"
copy "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\originalWim\winpe10.wim"

::copy boot files
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\bootmanager" /mir /xd sources
:afterAddingWinPE10


::ask? to update winpe 5->5.1, then copy 5.1 over sources\boot.wim









goto end

::start functions::


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


::expects %1 as the place the PE files were copied to
:cleanupAIK
if not exist "%~1" (echo error, %~1 does not exist
goto :eof)
set targetDir=%~1

mkdir "%targetDir%\fwfiles"
mkdir "%targetDir%\mount"
if exist "%targetDir%\ISO\boot\fonts" rmdir /s /q "%targetDir%\ISO\boot\fonts"
if exist "%targetDir%\ISO\EFI\Microsoft\boot\fonts" rmdir /s /q "%targetDir%\ISO\EFI\Microsoft\boot\fonts"
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
if exist "%targetDir%\media\boot\%%i" rmdir /s /q "%targetDir%\media\boot\%%i"
if exist "%targetDir%\media\EFI\boot\%%i" rmdir /s /q "%targetDir%\media\EFI\boot\%%i"
if exist "%targetDir%\media\EFI\Microsoft\boot\%%i" rmdir /s /q "%targetDir%\media\EFI\Microsoft\boot\%%i")
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
