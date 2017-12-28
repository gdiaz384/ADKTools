@echo off
setlocal enabledelayedexpansion

::set defaults
::detect any installed ADKs
::present download and download+install options for non-installed ADKs
::download selected ADK, 
::go to install, and abort if not requested

pushd "%~dp0"
set ADKDownloadPath=WindowsADKs
set ADK10version=latest
::latest, RTM, 1511, 1607, 1703, 1709

set integratePackages=true
set integrateDrivers=true
set integrateScripts=true
set buildImages=true

set resourcePath=resources
set toolsPath=%resourcePath%\tools
set archivePath=%resourcePath%\archives
set urlsFile=urls.txt

set Sevenz=7z.exe
set aria2=aria2c.exe

set shortcutsArchive=shortcuts.zip
set AIK7Path=%ADKDownloadPath%\AIK7
set ADK81UPath=%ADKDownloadPath%\ADK81U

if /i "%ADK10version%" equ "latest" for /f "eol=: delims== tokens=1*" %%i in ('find /i "Win10ADK_latest=" %resourcePath%\%urlsFile%') do set ADK10version=%%j
if not defined ADK10version (echo  Unable to determine latest ADK10 version using "%resourcePath%\%urlsFile%"
goto end)
if /i "%ADK10version%" equ "latest" (echo  unable to determine latest ADK10 version using "%resourcePath%\%urlsFile%"
goto end)

set ADK10Path=%ADKDownloadPath%\ADK10_%ADK10version%

set ADKSetup_defaultName=adksetup.exe
set ADK81UStagingExe=adksetup_81U.exe
set ADK10StagingExe=adksetup_%ADK10version%.exe

if /i "%processor_architecture%" equ "x86" set architecture=x86
if /i "%processor_architecture%" equ "AMD64" set architecture=x64
if not defined architecture (echo   error architecture not defined
goto end)

set AIK7DetectionFile=KB3AIK_EN.iso
set AIK7Folder=KB3AIK_EN
set AIK7SupplementDetectionFile=waik_supplement_en-us.iso
set AIK7SupplementFolder=waik_supplement_en-us
if /i "%architecture%" equ "x86" set AIK7InstallExe=wAIKX86.msi
if /i "%architecture%" equ "x64" set AIK7InstallExe=wAIKAMD64.msi
set AIK7SupplementExtractedDetectionFile=copype.cmd
set ADK81UDetectionFolder=Installers
set ADK10DetectionFolder=Installers
set ADK81UInstallExe=adksetup.exe
set ADK10InstallExe=adksetup.exe

set downloadOnly=invalid
set allADKsInstalled=false
set AIK7Installed=false
set ADK81Uinstalled=false
set ADK10installed=false

call :detectAIK7
call :detectADK81UandADK10
if /i "%AIK7Installed%" equ "true" if /i "%ADK81Uinstalled%" equ "true" if /i "%ADK10installed%" equ "true" set allADKsInstalled=true

cls
if /i "%~1" equ "0" goto end
if /i "%~1" equ "1" goto DownloadAndInstallADK10
if /i "%~1" equ "2" goto All


::get user input
:mainMenu
echo.
echo.
if /i "%AIK7Installed%" equ "true" echo  Detected AIK 7 installation at %AIK7InstallPath%
if /i "%AIK7Installed%" neq "true" echo  AIK 7 not installed
if /i "%ADK81Uinstalled%" equ "true" echo  Detected ADK 8.1 U installation at %ADK81Uinstallpath%
if /i "%ADK81Uinstalled%" neq "true" echo  ADK 8.1 U not installed
if /i "%ADK10installed%" equ "true" echo  Detected ADK 10 installation at %ADK10installpath%
if /i "%ADK10installed%" neq "true" echo  ADK 10 not installed
echo.
echo  Select one:  (space needed to download/space used after install)
echo.
echo  1. (Simple) Install ADK10_%ADK10version% and generate WinPE.wim images.
echo  2. (Full) Install AIK7, ADK8.1U, ADK10_%ADK10version% and generate images.
echo  3. (Custom) Only Download and Install some ADKs.
echo  0. Quit.

:mainMenuInput
set /p input=
if /i "%input%" equ "0" goto end
if /i "%input%" equ "1" (set installMode=simple
goto chooseDriversAndScripts)
if /i "%input%" equ "2" (set installMode=full
goto chooseDriversAndScripts)
if /i "%input%" equ "3" (set installMode=custom
goto preCustom)
echo  Invalid input, try again
goto mainMenuInput

