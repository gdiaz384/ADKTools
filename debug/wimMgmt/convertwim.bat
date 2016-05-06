@echo off
setlocal enabledelayedexpansion

if /i "%~1" equ "" goto usageHelp
if /i "%~1" equ "/?" goto usageHelp
if /i "%~2" equ "" goto usageHelp

::call .\resources\setEnvironment.bat

::set peMgmtScripts=D:\scripts\wimMgmt
::set winperoot=D:\WinPE

::Update path to appropriate DISM version for convert towimboot if necessary
::set dismPath=%peMgmtScripts%\resources\dism
::set path=%dismPath%;%PATH%

::set bootFilesPath=%winperoot%\bootFiles
::Note: The directory tree should look like this:
::bootFilesPath\bootManager\3\x86\ (boot/efi folders and bootmgr/bootmgr.efi)
::bootFilesPath\bootManager\5\x64\ (boot/efi folders and bootmgr/bootmgr.efi)
::bootFilesPath\isoBootSector\ (efisys_x64.bin/efisys_x86.bin/etfsboot.com)

if /i "%~1" equ "pathtoiso" goto pathToIso

::parse %2 into variables
::D:\images\Win8.1\x64\Win7Sp1x64.Advanced\Image\Win7Sp1x64.Advancedimage.15.July.2014.wim.7z.esd

set drive=%~d2
set filepath=%~p2
set filename=%~n2
set extension=%~x2
::echo drive    :%drive%
::echo filepath :%filepath%
::echo filename :%filename%
::echo extension:%extension%

if /i "%filepath:~-1%" equ "\" set filepath=%filepath:~,-1%
set filepath=%drive%%filepath%
for /f "delims=." %%i in ("%extension%") do set extension=%%i

::echo filepath: %filepath%

echo rawPath    :%2
echo parsedPath:%filepath%\%filename%.%extension%

if not exist "%filepath%\%filename%.%extension%" goto end
set parsedPath=%filepath%\%filename%
if not exist "%parsedPath%.%extension%" goto end

::check %1 where to go
if /i "%~1" equ "towim" if /i "%extension%" equ "esd" (goto toWimFromESD) else if /i "%extension%" equ "swm" (goto toWimFromSWM)
if /i "%~1" equ "toesd" goto toESD
if /i "%~1" equ "toswm" goto toSWM
if /i "%~1" equ "toiso" goto convertToIso
if /i "%~1" equ "towimboot" goto toWimBoot
goto usageHelp

::convertwim towim d:\images\install.esd
:toWimFromESD
dism /export-image /sourceimagefile:"%parsedPath%.%extension%" /sourceindex:1 /destinationimagefile:"%parsedPath%.wim" /compress:max /checkintegrity
goto end

::convertwim towim d:\images\install.swm
:toWimFromSWM
dism /export-image /sourceimagefile:"%parsedPath%.%extension%" /swmfile:"%parsedPath%*.%extension%" /sourceindex:1 /destinationimagefile:"%parsedPath%.wim" /compress:max /checkintegrity
goto end

::convertwim toesd d:\images\install.wim
:toESD
if /i "%~3" equ "" (set compressMode=max) else (set compressMode=%~3)
if /i "%compressMode%" neq "max" if /i "%compressMode%" neq "recovery" goto end
dism /export-image /sourceimagefile:"%parsedPath%.%extension%" /sourceindex:1 /destinationimagefile:"%parsedPath%.esd" /compress:%compressMode% /checkintegrity
goto end

::convertwim toswm d:\images\install.wim
:toSWM
if "%~3" neq "" (set fileSize=%~3) else (set fileSize=3900)
dism /split-image /imageFile:"%parsedPath%.%extension%" /SWMFile:"%parsedPath%_part.swm" /filesize:%fileSize% 
goto end

:convertToIso
if /i "%~3" equ "" (set version=5) else (set version=%~3)
if /i "%version%" neq "10" if /i "%version%" neq "5" if /i "%version%" neq "4" if /i "%version%" neq "3" if /i "%version%" neq "2" (echo error setting version to: %version%  rawInput:%3
goto end)

if /i "%~4" equ "" (set architecture=x64) else (set architecture=%~4)
if /i "%architecture%" neq "x64" if /i "%architecture%" neq "x86" (echo error setting architecture to: %architecture%  rawInput:%4
goto end)

set isoBootData=2#p0,e,b"%bootFilesPath%\isoBootSector\etfsboot.com"#pEF,e,b"%bootFilesPath%\isoBootSector\efisys_%architecture%.bin"
 
if exist temp rmdir temp /s /q
mkdir temp
if not exist temp goto end
if not exist "%bootFilesPath%\bootManager\%version%\%architecture%" goto end
if not exist "%bootFilesPath%\bootManager\%version%\%architecture%\bootmgr" (echo Error: bootmgr not found, make sure bootmgr and associated bootfiles are present at "%bootFilesPath%\bootManager\%version%\%architecture%\bootmgr" and try again
goto end)
if not exist "%parsedPath%.%extension%" goto end
robocopy "%bootFilesPath%\bootManager\%version%\%architecture%" temp /mir
mkdir temp\sources
copy "%parsedPath%.%extension%" temp\sources\boot.wim /y

