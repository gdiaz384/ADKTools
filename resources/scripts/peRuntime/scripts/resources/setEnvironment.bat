@echo off
::list PE information
echo.
call .\scripts\resources\getPEInfo.bat

::set name of script to automatically launch (detect later if at root of flash drive)
set autoDetectImagesScript=autoImage.bat
set credentialsFile=credentialsForNetworkDrive.txt
::maybe could embedd these two into the credentialsFile.txt and run dynamicly
set default_deployClientPathAndExe=AriaDeploy\client\AriaDeployClient.bat
set default_ networkDrive=Y:

:: update path BEFORE enabling local variables so path changes are global
:: local variables (with a .bat context) are auto-enabled when enabling delayed expansion
set resourcesPath=%systemroot%\system32\scripts\resources
set scriptPath=%systemroot%\system32\scripts
set toolPath=%systemroot%\System32\tools
set tempDism=%toolPath%\dism
set tempBcdBoot=%toolPath%\bcdboot
set tempUSMT=%toolPath%\usmt
set tempPath=%tempDism%;%tempBcdBoot%;%tempUSMT%;%scriptPath%;%toolPath%;%resourcesPath%
set path=%tempPath%;%path%
if exist "%tempDism%\dism.exe" if exist "%systemroot%\system32\dism.exe" ren "%systemroot%\system32\dism.exe" dism_.exe
if exist "%tempBcdBoot%\bcdboot.exe" if exist "%systemroot%\system32\bcdboot.exe" ren "%systemroot%\system32\bcdboot.exe" bcdboot_.exe
if exist "%tempBcdBoot%\bootsect.exe" if exist "%systemroot%\system32\bootsect.exe" ren "%systemroot%\system32\bootsect.exe" bootsect_.exe
if exist "%tempBcdBoot%\bcdedit.exe" if exist "%systemroot%\system32\bcdedit.exe" ren "%systemroot%\system32\bcdedit.exe" bcdedit_.exe

::disable firewall
wpeutil disablefirewall 1>nul 2>nul

::attempt to map network drive
if exist ".\scripts\mapNetworkDrive.bat" call ".\scripts\mapNetworkDrive.bat"

::read settings from credentials file
if not exist credentialsForNetworkDrive.txt goto ready
set deployClientPathAndExe=
for /f "skip=2 delims== tokens=1-10" %%a in ('find "clientDriveLetter" %credentialsFile%') do if /i "%%b" neq "" set networkDrive=%%b:
for /f "skip=2 delims== tokens=1-10" %%a in ('find "deployClientPathAndExe" %credentialsFile%') do if /i "%%b" neq "" set deployClientPathAndExe=%%b
if not exist %networkDrive% goto ready
if not defined deployClientPathAndExe (set deployClientPathAndExe=%default_networkDrive%\%default_deployClientPathAndExe%) else (
set deployClientPathAndExe=%networkDrive%\%deployClientPathAndExe%)

::execute deployClient.bat (turn over control to it completely), always run directly from server
if not exist "%deployClientPathAndExe%" goto ready
if exist "%deployClientPathAndExe%" "%deployClientPathAndExe%"
 

:ready
::enable delayed expansion by default for new cmd /c commands
reg add "HKLM\Software\Microsoft\Command Processor" /v DelayedExpansion /t REG_DWORD /d 1 /f
:: enable delayed expansion for this current set of batch file processing
:: will return to disabled after the initial processing ends due to initial cmd setting being off
setlocal enabledelayedexpansion

::list current volumes 
if exist .\scripts\diskpart\listdisk.bat diskpart.exe /s .\scripts\diskpart\listdisk.bat
::"list volume" or "list partition" should also work due to list.bat script

::search for an autoDetect script at a root folder, with a fallback to x:\windows\system32\scripts
for %%i in (Y,N,C,D,E,F,G,H,I,J,K) do (if exist "%%i:\%autoDetectImagesScript%" (set autoDetectDrive=%%i:))
if exist "%autoDetectDrive%\%autoDetectImagesScript%" "%autoDetectDrive%\%autoDetectImagesScript%"
if exist ".\scripts\%autoDetectImagesScript%" ".\scripts\%autoDetectImagesScript%"
echo.
echo     PE setup complete. Enter:
echo      "%autoDetectImagesScript%"  -to try to automatically detect and install Windows
echo      "image"  -to manually install a specific Windows Image file (.wim)
echo      "help"  -for help with the syntax in performing other common operations
echo.
:end