:preCustom
cls
:Custom
echo.
echo  Select one:  (space needed to download/space used after install)
echo.
if /i "%allADKsInstalled%" neq "true" echo  1. Download and Install any missing ADKs and generate WinPE.wim images
if /i "%allADKsInstalled%" neq "true" echo  2. Download and Install any missing ADKs       (17GB / 8GB)
if /i "%ADK10installed%" neq "true" echo  3. Download and Install ADK 10_%ADK10version% (required) (9GB / 5 GB)
if /i "%ADK81Uinstalled%" neq "true" echo  4. Download and Install ADK 8.1 U              (5GB / 1.6GB)
if /i "%AIK7Installed%" neq "true" echo  5. Download and Install AIK 7                  (7GB / 1.3GB)
echo  6. Only Download ADK 10_%ADK10version% (latest)          (3.3-3.8GB)
echo  7. Only Download ADK 8.1 U                     (3GB)
echo  8. Only Download AIK 7                         (3GB)
echo  9. Only Download ADK 10_RTM              (3GB)
echo  10. Only Download ADK 10_1511            (3GB)
echo  11. Only Download ADK 10_1607            (3GB)
echo  12. Only Download ADK 10_1703            (3GB)
echo  13. Only Download ADK 10_1709            (3GB)
echo  0. Quit.

:customInput
set /p input=
if /i "%input%" equ "0" goto end
if /i "%input%" equ "1" (set customMode=All
goto chooseDriversAndScripts)
if /i "%input%" equ "2" (set buildImages=false
set customMode=All
goto forkPoint)
if /i "%input%" equ "3" (set buildImages=false
set customMode=DownloadAndInstallADK10
goto forkPoint)
if /i "%input%" equ "4" (set buildImages=false
set customMode=DownloadAndInstallADK81U
goto forkPoint)
if /i "%input%" equ "5" (set buildImages=false
set customMode=DownloadAndInstallAIK7
goto forkPoint)
if /i "%input%" equ "6" (set buildImages=false
et customMode=DownloadADK10
goto forkPoint)
if /i "%input%" equ "7" (set buildImages=false
set customMode=DownloadADK81U
goto forkPoint)
if /i "%input%" equ "8" (set buildImages=false
set customMode=DownloadAIK7
goto forkPoint)
if /i "%input%" equ "9" (set buildImages=false
set ADK10version=RTM
set customMode=DownloadADK10
goto forkPoint)
if /i "%input%" equ "10" (set buildImages=false
set ADK10version=1511
set customMode=DownloadADK10
goto forkPoint)
if /i "%input%" equ "11" (set buildImages=false
set ADK10version=1607
set customMode=DownloadADK10
goto forkPoint)
if /i "%input%" equ "12" (set buildImages=false
set ADK10version=1703
set customMode=DownloadADK10
goto forkPoint)
if /i "%input%" equ "13" (set buildImages=false
set ADK10version=1709
set customMode=DownloadADK10
goto forkPoint)
echo Invalid input, try again
goto customInput


:chooseDriversAndScripts
cls
echo.
echo   Should packages, drivers and scripts be integrated into the images?
echo   Select a number to toggle on/off.
echo.
echo   1. All drivers, scripts and packages should be integrated. (continue)
echo   2. Integrate Packages: "%integratePackages%"
echo   3. Integrate Drivers: "%integrateDrivers%"
echo   4. Integrate Scripts: "%integrateScripts%"
echo   5. No Packages, Drivers, or Scripts.
echo   6. Continue.
echo   C. Continue.
echo   0. Quit.

:chooseDriversAndScriptsInput
set /p input=
if /i "%input%" equ "0" goto end
if /i "%input%" equ "1" (set integratePackages=true
set integrateDrivers=true
set integrateScripts=true
goto forkPoint)
if /i "%input%" equ "2" (if /i "%integratePackages%" equ "true" (set integratePackages=false) else (set integratePackages=true)
goto chooseDriversAndScripts)
if /i "%input%" equ "3" (if /i "%integrateDrivers%" equ "true" (set integrateDrivers=false) else (set integrateDrivers=true)
goto chooseDriversAndScripts)
if /i "%input%" equ "4" (if /i "%integrateScripts%" equ "true" (set integrateScripts=false) else (set integrateScripts=true)
goto chooseDriversAndScripts)
if /i "%input%" equ "5" (set integratePackages=false
set integrateDrivers=false
set integrateScripts=false
goto chooseDriversAndScripts)
if /i "%input%" equ "6" goto forkPoint
if /i "%input%" equ "c" goto forkPoint
goto chooseDriversAndScripts

