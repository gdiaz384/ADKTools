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
::copy PEscripts to peworkpace\updates\pescripts
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
set scriptPath=%resourcePath%\scripts
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


call :detectAIK7
call :detectADK81UandADK10
if /i "%AIK7Installed%" equ "true" if /i "%ADK81Uinstalled%" equ "true" if /i "%ADK10installed%" equ "true" set allADKsInstalled=true

cls

if /i "%~1" equ "skipPrompt" goto afterPrompts
if /i "%AIK7Installed%" neq "true" if exist "installADK.bat" (
echo.
echo   AIK 7 is not installed, download and install it now? ^(y/n^)
call :booleanprompt
if /i "!input!" equ "yes" call installADK 2
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
:afterPrompts

if /i "%AIK7Installed%" neq "true" if /i "%ADK81Uinstalled%" neq "true" if /i "%ADK10installed%" neq "true" (
echo   Error, no ADKs installed, unable to create WinPE.wim
echo   Please install at least one and run %~nx0 again
goto end)


::extract workspace
if not exist "%workspaceDest%\winPEWorkspace" "%toolPath%\%sevenZ%" x "%archivePath%\%winPEWorkspaceArchive%" -o"%workspaceDest%" -y -aos
if not exist "%workspaceDest%\winPEWorkspace" (echo   error extracting workspace
goto end)


:populateWorkspaces
call :addWinPE31ToWorkspace
call :addWinPE50ToWorkspace
call :addWinPE10ToWorkspace


::ask maybe? update winpe 5->5.1, then copy 5.1 over sources\boot.wim
::this takes a very long time
setlocal
if /i "%ADK81UInstalled%" equ "true" call "%scriptPath%\updateWinPE50.bat"
endlocal

:pie
::fill tools directory with latest tools available (should already have gimagex/chm/7za/aria2c)
::%workspaceDest%\winPEWorkspace\Updates\tools

::if dism is already there, then assume tools do not need to be copied
if exist "%workspaceDest%\winPEWorkspace\Updates\tools\dism\x86\dism.exe" goto afterToolsCopy

::if ADK10Installed, copy from adk10 (bcdboot/dism), then goto afterToolsCopy
if /i "%ADK10Installed%" neq "true" goto afterADK10ToolsCopy
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\dism" %workspaceDest%\winPEWorkspace\Updates\tools\x86\dism /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x64\dism" %workspaceDest%\winPEWorkspace\Updates\tools\x64\dism /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\bcdboot" %workspaceDest%\winPEWorkspace\Updates\tools\x86\bcdboot /e >nul
robocopy "%ADK10installpath%\%ADKDeploymentToolsPath%\x64\bcdboot" %workspaceDest%\winPEWorkspace\Updates\tools\x64\bcdboot /e >nul
goto afterToolsCopy
:afterADK10ToolsCopy

:: if not skipped yet, and if ADK81Uinstalled, copy from adk81U, then goto afterToolsCopy
if /i "%ADK81UInstalled%" neq "true" goto afterADK81UToolsCopy
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\dism" %workspaceDest%\winPEWorkspace\Updates\tools\x86\dism /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x64\dism" %workspaceDest%\winPEWorkspace\Updates\tools\x64\dism /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\bcdboot" %workspaceDest%\winPEWorkspace\Updates\tools\x86\bcdboot /e >nul
robocopy "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x64\bcdboot" %workspaceDest%\winPEWorkspace\Updates\tools\x64\bcdboot /e >nul
goto afterToolsCopy
:afterADK81UToolsCopy

::Issue warning to user about old DISM version, + paths to copy new one to
echo.
echo   Warning! 
echo   The only version of DISM found is from AIK 7.
echo   This old DISM version was prior to imageX imaging functionality 
echo   integration and cannot be used for automated imaging.
echo.
echo   To image: 1. install a newer ADK ^(81U/10^) and restart %~nx0
echo    2. copy imagex.exe in the directory below and use it manually
echo   or 3. otherwise obtain a newer version of DISM and place at:
echo   %workspaceDest%\winPEWorkspace\Updates\tools\dism
echo   echo "CTRL+C" to exit or 
pause 
::copy from Win7AIK


:afterToolsCopy


::copy PEscripts to peworkpace\updates\pescripts


goto end

::start functions::


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
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\3_x\PE_x64\bootmanager" /mir /xd sources
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
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\fwfiles\efisys.bin" 

::copy winpe to originalwim folder
copy "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe50.wim"
copy "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe50.wim"

::copy boot files
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\bootmanager" /mir /xd sources
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
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\x86\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\fwfiles\efisys.bin"
copy /y "%ADK10installpath%\%ADKDeploymentToolsPath%\amd64\Oscdimg\efisys_noprompt.bin" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\fwfiles\efisys.bin" 

::copy winpe to originalwim folder
copy "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\originalWim\winpe10.wim"
copy "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media\sources\boot.wim" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\originalWim\winpe10.wim"

::copy boot files
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x86\bootmanager" /mir /xd sources
robocopy "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media" "%workspaceDest%\winPEWorkspace\10_x\PE_x64\bootmanager" /mir /xd sources
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
"%toolPath%\%sevenz%" h -scrc%hashtype% "%~1">%tempfile%

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
