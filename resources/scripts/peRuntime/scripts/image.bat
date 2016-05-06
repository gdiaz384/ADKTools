@echo off
setlocal enabledelayedexpansion
if /i "%~1" equ "/?" goto usageHelp
if /i "%~1" equ "" goto usageHelp

::TODO: image script add support for wimBoot (copy from source, format, and then apply), compactOS, minimalDisk formatting

pushd "%systemroot%\system32"
::check to see if Y: is mapped
if exist Y: goto selectMode

:ynotmapped
echo    .wim network share "Y:" is not available. Please map it if needed
echo    using ".\scripts\networkdrive\mapNetworkDrive.bat"   or  
echo    Syntax: net use Y: \\192.168.106.150\d$ /u:localhost\admin password

:selectMode
if /i "%~1" equ "capture" goto capture
if /i "%~1" equ "/capture" goto capture
if /i "%~1" equ "deploy" goto deploy
if /i "%~1" equ "/deploy" goto deploy
goto usageHelp


:capture
:: use %month% to reference May
:: use %month%%date:~10,4% to reference May2013
:: or %today% for 21May2013
for /f "usebackq tokens=2 delims=/ " %%n in ('%date%') do set m=%%n
if "%m%" equ "01" set month=Jan
if "%m%" equ "02" set month=Feb
if "%m%" equ "03" set month=Mar
if "%m%" equ "04" set month=Apr
if "%m%" equ "05" set month=May
if "%m%" equ "06" set month=June
if "%m%" equ "07" set month=July
if "%m%" equ "08" set month=Aug
if "%m%" equ "09" set month=Sept
if "%m%" equ "10" set month=Oct
if "%m%" equ "11" set month=Nov
if "%m%" equ "12" set month=Dec
set today=%date:~7,2%%month%%date:~10,4%

if "%~2" equ "" (set captureSource=C:
) else (set captureSource=%~2)
if not exist "%captureSource%\Windows" (echo   error "%captureSource%\Windows" does not exist
goto end)

if "%~3" equ "" (set captureDestination=Y:\capturedimage_%today%.wim
) else (set captureDestination=%~3)

if "%~4" equ "" (set imageName=capturedimage_%today%.wim
) else (set imageName=%~4)

::echo   image  /capture  C:  Y:\capturedimage.wim  "Windows 7 Sp1 x86"  max /noprompt

if "%~5" equ "" (set compressType=max
) else (set compressType=%~5)
if /i "%compressType%" neq "max" if /i "%compressType%" neq "fast" if /i "%compressType%" neq "none" if /i "%compressType%" neq "recovery" (echo   error, compression type not supported: %compressType%
goto end)

if /i "%~6" equ "noprompt" goto afterFinalCaptureConfirmation
if /i "%~6" equ "/noprompt" goto afterFinalCaptureConfirmation

::do not enable /verify with /compress:max, buggy. Can only /verify with /compress:fast
echo.
echo   Please verify the following is correct:
echo        dism.exe /Capture-Image /ImageFile:"%captureDestination%" /CaptureDir:"%captureSource%" /Name:"%imageName%" /Description:"%imageName%" /compress:"%compressType%"
echo.

:: /verify makes the image capture take a really long time and tends lead to a "file exists error code 80" messages
:: maybe it takes up too much extra space on the ramdisk?
set callback=afterFinalCaptureConfirmation
goto prompt
:afterFinalCaptureConfirmation
dism.exe /Capture-Image /ImageFile:"%captureDestination%" /CaptureDir:"%captureSource%" /Name:"%imageName%" /Description:"%imageName%" /compress:"%compressType%"
goto end


:deploy
if "%~2" equ "" (goto usageHelp) else (set deploySource=%~2)
if not exist "%deploySource%" (echo error applying image: "%deploySource%" does not exist
goto end)

::start parse (lightweight buggy version)::
set drive=%~d2
set filepath=%~p2
set filename=%~n2
set extension=%~x2

if /i "%filepath:~-1%" equ "\" set filepath=%filepath:~,-1%
set filepath=%drive%%filepath%
if /i "%~dp0" equ "%~dp1" set filepath=nul
if /i "%extension%" neq "" for /f "delims=." %%i in ("%extension%") do set extension=%%i
if /i "%extension%" equ "" set extension=nul

::user can enter c:\path\folder
::or ::user can enter c:\path\folder\
set rawfolderpath=%~2
if /i "%rawfolderpath:~-1%" equ "\" set foldername=temp

set folderpath=%~p2
::\path\
if /i "%foldername%" neq "temp" set foldername=%~n2

::user can enter c:\path\folder
::or ::user can enter c:\path\folder\

if /i "%folderpath:~-1%" equ "\" set folderpath=%folderpath:~,-1%
::\path
set fullfolderpath=%drive%%folderpath%\%foldername%
if /i "%~dp0" equ "%~dp1" set fullfolderpath=nul