:forkPoint
::refresh variables in case older ADK was chosen for download
set ADK10Path=%ADKDownloadPath%\ADK10_%ADK10version%
set ADK10StagingExe=adksetup_%ADK10version%.exe

if /i "%installMode%" equ "simple" goto DownloadAndInstallADK10
if /i "%installMode%" equ "full" goto All
if /i "%installMode%" equ "custom" goto %customMode%
echo  unspecified error
goto end


::download and install all ADKs
:All
if /i "%AIK7Installed%" neq "true" call :AIK7Download
if /i "%AIK7Installed%" neq "true" call :AIK7Install
echo.
if /i "%ADK81Uinstalled%" neq "true" call :ADK81UDownload
if /i "%ADK81Uinstalled%" neq "true" call :ADK81UInstall
echo.
if /i "%ADK10installed%" neq "true" call :ADK10Download
if /i "%ADK10installed%" neq "true" call :ADK10Install
if /i "%buildImages%" equ "true" (goto generateWorkspace) else (goto end)

::download and install ADK10
:DownloadAndInstallADK10
if /i "%ADK10installed%" neq "true" call :ADK10Download
if /i "%ADK10installed%" neq "true" call :ADK10Install
if /i "%buildImages%" equ "true" (goto generateWorkspace) else (goto end)

::download and install ADK81U
:DownloadAndInstallADK81U
if /i "%ADK81Uinstalled%" neq "true" call :ADK81UDownload
if /i "%ADK81Uinstalled%" neq "true" call :ADK81UInstall
if /i "%buildImages%" equ "true" (goto generateWorkspace) else (goto end)

::download and install AIK7
:DownloadAndInstallAIK7
if /i "%AIK7Installed%" neq "true" call :AIK7Download
if /i "%AIK7Installed%" neq "true" call :AIK7Install
if /i "%buildImages%" equ "true" (goto generateWorkspace) else (goto end)

::download ADK10
:DownloadADK10
set downloadOnly=true
call :ADK10Download
goto end

::download ADK81U
:DownloadADK81U
set downloadOnly=true
call :ADK81UDownload
goto end

::download AIK7
:DownloadAIK7
set downloadOnly=true
call :AIK7Download
goto end


:generateWorkspace
set sourceScript=%resourcePath%\createWinPE.bat
set tempScript=%sourceScript%_temp_%random%.bat

echo. >"%tempScript%"
echo set integratePackages=%integratePackages%>>"%tempScript%"
echo set integrateDrivers=%integrateDrivers%>>"%tempScript%"
echo set integrateScripts=%integrateScripts%>>"%tempScript%"
type "%sourceScript%">>"%tempScript%"

"%tempScript%"


::start functions::

:AIK7Download
if not exist "%resourcePath%\%urlsFile%" (echo  Unable to find ADK 7 Download URLs.
goto :eof)

