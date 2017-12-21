@echo off

::set defaults
::detect any installed ADKs
::present download and download+install options for non-installed ADKs
::download selected ADK, 
::go to install, and abort if not requested

pushd "%~dp0"
set ADKDownloadPath=WindowsADKs
set ADK10version=latest
::latest, RTM, 1511, 1607, 1703, 1709


set resourcePath=resources
set toolsPath=%resourcePath%\tools
set archivePath=%resourcePath%\archives
set urlsFile=urls_debug.txt

set sevenZ=7z.exe
set aria2=aira2c.exe

set shortcutsArchive=shortcuts.zip
set AIK7Path=%ADKDownloadPath%\AIK7
set ADK81UPath=%ADKDownloadPath%\ADK81U

if /i "ADK10version" equ "latest" for /f "skip=2 eol=: delims== tokens=1-10" %%i in ('find /i "Win10ADK_latest=" %urlsFile%') do if /i "%%j" neq "" set ADK10version=%%j
if /i "ADK10version" equ "latest" (echo  unable to determine latest ADK10 version using %resourcePath%\%urlsFile%
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
if /i "%~1" equ "1" goto One
if /i "%~1" equ "2" goto Two
if /i "%~1" equ "3" goto Three
if /i "%~1" equ "4" goto Four
if /i "%~1" equ "5" goto Five
if /i "%~1" equ "6" goto Six
if /i "%~1" equ "7" goto Seven

::get user input
echo.
echo.
if /i "%AIK7Installed%" equ "true" echo  Detected AIK 7 installation at %AIK7InstallPath%
if /i "%AIK7Installed%" neq "true" echo  AIK 7 not installed
if /i "%ADK81Uinstalled%" equ "true" echo  Detected ADK 8.1 U installation at %ADK81Uinstallpath%
if /i "%ADK81Uinstalled%" neq "true" echo  ADK 8.1 U not installed
if /i "%ADK10installed%" equ "true" echo  Detected ADK 10 installation at %ADK10installpath%
if /i "%ADK10installed%" neq "true" echo  ADK 10 not installed
echo.
echo  Enter one of the following: (space needed to install/space used after install)
echo.
echo  0. To quit.
if /i "%allADKsInstalled%" neq "true" echo  1. Download and Install any missing ADKs (17GB / 6GB)
if /i "%AIK7Installed%" neq "true" echo  2. Download and Install AIK 7            (7GB / 1.3GB)
if /i "%ADK81Uinstalled%" neq "true" echo  3. Download and Install ADK 8.1 U        (5GB / 1.6GB)
if /i "%ADK10installed%" neq "true" echo  4. Download and Install ADK 10           (6GB / 2.5 GB)
echo  5. Only Download AIK 7                   (3GB)
echo  6. Only Download ADK 8.1 U               (3GB)
echo  7. Only Download ADK 10_%ADK10version%              (3.3-4GB)


:startInput
set /p input=
if /i "%input%" equ "0" goto end
if /i "%input%" equ "1" goto One
if /i "%input%" equ "2" goto Two
if /i "%input%" equ "3" goto Three
if /i "%input%" equ "4" goto Four
if /i "%input%" equ "5" goto Five
if /i "%input%" equ "6" goto Six
if /i "%input%" equ "7" goto Seven
echo Invalid input, try again
goto startInput

::download and install all ADKs
:One
if /i "%AIK7Installed%" neq "true" call :AIK7Download
call :AIK7Install
echo.
if /i "%ADK81UInstalled%" neq "true" call :ADK81UDownload
call :ADK81UInstall
echo.
if /i "%ADK10Installed%" neq "true" call :ADK10Download
call :ADK10Install

goto end

::download and install AIK7
:Two
if /i "%AIK7Installed%" neq "true" call :AIK7Download
call :AIK7Install
goto end

::download and install ADK81U
:Three
if /i "%ADK81UInstalled%" neq "true" call :ADK81UDownload
call :ADK81UInstall
goto end

::download and install ADK10
:Four
if /i "%ADK10Installed%" neq "true" call :ADK10Download
call :ADK10Install
goto end

::download AIK7
:Five
set downloadOnly=true
call :AIK7Download
goto end

::download ADK81U
:Six
set downloadOnly=true
call :ADK81UDownload
goto end

::download ADK10
:Seven
set downloadOnly=true
call :ADK10Download
goto end



::start functions::


:AIK7Download
if exist "%AIK7Path%\%AIK7DetectionFile%" if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo   Win7AIK and Supplement already downloaded at
echo   "%cd%\%AIK7Path%\%AIK7DetectionFile%" 
echo   "%cd%\%AIK7Path%\%AIK7SupplementDetectionFile%"
goto :eof)

