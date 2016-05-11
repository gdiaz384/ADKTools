@echo off

set resourcePath=resources
set toolsPath=%resourcePath%\tools
set archivePath=%resourcePath%\archives
set WININSTALLERArchive=WININSTALLER.7z
set winPEBootFilesArchive=winPEBootFiles.7z
set sevenZ=7z.exe
set workspaceDest=%cd%
if /i "%workspaceDest:~-1%" equ "\" set workspaceDest=%workspaceDest:~,-1%

if /i "%processor_architecture%" equ "x86" set architecture=x86
if /i "%processor_architecture%" equ "AMD64" set architecture=x64
if not defined architecture (echo    unspecified error
goto end)

::extract WININSTALLER directory
::extract winPEBootFiles.zip contents into WININSTALLER 
::copy existing pe images (boot.wim->rename WinPE31_x86.wim) to folder (if exist)
::if not exist "%workspaceDest%\winPEWorkspace\WININSTALLER" "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%WININSTALLERArchive%" -o"%workspaceDest%" -y -aoa
"%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%WININSTALLERArchive%" -y -aoa

::unarchive boot files to workspace\ root
if not exist "WININSTALLER\winPEBootFiles" "%toolsPath%\%architecture%\7z\%sevenZ%" x "%archivePath%\%winPEBootFilesArchive%" -o"WININSTALLER\sources" -y -aos

call :moveToPath "%workspaceDest%\winPEWorkspace\2_x\PE_x86\ISO\media\sources\boot.wim" 2 WinPE2_x86.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\2_x\PE_x64\ISO\media\sources\boot.wim" 2 WinPE2_x64.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\3_x\PE_x86\ISO\media\sources\boot.wim" 3 WinPE31_x86.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\3_x\PE_x64\ISO\media\sources\boot.wim" 3 WinPE31_x64.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\4_x\PE_x86\ISO\media\sources\boot.wim" 4 WinPE4_x86.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\4_x\PE_x64\ISO\media\sources\boot.wim" 4 WinPE4_x64.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\5_x\PE_x86\ISO\media\sources\boot.wim" 5 WinPE51_x86.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\5_x\PE_x64\ISO\media\sources\boot.wim" 5 WinPE51_x64.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\10_x\PE_x86\ISO\media\sources\boot.wim" 10 WinPE10_x86.wim
call :moveToPath "%workspaceDest%\winPEWorkspace\10_x\PE_x64\ISO\media\sources\boot.wim" 10 WinPE10_x64.wim

goto end


:moveToPath
set peVersion=%~2
set name=%~3

if /i "%peVersion%" equ "2" set winVersion=Vista
if /i "%peVersion%" equ "3" set winVersion=7
if /i "%peVersion%" equ "4" set winVersion=8
if /i "%peVersion%" equ "5" set winVersion=81
if /i "%peVersion%" equ "10" set winVersion=10

if exist "%~1" copy /y "%~1" "WININSTALLER\sources\Win%winVersion%\winPETools\%name%"
goto :eof


:end
