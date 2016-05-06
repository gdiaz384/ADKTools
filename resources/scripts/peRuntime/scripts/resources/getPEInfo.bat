@echo off
setlocal enabledelayedexpansion

::find current pe version
diskpart /s nonexist.txt > temp.txt
for /f "tokens=4" %%i in ('find /n "version" temp.txt') do set rawversion=%%i
del temp.txt

set version=%rawversion%
if /i "%rawversion%" equ "6.0.6001" (set version=2.0
set bootDetectMode=legacy)
if /i "%rawversion%" equ "6.1.7601" (set version=3.x
set bootDetectMode=legacy)
if /i "%rawversion%" equ "6.3.9600" (set version=5.x
set bootDetectMode=modern)
if /i "%rawversion%" equ "10.0.10240" (set version=10.0
set bootDetectMode=modern)
if /i "%bootDetectMode%" equ "modern" goto modernDetect

:legacyDetect
::detection method
::PE versions 2/3 do not have a reliable detection method for booting so....
::try to produce bcdedit output and parse it for a huristic analysis that's probably correct
::The bcd output is from the system store of the OS on the disk and there's no way to know
::that such an OS was installed in the same mode win PE is currently booted in, but
::it's very likely the boot mode will match (better than nothing at least)
set bootMode=Unknown

bcdedit > temp2.txt
::parse output
for /f "tokens=2 skip=2" %%a in ('find /n "path" temp2.txt') do set extension=%%~xa
if /i "%extension%" equ ".exe" set bootMode=BIOS
if /i "%extension%" equ ".efi" set bootMode=UEFI
del temp2.txt
goto display

:modernDetect
::detection method 3
::Microsoft way only correct for winPE v4+. Versions 2-3 will always show BIOS.
::Note: delims is a TAB followed by a space.
::echo modernDetect module starting
wpeutil UpdateBootInfo 1>nul 2>nul
for /f "tokens=2* delims=	 " %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') do set Firmware=%%B 1>nul 2>nul
if %Firmware%==0x1 set bootMode=BIOS
if %Firmware%==0x2 set bootMode=UEFI

:display
::find local IP(s)
::current code fragile, will not work well with multiple NICs or IPs
set ip=no IP address
ipconfig > ipinfo.txt
if exist ipaddress.txt del ipaddress.txt
for /f "tokens=1-20" %%a in ('find "IPv4 Address" ipinfo.txt') do if "%%n" neq "" echo %%n>> ipaddress.txt
if exist ipinfo.txt del ipinfo.txt
for /f %%i in (ipaddress.txt) do (set ip=%%i)
if exist ipaddress.txt del ipaddress.txt

echo   Current WinPE Boot Info:  %version%  %processor_architecture%  %bootMode%  %ip%
:end
endlocal