for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIK_CRC32=" %resourcePath%\%urlsFile%') do set Win7AIK_CRC32=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_CRC32=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_CRC32=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIK_URL=" %resourcePath%\%urlsFile%') do set Win7AIK_URL=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIK_URL2=" %resourcePath%\%urlsFile%') do set Win7AIK_URL2=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_URL=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_URL=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_URL2=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_URL2=%%i
if not defined Win7AIK_CRC32 (echo  Unable to find ADK 7 CRC32 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIKSupplement_CRC32 (echo  Unable to find ADK 7 Supplement CRC32 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIK_URL (echo  Unable to find ADK 7 Download URL in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIK_URL2 (echo  Unable to find ADK 7 Download URL2 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIKSupplement_URL (echo  Unable to find ADK 7 Supplement Download URL %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIKSupplement_URL2 (echo  Unable to find ADK 7 Supplement Download URL2 %resourcePath%\%urlsFile%
goto :eof)

set AIK7Hash=invalid
if exist "%AIK7Path%\%AIK7DetectionFile%" call :hashCheck "%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_CRC32%" crc32
if exist "%AIK7Path%\%AIK7DetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7DetectionFile%" "%AIK7DetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" set AIK7Hash=valid)


set AIK7SupplementHash=invalid
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" call :hashCheck "%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_CRC32%" crc32
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7SupplementDetectionFile%" "%AIK7SupplementDetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" set AIK7SupplementHash=valid)


if not exist "%AIK7Path%" mkdir "%AIK7Path%"

if /i "%AIK7Hash%" equ "valid" goto afterAIKDownload
:: --dir=  is probably a better than --out to allow the server to decide the target file name
echo.
echo  Downloading "%AIK7DetectionFile%"...
echo.
call "%toolsPath%\%architecture%\aria2\%aria2%" --file-allocation=none --out="%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_URL%"
if exist "%AIK7Path%\%AIK7DetectionFile%" call :hashCheck "%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_CRC32%" crc32
if exist "%AIK7Path%\%AIK7DetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7DetectionFile%" "%AIK7DetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" set AIK7Hash=valid
if /i "%hash%" equ "valid" goto afterAIKDownload)

if not exist "%AIK7Path%\%AIK7DetectionFile%" (echo.
echo  Downloading "%AIK7DetectionFile%"...
echo.
call "%toolsPath%\%architecture%\aria2\%aria2%" --file-allocation=none --out="%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_URL2%")
if exist "%AIK7Path%\%AIK7DetectionFile%" call :hashCheck "%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_CRC32%" crc32
if exist "%AIK7Path%\%AIK7DetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7DetectionFile%" "%AIK7DetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" set AIK7Hash=valid
if /i "%hash%" equ "valid" goto afterAIKDownload)
if not exist "%AIK7Path%\%AIK7DetectionFile%" (echo  Error downloading Win 7 AIK, please download manually from:
echo "%Win7AIK_URL%"
echo or
echo "%Win7AIK_URL2%"
goto :eof)
:afterAIKDownload

if /i "%AIK7SupplementHash%" equ "valid" goto :eof
echo.
echo  Downloading "%AIK7SupplementDetectionFile%"...
echo.
call "%toolsPath%\%architecture%\aria2\%aria2%" --file-allocation=none --out="%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_URL%"
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" call :hashCheck "%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_CRC32%" crc32
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7SupplementDetectionFile%" "%AIK7SupplementDetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" goto :eof)

if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo.
echo  Downloading "%AIK7SupplementDetectionFile%" again...
echo.
call "%toolsPath%\%architecture%\aria2\%aria2%" --file-allocation=none --out="%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_URL2%")
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" call :hashCheck "%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_CRC32%" crc32
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7SupplementDetectionFile%" "%AIK7SupplementDetectionFile%.corrupt.%random%.iso"
if /i "%hash%" equ "valid" goto :eof)

if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo  Error downloading Win 7 AIK Sup, please download manually
echo  "%Win7AIKSupplement_URL%"
echo   or
echo  "%Win7AIKSupplement_URL2%")
goto :eof


:AIK7Install
If /i "%downloadOnly%" equ "true" goto :eof
echo.
echo  Preparing to install AIK7...
if exist "%AIK7Path%\%AIK7DetectionFile%" call :hashCheck "%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_CRC32%" crc32
if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7DetectionFile%" "%AIK7DetectionFile%.corrupt.%random%.iso"
if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" call :hashCheck "%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_CRC32%" crc32
if /i "%hash%" neq "valid" ren "%AIK7Path%\%AIK7SupplementDetectionFile%" "%AIK7SupplementDetectionFile%.corrupt.%random%.iso"

if not exist "%AIK7Path%\%AIK7DetectionFile%" (echo  Win7AIK not yet downloaded, please download manually
echo "%Win7AIK_URL%"
echo or
echo "%Win7AIK_URL2%"
goto :eof)
if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo  Win7AIK Supplement not yet downloaded, please download manually
echo  "%Win7AIKSupplement_URL%"
echo   or
echo  "%Win7AIKSupplement_URL2%"
goto :eof)
if /i "%AIK7installed%" equ "true" (echo.
echo   AIK 7 already installed
goto :eof)


echo.
echo  Extracting AIK 7...
call "%toolsPath%\%architecture%\7z\%Sevenz%" x "%AIK7Path%\%AIK7DetectionFile%" -o"%AIK7Path%\%AIK7Folder%" -y -aoa
if not exist "%AIK7Path%\%AIK7Folder%\%AIK7InstallExe%" (echo  failed to extract AIK for Win7, please install it manually
goto :eof)
::@echo on

