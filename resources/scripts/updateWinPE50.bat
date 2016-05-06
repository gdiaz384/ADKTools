@
::download files
::hash check them
::abort if any hash check fails
::mount 5.0
::update winpe 5->5.1
::capture image
::if captured to originalwim\winpe51.wim sucessfully, delete sources\boot.wim
::unmount and discard
::copy 5.1 over sources\boot.wim


set update0=Windows8.1-KB2919355-x86.msu
set update0url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2919355-x86.msu
set update0crc32=

set update1=Windows8.1-KB2932046-x86.msu
set update1url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2932046-x86.msu
set update1crc32=

set update2=Windows8.1-KB2934018-x86.msu
set update2url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2934018-x86.msu
set update2crc32=

set update3=Windows8.1-KB2937592-x86.msu
set update3url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2937592-x86.msu
set update3crc32=

set update4=Windows8.1-KB2938439-x86.msu
set update4url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2938439-x86.msu
set update4crc32=

set update5=Windows8.1-KB2959977-x86.msu
set update5url=https://download.microsoft.com/download/4/E/C/4EC66C83-1E15-43FD-B591-63FB7A1A5C04/Windows8.1-KB2959977-x86.msu
set update5crc32=

set update6=Windows8.1-KB2919442-x86.msu
set update6url=https://download.microsoft.com/download/9/D/A/9DA6C939-9E65-4681-BBBE-A8F73A5C116F/Windows8.1-KB2919442-x86.msu
set update6crc32=


set update0=Windows8.1-KB2919355-x64.msu
set update0url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2919355-x64.msu
set update0crc32=

set update1=Windows8.1-KB2932046-x64.msu
set update1url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2932046-x64.msu
set update1crc32=

set update2=Windows8.1-KB2934018-x64.msu
set update2url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2934018-x64.msu
set update2crc32=

set update3=Windows8.1-KB2937592-x64.msu
set update3url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2937592-x64.msu
set update3crc32=

set update4=Windows8.1-KB2938439-x64.msu
set update4url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2938439-x64.msu
set update4crc32=

set update5=Windows8.1-KB2959977-x64.msu
set update5url=https://download.microsoft.com/download/D/B/1/DB1F29FC-316D-481E-B435-1654BA185DCF/Windows8.1-KB2959977-x64.msu
set update5crc32=

set update6=Windows8.1-KB2919442-x64.msu
set update6url=https://download.microsoft.com/download/C/F/8/CF821C31-38C7-4C5C-89BB-B283059269AF/Windows8.1-KB2919442-x64.msu
set update6crc32=

set resources=resources
set tools=%resources%\tools
set mountDir=%
set sevenZ=
set aria=aria2c.exe
set downloadPath=win81UpdateMSUs

if not exist "%downloadPath%" mkdir "%downloadPath%"

for /l %%i in (0,1,6) do echo "%tools%\%aria%" !update%%iurl! --dir="%downloadPath%"


Dism /Mount-Image /ImageFile:"C:\WinPE_amd64\media\sources\boot.wim" /index:1 /MountDir:"C:\WinPE_amd64\mount"




Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919442-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2919355-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2932046-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2934018-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2937592-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2938439-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log
Dism /Add-Package /PackagePath:C:\MSU\Windows8.1-KB2959977-x64.msu /Image:C:\WinPE_amd64\mount /LogPath:AddPackage.log

Dism /image:c:\WinPE_amd64\mount /Cleanup-Image /StartComponentCleanup /ResetBase




Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /discard
del C:\WinPE_amd64\media\sources\boot.wim
rename C:\WinPE_amd64\media\sources\boot2.wim boot.wim


goto end


::hash check a file

echo    Calculating hash of downloaded file please wait...
set errorlevel=0
if exist "%targetTempFilesLocation%\%imagefileName%" call :hashCheck "%targetTempFilesLocation%\%imagefileName%" > hash.txt
for /f "tokens=1-10" %%a in (hash.txt) do (set calculatedHash=%%a
if exist hash.txt del hash.txt
goto compareHashes2)
:compareHashes2
echo.
echo  comparing: hash:"%hashData%"  %imagefileName%
echo  with       hash:"%calculatedHash%"  %targetTempFilesLocation%\%imagefileName%
if "%calculatedHash%" equ "%hashData%" (
echo   %imagefileName% successfully downloaded without errors
goto deploy
) else (
echo "%calculatedHash%" is NOT equal to 
echo "%hashData%" 
echo   File transfered with errors
)


::Usage: hashCheck expects a file %1 as input, defaults to crc32, outputs the hash + name of the file separated by a space
::hashCheck x:\myfile.wim
::hashCheck x:\myfile.wim crc32
:hashCheck 
@echo off
set tempfile=rawHashOutput.txt
"%sevenz%" h -scrc%hashtype% "%~1" > %tempfile%

for /f "tokens=1-10" %%a in ('find /i /c "Cannot open" %tempfile%') do set errorlevel=%%c
if /i "%errorlevel%" neq "0" (echo   Unable to generate hash, file currently in use
if exist "%tempfile%" del "%tempfile%"
goto :eof)

for /f "skip=2 tokens=1-10" %%a in ('find /i "for data" %tempfile%') do echo %%d "%~1"
if exist "%tempfile%" del "%tempfile%"
goto :eof

:end