if not exist "%resourcePath%\%urlsFile%" (echo  Unable to find ADK 7 Download URLs
goto :eof)
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIK_URL=" %resourcePath%\%urlsFile%') do set Win7AIK_URL=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_URL=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_URL=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_URL2=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_URL2=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIK_CRC32=" %resourcePath%\%urlsFile%') do set Win7AIK_CRC32=%%i
for /f "skip=2 tokens=2 delims==" %%i in ('find /i "Win7AIKSupplement_CRC32=" %resourcePath%\%urlsFile%') do set Win7AIKSupplement_CRC32=%%i
if not defined Win7AIK_URL (echo  Unable to find ADK 7 Download URL in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIK_CRC32 (echo  Unable to find ADK 7 CRC32 in %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIKSupplement_URL (echo  Unable to find ADK 7 Supplement Download URL %resourcePath%\%urlsFile%
goto :eof)
if not defined Win7AIKSupplement_CRC32 (echo  Unable to find ADK 7 Supplement CRC32 in %resourcePath%\%urlsFile%
goto :eof)

if not exist "%AIK7Path%" mkdir "%AIK7Path%"
if exist "%AIK7Path%\%AIK7DetectionFile%" goto afterAIKDownload
:: --dir=  is prolly a better alternative to --out
call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_URL%"
if not exist "%AIK7Path%\%AIK7DetectionFile%" (echo  Error downloading Win 7 AIK, please download manually
echo "%Win7AIK_URL%"
goto :eof)
call :hashCheck "%AIK7Path%\%AIK7DetectionFile%" "%Win7AIK_CRC32%" crc32
if /i "%hash%" neq "valid" (echo  Error downloading Win 7 AIK, please download manually
echo "%Win7AIK_URL%"
goto :eof)
:afterAIKDownload

if exist "%AIK7Path%\%AIK7SupplementDetectionFile%" goto :eof
call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_URL%"
if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_URL2%"
if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo  Error downloading Win 7 AIK Sup, please download manually
echo "%Win7AIKSupplement_URL%")
call :hashCheck "%AIK7Path%\%AIK7SupplementDetectionFile%" "%Win7AIKSupplement_CRC32%" crc32
if /i "%hash%" neq "valid" (echo  Error downloading Win 7 AIK Sup, please download manually
echo "%Win7AIKSupplement_URL%")
goto :eof


:AIK7Install
If /i "%downloadOnly%" equ "true" goto :eof
if not exist "%AIK7Path%\%AIK7DetectionFile%" if not exist "%AIK7Path%\%AIK7SupplementDetectionFile%" (echo  Win7AIK and Supplement not yet downloaded
goto :eof)
if /i "%AIK7installed%" equ "true" (echo   AIK 7 already installed
goto :eof)

echo.
echo  extracting AIK 7...
call "%toolsPath%\%architecture%\7z\%sevenZ%" x "%AIK7Path%\%AIK7DetectionFile%" -o"%AIK7Path%\%AIK7Folder%" -y -aos
if not exist "%AIK7Path%\%AIK7Folder%\%AIK7InstallExe%" (echo  failed to extract AIK for Win7, please install it manually
goto :eof)
::@echo on
echo.
echo  AIK 7 must be installed with a full UI, please go Next-^>Next-^>Next
echo.
call "%AIK7Path%\%AIK7Folder%\%AIK7InstallExe%"
call :detectAIK7
if /i "%AIK7Installed%" neq "true" (echo   AIK 7 not installed, please install it manually
goto :eof)

echo.
echo   Finished updating AIK 7 with supplement
echo.
echo   Extracting AIK 7 Supplement...
call "%toolsPath%\%architecture%\7z\%sevenZ%" x "%AIK7Path%\%AIK7SupplementDetectionFile%" -o"%AIK7Path%\%AIK7SupplementFolder%" -y -aos
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
::call "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aos
::if /i "%architecture%" equ "x86" (copy "%resourcePath%\shortcuts\x86\Win 7 Deployment Tools Command Prompt.lnk" "%userprofile%\desktop\Win 7 Deployment Tools Command Prompt.lnk" /y
::copy "%resourcePath%\shortcuts\x86\Win 7 Deployment Tools Command Prompt.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 7 Deployment Tools Command Prompt.lnk" /y)
::if /i "%architecture%" equ "x64" (copy "%resourcePath%\shortcuts\x64\Win 7 Deployment Tools Command Prompt.lnk" "%userprofile%\desktop\Win 7 Deployment Tools Command Prompt.lnk" /y
::copy "%resourcePath%\shortcuts\x64\Win 7 Deployment Tools Command Prompt.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 7 Deployment Tools Command Prompt.lnk" /y)
::cleanup
if exist "%AIK7Path%\%AIK7Folder%" rmdir /s /q "%AIK7Path%\%AIK7Folder%"
if exist "%AIK7Path%\%AIK7SupplementFolder%" rmdir /s /q "%AIK7Path%\%AIK7SupplementFolder%"
goto :eof


:ADK81UDownload
if exist "%ADK81UPath%\%ADK81UDetectionFolder%" (echo   ADK 8.1 U already downloaded at
echo   "%cd%\%ADK81UPath%"
goto :eof)

echo    Please wait, Downloading ADK 81 U (3GB will take a while)...
echo    Check Resource Monitor-^>Network for transfer speed
if not exist "%ADK81UPath%" mkdir "%ADK81UPath%"
for /f "tokens=1* delims==" %%i in ('find /i "Win81UADK_URL=" %resourcePath%\%urlsFile%') do set Win81UADK_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win81UADK_URL2=" %resourcePath%\%urlsFile%') do set Win81UADK_URL2=%%j
call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_URL%"
if not exist "%toolsPath%\%ADK81UStagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out="%toolsPath%\%ADK81UStagingExe%" "%Win81UADK_URL2%"
if not exist "%toolsPath%\%ADK81UStagingExe%"(echo   Error downloading ADK 8.1U %toolsPath%\%ADK81UStagingExe% , please download it manually from
echo   %Win81UADK_URL%
echo   or
echo   %Win81UADK_URL2%
goto :eof)
::need to check crc32 of staging file here

call "%toolsPath%\%ADK81UStagingExe%" /layout "%ADK81UPath%" /q /ceip off
if not exist "%ADK81UPath%\%ADK81UDetectionFolder%" echo Error downloading ADK 8.1U, please download it manually
goto :eof


:ADK81UInstall
If /i "%downloadOnly%" equ "true" goto :eof
if /i "%ADK81Uinstalled%" equ "true" (echo   ADK 81 U already installed
goto :eof)
if not exist "%ADK81UPath%\%ADK81UDetectionFolder%" (echo ADK 81 U not downloaded
goto :eof)
echo    Please wait, installing ADK 8.1Update (will take a while)...

call "%ADK81UPath%\%ADK81UInstallExe%" /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment /ceip off /q

call :detectADK81UandADK10
if /i "%ADK81UInstalled%" neq "true" (echo   ADK 81 U did not install sucessfully, please install it manually
goto :eof)
if /i "%ADK81UInstalled%" equ "true" echo   ADK 81 U Installed Sucessfully

if not exist "%archivePath%\%shortcutsArchive%" goto :eof
if not exist "%resourcePath%\shortcuts" mkdir "%resourcePath%\shortcuts"
call "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aos
copy "%resourcePath%\shortcuts\x86\Win 81 Deployment and Tools Environment.lnk" "%cd%\Win 81 Deployment and Tools Environment.lnk" /y
if /i "%architecture%" equ "x86" (copy "%resourcePath%\shortcuts\x86\Win 81 Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 81 Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x86\Win 81 Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 81 Deployment and Tools Environment.lnk" /y)
if /i "%architecture%" equ "x64" (copy "%resourcePath%\shortcuts\x64\Win 81 Deployment and Tools Environment.lnk" "%userprofile%\desktop\Win 81 Deployment and Tools Environment.lnk" /y
copy "%resourcePath%\shortcuts\x64\Win 81 Deployment and Tools Environment.lnk" "%programdata%\Microsoft\Windows\Start Menu\Programs\Win 81 Deployment and Tools Environment.lnk" /y)
goto :eof


:ADK10Download
if exist "%ADK10Path%\%ADK10DetectionFolder%" (echo   ADK 10 already downloaded at
echo   "%cd%\%ADK10Path%"
goto :eof)

echo    Please wait, Downloading ADK 10 (3.3-4GB will take a while)...
echo    Check Resource Monitor-^>Network for transfer speed
if not exist "%ADK10Path%" mkdir "%ADK10Path%"

for /f "tokens=1* delims==" %%i in ('find /i "Win10ADK_%ADK10version%_URL=" %resourcePath%\%urlsFile%') do set Win10ADK_%ADK10version%_URL=%%j
for /f "tokens=1* delims==" %%i in ('find /i "Win10ADK_%ADK10version%_URL2=" %resourcePath%\%urlsFile%') do set Win10ADK_%ADK10version%_URL2=%%j
call "%toolsPath%\%architecture%\aria2\%aria2%" --out "%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_URL!"
if not exist "%toolsPath%\%ADK10StagingExe%" call "%toolsPath%\%architecture%\aria2\%aria2%" --out "%toolsPath%\%ADK10StagingExe%" "!Win10ADK_%ADK10version%_URL2!"
if not exist "%toolsPath%\%ADK10StagingExe%"(echo   Error downloading ADK 10_%ADK10version% %toolsPath%\%ADK10StagingExe% , please download it manually from
echo   !Win10ADK_%ADK10version%_URL!
echo   or
echo   !Win10ADK_%ADK10version%_URL2!
goto :eof)
::need to check crc32 of staging file

call "%toolsPath%\%ADK10StagingExe%" /layout "%ADK10Path%" /q /ceip off
if not exist "%ADK10Path%\%ADK10DetectionFolder%" echo Error downloading ADK 10, please download it manually
goto :eof


:ADK10Install
If /i "%downloadOnly%" equ "true" goto :eof
if /i "%ADK10installed%" equ "true" (echo   ADK 10 already installed
goto :eof)
if not exist "%ADK10Path%\%ADK10DetectionFolder%" (echo ADK 10 not downloaded
goto :eof)
echo    Please wait, installing ADK 10_%ADK10version% (will take a while)...

call "%ADK10Path%\%ADK10InstallExe%" /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment /ceip off /q

call :detectADK81UandADK10
if /i "%ADK10Installed%" neq "true" (echo   ADK 10_%ADK10version% did not install sucessfully, please install it manually
goto :eof)
if /i "%ADK10Installed%" equ "true" echo   ADK 10 Installed Sucessfully

if not exist "%archivePath%\%shortcutsArchive%" goto :eof
if not exist "%resourcePath%\shortcuts" mkdir "%resourcePath%\shortcuts"
call "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%shortcutsArchive%" -o"%resourcePath%" -y -aos
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


:end
