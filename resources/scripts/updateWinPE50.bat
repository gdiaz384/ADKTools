@echo off
setlocal enabledelayedexpansion

::download files
::hash check them
::abort if any hash check fails
::mount 5.0
::update winpe 5->5.1
::capture image
::if captured to originalwim\winpe51.wim sucessfully, delete sources\boot.wim
::unmount and discard
::copy 5.1 over sources\boot.wim

::change these 3 paths to be valid
set resourcePath=resources
set downloadPath=%resourcePath%\..\win81UpdateMSUs
set workspaceDest=.

set toolsPath=%resourcePath%\tools
set sevenZ=7z.exe
set aria=aria2c.exe
set urlstxt=urls.txt

set x86mountDir=%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\mount
set x64mountDir=%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\mount
set logfile=%temp%\winPE50upgrade%random%.log
set description=WinPE51
set ADKDeploymentToolsPath=Assessment and Deployment Kit\Deployment Tools
set ADKsetEnvScript=DandISetEnv.bat

if /i "%processor_architecture%" equ "x86" set architecture=x86
if /i "%processor_architecture%" equ "AMD64" set architecture=x64
if not defined architecture (echo    Error: architecture %processor_architecture% not supported
goto end)

set x86MSUsAvailable=true
set x64MSUsAvailable=true

call :detectADK81UandADK10
cls

if not exist "%downloadPath%" mkdir "%downloadPath%"
call :readMSUs

::downloadMSUs
::if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" goto afterDownloadingMSUs
if exist "%downloadPath%\%update6_x86%" goto afterDownloadingx86MSUs

for /l %%i in (0,1,6) do call "%toolsPath%\%architecture%\aria2\%aria%" "!update%%i_x86_url!" --dir="%cd%\%downloadPath%"

::check hashes 1
call :hashCheck "%downloadPath%\%update0_x86%" "%update0_x86_crc32%" crc32
echo hash: %hash%
if /i "!hash!" neq "valid" del "%downloadPath%\%update0_x86%"
call :hashCheck "%downloadPath%\%update1_x86%" "%update1_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update1_x86%"
call :hashCheck "%downloadPath%\%update2_x86%" "%update2_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update2_x86%"
call :hashCheck "%downloadPath%\%update3_x86%" "%update3_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update3_x86%"
call :hashCheck "%downloadPath%\%update4_x86%" "%update4_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update4_x86%"
call :hashCheck "%downloadPath%\%update5_x86%" "%update5_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update5_x86%"
call :hashCheck "%downloadPath%\%update6_x86%" "%update6_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update6_x86%"

if not exist "%downloadPath%\%update0_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update0_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update1_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update1_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update2_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update2_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update3_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update3_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update4_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update4_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update5_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update5_x86_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update6_x86%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update6_x86_url2%" --dir="%cd%\%downloadPath%"

::check hashes 2
call :hashCheck "%downloadPath%\%update0_x86%" "%update0_x86_crc32%" crc32
echo hash: %hash%
if /i "!hash!" neq "valid" del "%downloadPath%\%update0_x86%"
call :hashCheck "%downloadPath%\%update1_x86%" "%update1_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update1_x86%"
call :hashCheck "%downloadPath%\%update2_x86%" "%update2_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update2_x86%"
call :hashCheck "%downloadPath%\%update3_x86%" "%update3_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update3_x86%"
call :hashCheck "%downloadPath%\%update4_x86%" "%update4_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update4_x86%"
call :hashCheck "%downloadPath%\%update5_x86%" "%update5_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update5_x86%"
call :hashCheck "%downloadPath%\%update6_x86%" "%update6_x86_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update6_x86%"