:andfinally
"%OSCDImgRoot%\oscdimg.exe" -bootdata:%isoBootData% -u1 -udfver102 temp "%parsedPath%.iso"
rmdir temp /s /q
goto end

:pathToIso
if /i "%~3" equ "" (set architecture=x64) else (set architecture=%~3)
if /i "%architecture%" neq "x64" if /i "%architecture%" neq "x86" (echo error setting architecture to: %architecture%  rawInput:%4
goto end)
set isoBootData=2#p0,e,b"%bootFilesPath%\isoBootSector\etfsboot.com"#pEF,e,b"%bootFilesPath%\isoBootSector\efisys_%architecture%.bin"
"%OSCDImgRoot%\oscdimg.exe" -bootdata:%isoBootData% -u1 -udfver102 %2 custom.iso
goto end

::convertwim  towimboot  d:\images\install.wim
:toWimBoot
call mountwim "%filepath%\%filename%.%extension%" %default_mountPath%

::confirm can work on image with no errors (no errors on parse and dism/image version match)
dism /image:d:\mount2 /get-currentedition > info.txt
for /f "skip=1 tokens=3" %%i in ('find /c "Error" info.txt') do set errorlevel=%%i
if "%errorlevel%" neq "0" (echo  Error, cannot work on image, DISM and image versions must match
type info.txt
goto end)

::confirm dism and image versions match
set count=1
for /f "skip=2 tokens=1-5" %%i in ('find /n "Version:" info.txt') do (set version!count!=%%i %%j %%k
set /a count+=1)
for /f "tokens=2-5 delims=. " %%i in ("%version1%") do set version1="%%i.%%j.%%k"
for /f "tokens=3-5 delims=. " %%i in ("%version2%") do set version2="%%i.%%j.%%k"
echo    Detected DISM Version: %version1%
echo    Detected Image Version: %version2%
if /i "%version1%" equ "%version2%" echo   Versions Match
if /i "%version1%" neq "%version2%" (echo  Error: Versions do not match
goto end)

::remove RE
if exist "%default_mountPath%\Windows\System32\Recovery\winre.wim" (attrib -h -s "%default_mountPath%\Windows\System32\Recovery\winre.wim"
move /y "%default_mountPath%\Windows\System32\Recovery\winre.wim" "%filepath%\winre.wim")
if exist "%default_mountPath%\recovery\WindowsRE\winre.wim" (attrib -h -s "%default_mountPath%\recovery\WindowsRE\winre.wim"
move /y "%default_mountPath%\recovery\WindowsRE\winre.wim" "%filepath%\winre.wim")

dism /image:"%default_mountPath%" /Optimize-Image /WIMBoot
mkdir "%temp%\scratchDir"
::dism /Capture-Image /WIMBoot /ImageFile:"%filepath%\%filename%_wimBoot.%extension%" /CaptureDir:"%default_mountPath%" /Name:"Windows %version% WIMBoot" /ScratchDir:"%temp%\scratchDir"
dism /Capture-Image /WIMBoot /ImageFile:"%filepath%\%filename%_wimBoot.%extension%" /CaptureDir:"%default_mountPath%" /Name:"Windows %version% WIMBoot"
call unmount "%default_mountPath%" discard

goto end

:usageHelp
echo   convertWim.bat can convert install.wim and boot.wim files:
echo        1) into and from compressed .esd files (takes forever) (wim^<-^>esd)
echo        2) into and from split wim files  (wim^<-^>swm)
echo        3) to bootable .isos for bios/efi systems (wim-^>iso)
echo        4) random directories into bootable isos (path-^>iso)
echo        5) into wimBoot capable wim files (8.1/10 only) -experimental
echo.
echo   Install.wim options:
echo       convertwim  towim  d:\images\install.esd
echo       convertwim  towim  d:\images\install.swm
echo       convertwim  toesd  d:\images\install.wim  {max  or  recovery}
echo       convertwim  toswm  d:\images\install.wim  {3900}
echo       convertwim  towimboot  d:\images\install.wim
echo   WinPEBoot.wim syntax:
echo       convertwim  toiso  d:\images\boot.wim  {PEver: 2,3,4,5,10}  {x86 or x64}
echo       convertwim  toiso  d:\images\boot.wim
echo       convertwim  toiso  d:\images\boot.wim  5
echo       convertwim  toiso  d:\images\boot.wim  10  x64
echo   D:\iso\path syntax:
echo       convertwim  pathtoiso  d:\WinPE\5\ISO
echo       convertwim  pathtoiso  "d:\Win PE files\ISO" x86
echo.
echo     ISO Notes:
echo     All isos should be bios/csm bootable
echo     WinPE boot.wim version and pe boot files should match (2,3,4,5,10)
echo     PE v5 boot files are the default
echo     The architecture option changes the boot files and the efisys.bin used
echo.
echo     UEFI compatibility:
echo     UEFI and operating system architectures must match (x86 or x64)
echo     Isos are x64 UEFI bootable by default
echo     Use the x86 option to switch support from native x64 UEFI to x86 UEFI
echo     x86 UEFI support begins at PEv4
echo.
echo     SanityCheck: 
echo     Do not put a sysprepped windows image into an iso file as a boot.wim
echo     or convert bootablePE images to esd or "split" 350 mb wims into 2gb swms
:end
endlocal 