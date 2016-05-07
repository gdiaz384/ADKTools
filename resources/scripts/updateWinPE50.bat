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

set resourcePath=..
set toolPath=%resourcePath%\tools
set mountDir=%temp%\temp%random%
set sevenZ=7z.exe
set aria=aria2c.exe
set downloadPath=%resourcePath%\..\..\win81UpdateMSUs
set workspaceDest=%userprofile%\desktop
set logfile=winPE50upgrade.log
set description=WinPE51
set ADKDeploymentToolsPath=Assessment and Deployment Kit\Deployment Tools
set ADKsetEnvScript=DandISetEnv.bat

call :detectADK81UandADK10
cls

if not exist "%downloadPath%" mkdir "%downloadPath%"

call :readx86MSUs

for /l %%i in (0,1,6) do if not exist "%downloadPath%\!update%%i!" call "%toolPath%\%aria%" !update%%iurl! --dir="%cd%\%downloadPath%"

for /l %%i in (0,1,6) do (call :hashCheck "%downloadPath%\!update%%i!" "!update%%icrc32!" crc32
echo hash: !hash!
if /i "!hash!" neq "valid" goto invalidHashFound)

call :readx64MSUs

for /l %%i in (0,1,6) do if not exist "%downloadPath%\!update%%i!" call "%toolPath%\%aria%" !update%%iurl! --dir="%cd%\%downloadPath%"

for /l %%i in (0,1,6) do (call :hashCheck "%downloadPath%\!update%%i!" "!update%%icrc32!" crc32
echo hash: !hash!
if /i "!hash!" neq "valid" goto invalidHashFound)

::alright so all of them are available and downloaded sucessfully.

pushd "%cd%"
call "%ADK81Uinstallpath%\%ADKDeploymentToolsPath%\%ADKsetEnvScript%"
popd

if not exist "%mountDir%" mkdir "%mountDir%"

call :readx86MSUs

dism /Mount-Image /ImageFile:"%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe50.wim" /index:1 /MountDir:"%mountDir%"

for /l %%i in (0,1,6) do dism /Add-Package /PackagePath:"%downloadPath%\!update%%i!" /Image:"%mountDir%" /LogPath:%logfile%

::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919442-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919355-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2932046-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2934018-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2937592-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2938439-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
::dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2959977-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log

dism /image:%mountDir% /Cleanup-Image /StartComponentCleanup /ResetBase

dism /capture-image /imagefile:"%workspaceDest%\winPEWorkspace\5_x\PE_x86\originalWim\winpe51.wim" /capturedir:%mountDir% /name:"%description%x86" /description:"%description%x86" /compress:max /bootable

dism /Unmount-Image /MountDir:"%mountDir%" /discard
::del C:\WinPE_amd64\media\sources\boot.wim
::rename C:\WinPE_amd64\media\sources\boot2.wim boot.wim


call :readx64MSUs

dism /Mount-Image /ImageFile:"%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe50.wim" /index:1 /MountDir:"%mountDir%"

for /l %%i in (0,1,6) do dism /Add-Package /PackagePath:"%downloadPath%\!update%%i!" /Image:"%mountDir%" /LogPath:%logfile%

dism /image:%mountDir% /Cleanup-Image /StartComponentCleanup /ResetBase

dism /capture-image /imagefile:"%workspaceDest%\winPEWorkspace\5_x\PE_x64\originalWim\winpe51.wim" /capturedir:%mountDir% /name:"%description%x64" /description:"%description%x64" /compress:max /bootable

dism /Unmount-Image /MountDir:"%mountDir%" /discard

::now need to check if was captured and copy over sources\boot.wim

goto end


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


:readx86MSUs
set update0=Windows8.1-KB2919442-x86.msu
set update0url=https://download.microsoft.com/download/9/D/A/9DA6C939-9E65-4681-BBBE-A8F73A5C116F/Windows8.1-KB2919442-x86.msu
set update0crc32=9AA7770A

set update1=Windows8.1-KB2919355-x86.msu
set update1url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2919355-x86.msu
set update1crc32=5AB54248

set update2=Windows8.1-KB2932046-x86.msu
set update2url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2932046-x86.msu
set update2crc32=BC3E5E75

set update3=Windows8.1-KB2934018-x86.msu
set update3url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2934018-x86.msu
set update3crc32=3CC92EC3
::set update3crc32=3CC92EC2

set update4=Windows8.1-KB2937592-x86.msu
set update4url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2937592-x86.msu
set update4crc32=162CC2B6

set update5=Windows8.1-KB2938439-x86.msu
set update5url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2938439-x86.msu
set update5crc32=E3CB4ECB

set update6=Windows8.1-KB2959977-x86.msu
set update6url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2959977-x86.msu
set update6crc32=1DD2626C
goto :eof


:readx64MSUs
set update0=Windows8.1-KB2919442-x64.msu
set update0url=https://download.microsoft.com/download/C/F/8/CF821C31-38C7-4C5C-89BB-B283059269AF/Windows8.1-KB2919442-x64.msu
set update0crc32=763FA9DA

set update1=Windows8.1-KB2919355-x64.msu
set update1url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2919355-x64.msu
set update1crc32=B45C9B9F

set update2=Windows8.1-KB2932046-x64.msu
set update2url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2932046-x64.msu
set update2crc32=42AEEAB7

set update3=Windows8.1-KB2934018-x64.msu
set update3url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2934018-x64.msu
set update3crc32=AAAEACDC

set update4=Windows8.1-KB2937592-x64.msu
set update4url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2937592-x64.msu
set update4crc32=398F818D

set update5=Windows8.1-KB2938439-x64.msu
set update5url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2938439-x64.msu
set update5crc32=7BD7DD9B

set update6=Windows8.1-KB2959977-x64.msu
set update6url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2959977-x64.msu
set update6crc32=BD47BE3C
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
if exist "%mountDir%" rmdir /s /q "%mountDir%"