if not exist "%downloadPath%\%update0_x86%" (echo   "%update0_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update1_x86%" (echo   "%update1_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update2_x86%" (echo   "%update2_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update3_x86%" (echo   "%update3_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update4_x86%" (echo   "%update4_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update5_x86%" (echo   "%update5_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)
if not exist "%downloadPath%\%update6_x86%" (echo   "%update6_x86%" not found at "%downloadPath%"
set x86MSUsAvailable=false)

:afterDownloadingx86MSUs

if exist "%downloadPath%\%update6_x64%" goto afterDownloadingx64MSUs

for /l %%i in (0,1,6) do call "%toolsPath%\%architecture%\aria2\%aria%" "!update%%i_x64_url!" --dir="%cd%\%downloadPath%"

::check hashes 3
call :hashCheck "%downloadPath%\%update0_x64%" "%update0_x64_crc32%" crc32
echo hash: %hash%
if /i "!hash!" neq "valid" del "%downloadPath%\%update0_x64%"
call :hashCheck "%downloadPath%\%update1_x64%" "%update1_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update1_x64%"
call :hashCheck "%downloadPath%\%update2_x64%" "%update2_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update2_x64%"
call :hashCheck "%downloadPath%\%update3_x64%" "%update3_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update3_x64%"
call :hashCheck "%downloadPath%\%update4_x64%" "%update4_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update4_x64%"
call :hashCheck "%downloadPath%\%update5_x64%" "%update5_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update5_x64%"
call :hashCheck "%downloadPath%\%update6_x64%" "%update6_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update6_x64%"

if not exist "%downloadPath%\%update0_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update0_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update1_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update1_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update2_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update2_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update3_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update3_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update4_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update4_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update5_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update5_x64_url2%" --dir="%cd%\%downloadPath%"
if not exist "%downloadPath%\%update6_x64%" call "%toolsPath%\%architecture%\aria2\%aria%" "%update6_x64_url2%" --dir="%cd%\%downloadPath%"

::check hashes 4
call :hashCheck "%downloadPath%\%update0_x64%" "%update0_x64_crc32%" crc32
echo hash: %hash%
if /i "!hash!" neq "valid" del "%downloadPath%\%update0_x64%"
call :hashCheck "%downloadPath%\%update1_x64%" "%update1_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update1_x64%"
call :hashCheck "%downloadPath%\%update2_x64%" "%update2_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update2_x64%"
call :hashCheck "%downloadPath%\%update3_x64%" "%update3_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update3_x64%"
call :hashCheck "%downloadPath%\%update4_x64%" "%update4_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update4_x64%"
call :hashCheck "%downloadPath%\%update5_x64%" "%update5_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update5_x64%"
call :hashCheck "%downloadPath%\%update6_x64%" "%update6_x64_crc32%" crc32
echo hash: %hash%
if /i "%hash%" neq "valid" del "%downloadPath%\%update6_x64%"

if not exist "%downloadPath%\%update0_x64%" (echo   "%update0_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update1_x64%" (echo   "%update1_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update2_x64%" (echo   "%update2_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update3_x64%" (echo   "%update3_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update4_x64%" (echo   "%update4_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update5_x64%" (echo   "%update5_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)
if not exist "%downloadPath%\%update6_x64%" (echo   "%update6_x64%" not found at "%downloadPath%"
set x64MSUsAvailable=false)

:afterDownloadingx64MSUs


::Alright, so all of them downloaded successfully and are available. Now to mount and update the images.
pushd "%cd%"
call "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
popd

if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" goto afterUpdatingPE50x86
if /i "%x86MSUsAvailable%" neq "true" goto afterUpdatingPE50x86

dism /Mount-Image /ImageFile:"%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe50.wim" /index:1 /MountDir:"%x86mountDir%"

for /l %%i in (0,1,6) do dism /Add-Package /PackagePath:"%downloadPath%\!update%%i_x86!" /Image:"%x86mountDir%" /LogPath:"%logfile%"

::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919442-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919355-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2932046-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2934018-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2937592-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2938439-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2959977-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log

dism /image:"%x86mountDir%" /Cleanup-Image /StartComponentCleanup /ResetBase

dism /capture-image /imagefile:"%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" /capturedir:"%x86mountDir%" /name:"%description%x86" /description:"%description%x86" /compress:max /bootable

dism /Unmount-Image /MountDir:"%x86mountDir%" /discard
:afterUpdatingPE50x86


if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe51.wim" goto afterUpdatingPE50x64
if /i "%x64MSUsAvailable%" neq "true" goto end

dism /Mount-Image /ImageFile:"%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe50.wim" /index:1 /MountDir:"%x64mountDir%"

for /l %%i in (0,1,6) do dism /Add-Package /PackagePath:"%downloadPath%\!update%%i_x64!" /Image:"%x64mountDir%" /LogPath:"%logfile%"

dism /image:"%x64mountDir%" /Cleanup-Image /StartComponentCleanup /ResetBase

dism /capture-image /imagefile:"%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe51.wim" /capturedir:%x64mountDir% /name:"%description%x64" /description:"%description%x64" /compress:max /bootable

dism /Unmount-Image /MountDir:"%x64mountDir%" /discard
:afterUpdatingPE50x64


::now need to copy over sources\boot.wim
::del C:\WinPE_amd64\media\sources\boot.wim
::rename C:\WinPE_amd64\media\sources\boot2.wim boot.wim
::x86
if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" (del "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim"
copy /y "%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim")

::x64
if exist "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe51.wim" (del "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim"
copy /y "%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe51.wim" "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim")



goto end


::start functions::
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


:readMSUs
::set update0=Windows8.1-KB2919442-x86.msu
::set update0url=https://download.microsoft.com/download/9/D/A/9DA6C939-9E65-4681-BBBE-A8F73A5C116F/Windows8.1-KB2919442-x86.msu
::set update0crc32=9AA7770A

for /f "tokens=1* delims==" %%i in ('find /i "update0_x86=" %resourcePath%\%urlstxt%') do set update0_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x86_url=" %resourcePath%\%urlstxt%') do set update0_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x86_url2=" %resourcePath%\%urlstxt%') do set update0_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x86_crc32=" %resourcePath%\%urlstxt%') do set update0_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update1_x86=" %resourcePath%\%urlstxt%') do set update1_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x86_url=" %resourcePath%\%urlstxt%') do set update1_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x86_url2=" %resourcePath%\%urlstxt%') do set update1_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x86_crc32=" %resourcePath%\%urlstxt%') do set update1_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update2_x86=" %resourcePath%\%urlstxt%') do set update2_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x86_url=" %resourcePath%\%urlstxt%') do set update2_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x86_url2=" %resourcePath%\%urlstxt%') do set update2_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x86_crc32=" %resourcePath%\%urlstxt%') do set update2_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update3_x86=" %resourcePath%\%urlstxt%') do set update3_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x86_url=" %resourcePath%\%urlstxt%') do set update3_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x86_url2=" %resourcePath%\%urlstxt%') do set update3_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x86_crc32=" %resourcePath%\%urlstxt%') do set update3_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update4_x86=" %resourcePath%\%urlstxt%') do set update4_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x86_url=" %resourcePath%\%urlstxt%') do set update4_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x86_url2=" %resourcePath%\%urlstxt%') do set update4_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x86_crc32=" %resourcePath%\%urlstxt%') do set update4_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update5_x86=" %resourcePath%\%urlstxt%') do set update5_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x86_url=" %resourcePath%\%urlstxt%') do set update5_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x86_url2=" %resourcePath%\%urlstxt%') do set update5_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x86_crc32=" %resourcePath%\%urlstxt%') do set update5_x86_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update6_x86=" %resourcePath%\%urlstxt%') do set update6_x86=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x86_url=" %resourcePath%\%urlstxt%') do set update6_x86_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x86_url2=" %resourcePath%\%urlstxt%') do set update6_x86_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x86_crc32=" %resourcePath%\%urlstxt%') do set update6_x86_crc32=%%j


for /f "tokens=1* delims==" %%i in ('find /i "update0_x64=" %resourcePath%\%urlstxt%') do set update0_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x64_url=" %resourcePath%\%urlstxt%') do set update0_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x64_url2=" %resourcePath%\%urlstxt%') do set update0_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update0_x64_crc32=" %resourcePath%\%urlstxt%') do set update0_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update1_x64=" %resourcePath%\%urlstxt%') do set update1_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x64_url=" %resourcePath%\%urlstxt%') do set update1_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x64_url2=" %resourcePath%\%urlstxt%') do set update1_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update1_x64_crc32=" %resourcePath%\%urlstxt%') do set update1_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update2_x64=" %resourcePath%\%urlstxt%') do set update2_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x64_url=" %resourcePath%\%urlstxt%') do set update2_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x64_url2=" %resourcePath%\%urlstxt%') do set update2_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update2_x64_crc32=" %resourcePath%\%urlstxt%') do set update2_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update3_x64=" %resourcePath%\%urlstxt%') do set update3_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x64_url=" %resourcePath%\%urlstxt%') do set update3_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x64_url2=" %resourcePath%\%urlstxt%') do set update3_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update3_x64_crc32=" %resourcePath%\%urlstxt%') do set update3_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update4_x64=" %resourcePath%\%urlstxt%') do set update4_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x64_url=" %resourcePath%\%urlstxt%') do set update4_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x64_url2=" %resourcePath%\%urlstxt%') do set update4_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update4_x64_crc32=" %resourcePath%\%urlstxt%') do set update4_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update5_x64=" %resourcePath%\%urlstxt%') do set update5_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x64_url=" %resourcePath%\%urlstxt%') do set update5_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x64_url2=" %resourcePath%\%urlstxt%') do set update5_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update5_x64_crc32=" %resourcePath%\%urlstxt%') do set update5_x64_crc32=%%j

for /f "tokens=1* delims==" %%i in ('find /i "update6_x64=" %resourcePath%\%urlstxt%') do set update6_x64=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x64_url=" %resourcePath%\%urlstxt%') do set update6_x64_url=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x64_url2=" %resourcePath%\%urlstxt%') do set update6_x64_url2=%%j
for /f "tokens=1* delims==" %%i in ('find /i "update6_x64_crc32=" %resourcePath%\%urlstxt%') do set update6_x64_crc32=%%j
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
goto :eof


:invalidHashFound
echo.
echo   Error: Invalid hash found.

:end
endlocal