::echo   _raw__DeploySource: %~2
::echo   parsedDeploySource: %filePath%\%fileName%.%extension%


if /i "%extension%" neq "wim" if /i "%extension%" neq "esd" if /i "%extension%" neq "swm" (echo   Error: "%extension%" is not a recognized extension: wim swm esd
goto end)

if "%~3" equ "" (set wimIndex=1
) else (set wimIndex=%~3)

if /i "%~4" equ "/noformat" (
if "%~5" equ "" (set deployDestination=B:) else (set deployDestination=%~5)
goto startImage
)
if /i "%~4" equ "noformat" (
if "%~5" equ "" (set deployDestination=B:) else (set deployDestination=%~5)
goto startImage
)

set deployDestination=B:

if "%~5" equ "" (set diskSelect=0
) else (set diskSelect=%~5)
if /i "%diskSelect%" neq "0" if /i "%diskSelect%" neq "1" if /i "%diskSelect%" neq "2" if /i "%diskSelect%" neq "3" if /i "%diskSelect%" neq "4" if /i "%diskSelect%" neq "5" if /i "%diskSelect%" neq "6" goto troubleshoot

if "%~6" equ "" (set formatSelect=MBR
) else (set formatSelect=%~6)
if /i not "%formatSelect%" equ "MBR" if /i not "%formatSelect%" equ "GPT" goto troubleshoot

set minimalFlag=false
if /i "%~4" equ "/noprompt" goto afterFinalDeployConfirmation
if /i "%~4" equ "noprompt" goto afterFinalDeployConfirmation
if /i "%~4" equ "/minimal" (set minimalFlag=true
goto afterFinalDeployConfirmation)
if /i "%~4" equ "minimal" (set minimalFlag=true
goto afterFinalDeployConfirmation)

echo.
echo.
echo         ALL DATA WILL BE LOST UPON CONTINUE
echo         ALL DATA WILL BE LOST UPON CONTINUE
echo.   
echo   Will now REFORMAT hard disk %diskSelect% with diskpart as %formatSelect% and run 
echo   the following command,  Please verify it is correct:
echo.
echo.
if /i "%extension%" equ "wim" echo        dism /Apply-Image /ImageFile:"%deploySource%" /Index:"%wimIndex%" /ApplyDir:"%deployDestination%"
if /i "%extension%" equ "esd" echo        dism /Apply-Image /ImageFile:"%deploySource%" /Index:"%wimIndex%" /ApplyDir:"%deployDestination%"
if /i "%extension%" equ "swm" echo        dism /Apply-Image /ImageFile:"%deploySource%" /SWMFile:"%deploySource%*.swm"  /ApplyDir:"%deployDestination%" /Index:"%wimIndex%"
echo.

set callback=afterFinalDeployConfirmation
goto prompt
:afterFinalDeployConfirmation

if /i "%minimalFlag%" equ "true" goto minimalFormat
if not exist ".\scripts\diskpart" mkdir ".\scripts\diskpart" 1>nul 2>nul
echo select disk %diskSelect% > .\scripts\diskpart\temp3.txt
if /i "%formatSelect%" equ "MBR" type ".\scripts\diskpart\formatMBRNoDisk.bat" >> ".\scripts\diskpart\temp3.txt"
if /i "%formatSelect%" equ "GPT" type ".\scripts\diskpart\formatGPTNoDisk.bat" >> ".\scripts\diskpart\temp3.txt"
diskpart.exe /s ".\scripts\diskpart\temp3.txt"
if "%formatSelect%" equ "MBR" subst R: S:\
goto startImage

:minimalFormat
if not exist ".\scripts\diskpart" mkdir ".\scripts\diskpart" 1>nul 2>nul
echo select disk %diskSelect% > .\scripts\diskpart\temp4.txt
if /i "%formatSelect%" equ "MBR" type ".\scripts\diskpart\formatMBRminimalNoDisk.bat" >> ".\scripts\diskpart\temp4.txt"
if /i "%formatSelect%" equ "GPT" type ".\scripts\diskpart\formatGPTminimalNoDisk.bat" >> ".\scripts\diskpart\temp4.txt"
diskpart.exe /s ".\scripts\diskpart\temp4.txt"
if "%formatSelect%" equ "GPT" subst R: B:\
if "%formatSelect%" equ "MBR" subst S: B:\
if "%formatSelect%" equ "MBR" subst R: B:\

:startImage
if /i "%extension%" equ "swm" goto startImageSWM
dism /Apply-Image /ImageFile:"%deploySource%" /Index:"%wimIndex%" /ApplyDir:"%deployDestination%"
goto cleanup

:startImageSWM
dism /Apply-Image /ImageFile:"%deploySource%" /SWMFile:"%filePath%\%fileName%*.%extension%"  /ApplyDir:"%deployDestination%" /Index:"%wimIndex%"


