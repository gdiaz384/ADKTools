@echo off
setlocal enabledelayedexpansion

echo.
echo   Attempting to map network drive please wait....
echo.

::kinda pointless to have the firewall enabled in windowsPE
::also: needs disabling for FTP and maybe Aira to work as intended anyway
wpeutil disablefirewall 1>nul 2>nul

set serveraddress1=2012r2mdt
set serveraddress2=2008r2mdt
set serveraddress3=192.168.106.150
set serveraddress4=192.168.0.150
set serveraddress5=AriaDeployLite
set serveraddress6=Strawberry
set ftpUserName=anonymous
::nul is not the password, it means no password set. Changing it to anything else will specify an actual password
set ftpUserNamePassword=nul
set credentialsFile=credentialsForNetworkDrive.txt
set default_networkDriveLetter=Y

::Overview:
::1) test if addresses exist
::2) try to ftp to valid addresses to fetch drive path mapping information and credentials file
::3) extract credentials
::4) map network drive
::5) test to see if mapped - if failed, tell user to do it manually

::1) test if addresses exist
set validIPtxt=validAddressesList.txt
if exist "%validIPtxt%" del "%validIPtxt%"
set validAddressFound=false
:step2
::test if addresses exist
for %%i in (1,2,3,4,5,6) do (call :checkLink !serveraddress%%i!
if !errorlevel! equ 0 (echo !serveraddress%%i!>>%validIPtxt%
echo   !serveraddress%%i! reachable
set validAddressFound=true)
if !errorlevel! neq 0 (echo !serveraddress%%i! not reachable)
)

::Not available means could not ping it. FTP might be up but if echo request
::is blocked then script won't connect to it
if /i "%validAddressFound%" neq "true" (echo   No server available
goto end)

::2) try to ftp to valid addresses to fetch drive path mapping information and credentials file
if exist "%credentialsFile%" del "%credentialsFile%"
for /f %%a in (%validIPtxt%) do call :attemptFetchFTP %%a
if exist "%validIPtxt%" del "%validIPtxt%"
if not exist "%credentialsFile%" goto notMapped

::3) extract credentials
:mapDrive
for /f "skip=2 delims== tokens=1-10" %%a in ('find "clientDriveLetter" %credentialsFile%') do set networkDriveLetter=%%b
for /f "skip=2 delims== tokens=1-10" %%a in ('find "sharePath" %credentialsFile%') do set sharePath=%%b
for /f "skip=2 delims== tokens=1-10" %%a in ('find "serverAddress" %credentialsFile%') do set serverAddress=%%b
for /f "skip=2 delims== tokens=1-10" %%a in ('find "username" %credentialsFile%') do set networkUserName=%%b
for /f "skip=2 delims== tokens=1-10" %%a in ('find "password" %credentialsFile%') do set networkUserPsw=%%b

if not defined networkDriveLetter set networkDriveLetter=%default_networkDriveLetter%

if exist %networkDriveLetter%: (echo   %networkDriveLetter%: already exists
net use
goto end)

::4) map network drive
net use %networkDriveLetter%: \\%serverAddress%\%sharePath% /u:localhost\%networkUserName% %networkUserPsw%
::prefer to specify domain as localhost\admin but sometimes won't work, like if the domain was specified on the server
::side, so if the previous command didn't work, try again without specifying the domain (different syntax basically)
if not exist %networkDriveLetter%: net use %networkDriveLetter%: \\%serverAddress%\%sharePath% /u:%networkUserName% %networkUserPsw%

::5) test to see if mapped - if failed, tell user to do it manually
:checkMapping
if not exist %networkDriveLetter%: goto notMapped

if exist %networkDriveLetter%: net use > temp.txt
if not exist temp.txt goto end
for /f "skip=2 tokens=1-10" %%a in ('find "%networkDriveLetter%:" temp.txt') do set serverAddressAndSharePath=%%c
if exist temp.txt del temp.txt
echo   %networkDriveLetter%: successfully mapped to %serverAddressAndSharePath%
goto end


::StartFunctionList::
::checkLink expects a serverAddress as %1 and will return the result of pinging it in the %errorlevel% variable
::0 means success, 1 means error (default). Could also just check FTP availability instead. But how?
::or could skip availability test completely and just blindly attempt to open an ftp connection everywhere all random like
:checkLink
set ipaddr=%~1
set errorlevel=1
for /f "tokens=5,6,7" %%a in ('ping -n 1 %ipaddr%') do (
    if "%%b" equ "unreachable." goto :eof
    if "%%a" equ "Received" if "%%c" equ "1," set errorlevel=0
)
goto :eof


::attemptFetchFTP expects a serverAddress as %1 and will try to get credentials.txt over ftp using the anonymous
::account w/no psw. Could add actual user account/psw for slightly increased obscurity in specalized enviornments
:attemptFetchFTP
::if already exists, don't try to fetch another copy
if exist "%credentialsFile%" goto :eof
::if it doesn't, then try to ftp to an address (hopefully valid) to fetch credentials.txt
echo   Attempting to get ftp://%~1/%credentialsFile%
set tempfile=tempFTP.txt
echo open %~1 >%tempfile%
echo %ftpUserName%>>%tempfile%
if /i "%ftpUserNamePassword%" equ "nul" echo.  >>%tempfile%
if /i "%ftpUserNamePassword%" neq "nul" echo %ftpUserNamePassword% >>%tempfile%
echo binary >>%tempfile%
echo get %credentialsFile% >>%tempfile%
echo bye >>%tempfile%
ftp /s:%tempfile% >nul 2>nul
if exist %tempfile% del %tempfile%
goto :eof
::EndFunctionList::

:notMapped
echo    .wim network share "%networkDriveLetter%:" is not available. Please map manually if needed
echo    Syntax: 
echo        net use %networkDriveLetter%: \\192.168.106.150\d$ /u:localhost\admin password

:end
endlocal