::start automation script
start "" "%resourcePath%\scripts\setup\InstallAIK.exe"
echo.
echo  AIK 7 must be installed with a full UI, please go Next-^>Next-^>Next
echo.
::wait 4 seconds for it to start
ping localhost -n 4 >nul
call "%AIK7Path%\%AIK7Folder%\%AIK7InstallExe%"
call :detectAIK7
if /i "%AIK7Installed%" neq "true" (echo   AIK 7 not installed, please install it manually
goto :eof)

echo.
echo   Extracting AIK 7 Supplement...
call "%toolsPath%\%architecture%\7z\%Sevenz%" x "%AIK7Path%\%AIK7SupplementDetectionFile%" -o"%AIK7Path%\%AIK7SupplementFolder%" -y -aoa
if not exist "%AIK7Path%\%AIK7SupplementFolder%\%AIK7SupplementExtractedDetectionFile%" (echo  failed to extract AIK7 Supplement, please install it manually
goto :eof)

echo   Updating AIK 7 with supplement...
echo robocopy "%cd%\%AIK7Path%\%AIK7SupplementFolder%" "%AIK7InstallPath%\Tools\PETools" /e /move
robocopy "%cd%\%AIK7Path%\%AIK7SupplementFolder%" "%AIK7InstallPath%\Tools\PETools" /e /move
::xcopy E:\ "C:\Program Files\Windows AIK\Tools\PETools" /ERDY
echo.
echo   Finished updating AIK 7 with supplement

::if not exist "%archivePath%\%shortcutsArchive%" goto :eof
::if not exist "%resourcePath%\shortcuts" mkdir "%resourcePath%\shortcuts"
::call "%toolsPath%\%architecture%\7z\%Sevenz%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aoa
::if /i "%architecture%" equ "x86" (copy "%resourcePath%\shortcuts\x86\Win 7 Deployment Tools Command Prompt.lnk" "%userprofile%\desktop\Win 7 Deployment Tools Command Prompt.lnk" /y
::copy "%resourcePath%\shortcuts\x86\Win 7 Deployment Tools Command Prompt.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 7 Deployment Tools Command Prompt.lnk" /y)
::if /i "%architecture%" equ "x64" (copy "%resourcePath%\shortcuts\x64\Win 7 Deployment Tools Command Prompt.lnk" "%userprofile%\desktop\Win 7 Deployment Tools Command Prompt.lnk" /y
::copy "%resourcePath%\shortcuts\x64\Win 7 Deployment Tools Command Prompt.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 7 Deployment Tools Command Prompt.lnk" /y)
::cleanup
if exist "%AIK7Path%\%AIK7Folder%" rmdir /s /q "%AIK7Path%\%AIK7Folder%"
if exist "%AIK7Path%\%AIK7SupplementFolder%" rmdir /s /q "%AIK7Path%\%AIK7SupplementFolder%"
goto :eof