:cleanup
if /i "%~4" equ "noformat" goto bcdbootUser
if /i "%~4" equ "/noformat" goto bcdbootUser

if /i "%formatSelect%" equ "MBR" goto bcdbootMBR
if /i "%formatSelect%" equ "GPT" goto bcdbootGPT
echo    Error: formatSelect: "%formatSelect%" is not GPT or MBR
goto bcdbootUser

:bcdbootMBR
if exist "%deployDestination%\boot\bcd" (attrib -a -h -s "%deployDestination%\boot\bcd"
del "%deployDestination%\boot\bcd")
bcdboot "%deployDestination%\Windows" /s S: /f BIOS
goto end

:bcdbootGPT
if exist "%deployDestination%\boot\bcd" (attrib -a -h -s "%deployDestination%\boot\bcd"
del "%deployDestination%\boot\bcd")
bcdboot "%deployDestination%\Windows" /s S: /f UEFI
goto end


:bcdbootUser
echo   Please run "bcdboot %deployDestination%\Windows /s S: /f ALL" manually
echo   to copy the required boot files. Enter "bcdboot /?" or "help" for details.
goto end


:prompt
echo Are you sure (yes/no)?  (or enter T to troubleshoot)
set /p userInput=
if /i "%userInput%" equ "y" goto %callback%
if /i "%userInput%" equ "ye" goto %callback%
if /i "%userInput%" equ "yes" goto %callback%
if /i "%userInput%" equ "t" goto troubleshoot2
if /i "%userInput%" equ "n" goto end
if /i "%userInput%" equ "no" goto end
goto prompt


:troubleshoot
echo.
echo   A fatal error has occured and image.bat must not continue. Please verify
echo   the following are correct and restart image.bat or see image.bat /?:
echo   Full set local variable information is available at:  x:\dump2.txt
:troubleshoot2
set > x:\dump2.txt
path >> x:\dump2.txt
echo       /capture or /deploy value : %1
if /i "%1" equ "/capture" goto capturetroubleshoot
if /i "%1" equ "capture" goto capturetroubleshoot
if /i "%1" equ "/deploy" goto deploytroubleshoot
if /i "%1" equ "deploy" goto deploytroubleshoot
goto end
:capturetroubleshoot
echo                         source path : %captureSource%
echo             destination wim path : %captureDestination% 
echo                image description : %imageName%
echo                    noprompt value : %4
echo.
goto end
:deploytroubleshoot
echo                  source wim path : %deploySource%
echo                   target directory : %deployDestination%
echo                source wim index : %wimIndex%
echo /noprompt or /noformat value: %4
echo           wim or split wim(swm): %extension%
echo          diskpart disk specified: %diskSelect%
echo            diskpart format mode: %formatSelect%
echo.
goto end


::TODO: image script add support for Win8.1 wimBoot (copy from source, format, and then apply), 
::Win 10 compactOS -set a compactOS flag, and check for win10
::minimalDisk formatting
:usageHelp
echo.
echo   Usage: image.bat uses DISM to capture and deploy .wim images, ideally
echo   using network share Y. ESD and SWM formats are supported transparently.
echo.
echo   Syntax:
echo   image  /capture {sourceDir} {destWim} {description} {compression} {/noprompt}
echo   Examples:
echo   image  /capture  C:
echo   image  /capture  C:  Y:\capturedimage.wim
echo   image  /capture  C:  Y:\capturedimage.wim  "Windows 81 Pro x64"
echo   image  /capture  B:  Y:\capturedimage.wim  "Windows 7 Sp1 x86"  fast
echo   image  /capture  D:  Y:\capturedimage.wim  "Windows 7 Sp1 x86"  max /noprompt
echo.
echo   Syntax:
echo   image  /deploy [sourceWim] {index} {noprompt^|minimal} {diskNumber} {mbr^|gpt}
echo   image  /deploy [sourceWim] [index] [noformat] {dest}
echo   Examples:
echo   image  /deploy  Y:\install.wim
echo   image  /deploy  Y:\install.swm  1
echo   image  /deploy  Y:\install.wim  4  /noprompt
echo   image  /deploy  Y:\install.esd  1  /noprompt  0
echo   image  /deploy  Y:\install.swm  2  /noprompt  0  GPT
echo   image  /deploy  Y:\install.wim  1  /minimal   0  GPT
echo   image  /deploy  Y:\install.esd  6  /noformat  B:
echo.
echo   Edge case syntax (experimental):
echo   image  /wimboot  Y:\install.wim  0
echo   image  /compact  Y:\install.wim  4  /noprompt 
echo   image  /compact  Y:\install.wim  2  /noprompt 1 MBR
echo.
echo   Note: Using "%~nx0" without the optional arguments will ask %~nx0
echo   to perform the specified action with default values. A final prompt occurs
echo   before anything occurs unless /noprompt or /noformat is specified.
echo   The minimal option formats the disk without a recovery partition.
echo.
goto end


:end
popd
endlocal