:ADK81UDownload
if not exist "%resourcePath%\%urlsFile%" (echo  Unable to find ADK 8.1U Download URLs
goto :eof)
for /f "tokens=1* delims==" %%i in ('find /i "Win81UADK_URL=" %resourcePath%\%urlsFile%') do set Win81UADK_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win81UADK_URL2=" %resourcePath%\%urlsFile%') do set Win81UADK_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win81UADK_CRC32=" %resourcePath%\%urlsFile%') do set Win81UADK_CRC32=%%j
if not defined Win81UADK_URL (echo  Unable to find ADK 8.1U download URL in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win81UADK_URL2 (echo  Unable to find ADK 8.1U download URL2 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win81UADK_CRC32 (echo  Unable to find ADK 8.1U CRC32 in %resourcePath%\%urlsFile%
goto :eof)

if exist "%ADK81UPath%\%ADK81UDetectionFolder%" (echo   ADK 8.1 U already downloaded at
echo   "%cd%\%ADK81UPath%"
goto :eof)

echo.
echo   Downloading ADK 8.1U "%toolsPath%\%ADK81UStagingExe%"...
if exist "%toolsPath%\%ADK81UStagingExe%" call :hashCheck "%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_CRC32%" crc32
if exist "%toolsPath%\%ADK81UStagingExe%" (if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK81UStagingExe%" "%toolsPath%\%ADK81UStagingExe%.corrupt.%random%.msi"
if /i "%hash%" equ "valid" goto afterDownloadingADK81UStagingExe)
if not exist "%toolsPath%\%ADK81UStagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_URL%"
if exist "%toolsPath%\%ADK81UStagingExe%" call :hashCheck "%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_CRC32%" crc32
if exist "%toolsPath%\%ADK81UStagingExe%" (if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK81UStagingExe%" "%toolsPath%\%ADK81UStagingExe%.corrupt.%random%.msi"
if /i "%hash%" equ "valid" goto afterDownloadingADK81UStagingExe)
if not exist "%toolsPath%\%ADK81UStagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_URL2%"
if exist "%toolsPath%\%ADK81UStagingExe%" call :hashCheck "%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_CRC32%" crc32
if exist "%toolsPath%\%ADK81UStagingExe%" if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK81UStagingExe%" "%toolsPath%\%ADK81UStagingExe%.corrupt.%random%.msi"
:afterDownloadingADK81UStagingExe

if not exist "%toolsPath%\%ADK81UStagingExe%" (echo   Error downloading ADK 8.1U "%toolsPath%\%ADK81UStagingExe%", please download it manually from
echo   %Win81UADK_URL%
echo   or
echo   %Win81UADK_URL2%
goto :eof)

echo.
echo    Please wait, Downloading ADK 81 U (3GB will take a while)...
echo    Check Resource Monitor-^>Network for transfer speed
if not exist "%ADK81UPath%" mkdir "%ADK81UPath%"

call "%toolsPath%\%ADK81UStagingExe%" /layout "%ADK81UPath%" /q /ceip off
if not exist "%ADK81UPath%\%ADK81UDetectionFolder%" echo Error downloading ADK 8.1U, please download it manually
::how can checking if the download was successful be made more robust?
goto :eof


:ADK81UInstall
if /i "%downloadOnly%" equ "true" goto :eof
if /i "%ADK81Uinstalled%" equ "true" (echo   ADK 81 U already installed
goto :eof)
if not exist "%ADK81UPath%\%ADK81UDetectionFolder%" (echo ADK 81 U not downloaded
goto :eof)
echo.
echo    Please wait, installing ADK 8.1Update (will take a while)...

::need to verify staging exe first
call "%ADK81UPath%\%ADK81UInstallExe%" /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment /ceip off /q

call :detectADK81UandADK10
if /i "%ADK81UInstalled%" neq "true" (echo   ADK 81 U did not install sucessfully, please install it manually
goto :eof)
if /i "%ADK81UInstalled%" equ "true" (echo.
echo   ADK 81 U Installed Sucessfully)

if not exist "%archivePath%\%shortcutsArchive%" goto :eof
if not exist "%resourcePath%\shortcuts" mkdir "%resourcePath%\shortcuts"
call "%toolsPath%\%architecture%\7z\%Sevenz%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aoa
copy "%resourcePath%\shortcuts\x86\Win 8.1 Update Deployment and Tools Environment.lnk" "%cd%\Win 8.1 Update Deployment and Tools Environment.lnk" /y
if /i "%architecture%" equ "x86" (copy "%resourcePath%\shortcuts\x86\Win 8.1 Update Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 8.1 Update Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x86\Win 8.1 Update Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 8.1 Update Deployment and Tools Environment.lnk" /y)
if /i "%architecture%" equ "x64" (copy "%resourcePath%\shortcuts\x64\Win 8.1 Update Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 8.1 Update Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x64\Win 8.1 Update Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 8.1 Update Deployment and Tools Environment.lnk" /y)
goto :eof


:ADK10Download
if not exist "%resourcePath%\%urlsFile%" (echo  Unable to find ADK 10_%ADK10version% Download URLs
goto :eof)
for /f "tokens=1* delims==" %%i in ('find /i "Win10ADK_%ADK10version%_URL=" %resourcePath%\%urlsFile%') do set Win10ADK_%ADK10version%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win10ADK_%ADK10version%_URL2=" %resourcePath%\%urlsFile%') do set Win10ADK_%ADK10version%_URL2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win10ADK_%ADK10version%_CRC32=" %resourcePath%\%urlsFile%') do set Win10ADK_%ADK10version%_CRC32=%%j
if not defined Win10ADK_%ADK10version%_URL (echo  Unable to find ADK 10_%ADK10version% download URL in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win10ADK_%ADK10version%_URL2 (echo  Unable to find ADK 10_%ADK10version% download URL2 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win10ADK_%ADK10version%_CRC32 (echo  Unable to find ADK 10_%ADK10version% crc32 in %resourcePath%\%urlsFile%
goto :eof)

if exist "%ADK10Path%\%ADK10DetectionFolder%" (echo.
echo   ADK 10_%ADK10version% already downloaded at
echo   "%cd%\%ADK10Path%"
goto :eof)

echo.
echo   Downloading ADK 10_%ADK10version% "%toolsPath%\%ADK10StagingExe%"...
if exist "%toolsPath%\%ADK10StagingExe%" call :hashCheck "%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_CRC32!" crc32
if exist "%toolsPath%\%ADK10StagingExe%" (if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK10StagingExe%" "%toolsPath%\%ADK10StagingExe%.corrupt.%random%.msi"
if /i "%hash%" equ "valid" goto afterDownloadingADK10StagingExe)
if not exist "%toolsPath%\%ADK10StagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_URL!"
if exist "%toolsPath%\%ADK10StagingExe%" call :hashCheck "%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_CRC32!" crc32
if exist "%toolsPath%\%ADK10StagingExe%" (if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK10StagingExe%" "%toolsPath%\%ADK10StagingExe%.corrupt.%random%.msi"
if /i "%hash%" equ "valid" goto afterDownloadingADK10StagingExe)
if not exist "%toolsPath%\%ADK10StagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_URL2!"
if exist "%toolsPath%\%ADK10StagingExe%" call :hashCheck "%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_CRC32!" crc32
if exist "%toolsPath%\%ADK10StagingExe%" if /i "%hash%" neq "valid" ren "%toolsPath%\%ADK10StagingExe%" "%toolsPath%\%ADK10StagingExe%.corrupt.%random%.msi"
:afterDownloadingADK10StagingExe

if not exist "%toolsPath%\%ADK10StagingExe%" (echo   Error downloading ADK 10_%ADK10version% "%toolsPath%\%ADK10StagingExe%", please download it manually from
echo   !Win10UADK_%ADK10version%_URL!
echo   or
echo   !Win10UADK_%ADK10version%_URL2!
goto :eof)

echo    Please wait, Downloading ADK 10 (3.3-4GB will take a while)...
echo    Check Resource Monitor-^>Network for transfer speed
if not exist "%ADK10Path%" mkdir "%ADK10Path%"

call "%toolsPath%\%ADK10StagingExe%" /layout "%ADK10Path%" /q /ceip off
if not exist "%ADK10Path%\%ADK10DetectionFolder%" echo Error downloading ADK 10, please download it manually
goto :eof


:ADK10Install
If /i "%downloadOnly%" equ "true" goto :eof
if /i "%ADK10installed%" equ "true" (echo.
echo   ADK 10 already installed
goto :eof)
if not exist "%ADK10Path%\%ADK10DetectionFolder%" (echo ADK 10 not downloaded
goto :eof)
echo.
echo    Please wait, installing ADK 10_%ADK10version% (will take a while)...
echo.

::need to verify staging exe first
call "%ADK10Path%\%ADK10InstallExe%" /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment /ceip off /q

call :detectADK81UandADK10
if /i "%ADK10Installed%" neq "true" (echo   ADK 10_%ADK10version% did not install sucessfully, please install it manually
goto :eof)
if /i "%ADK10Installed%" equ "true" echo   ADK 10 Installed Sucessfully

if not exist "%archivePath%\%shortcutsArchive%" goto :eof
if not exist "%resourcePath%\shortcuts" mkdir "%resourcePath%\shortcuts"
call "%toolsPath%\%architecture%\7z\%Sevenz%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aoa
copy "%resourcePath%\shortcuts\x86\Win 10 Deployment and Tools Environment.lnk" "%cd%\Win 10_%ADK10version% Deployment and Tools Environment.lnk" /y
if /i "%architecture%" equ "x86" (copy "%resourcePath%\shortcuts\x86\Win 10 Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 10_%ADK10version% Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x86\Win 10 Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 10_%ADK10version% Deployment and Tools Environment.lnk" /y)
if /i "%architecture%" equ "x64" (copy "%resourcePath%\shortcuts\x64\Win 10 Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 10_%ADK10version% Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x64\Win 10 Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 10_%ADK10version% Deployment and Tools Environment.lnk" /y)
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
"%toolsPath%\%architecture%\7z\%Sevenz%" h -scrc%hashtype% "%~1">%tempfile%

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


:end
