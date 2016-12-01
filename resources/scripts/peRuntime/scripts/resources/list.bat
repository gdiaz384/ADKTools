@echo off
if /i "%~1" equ "" goto end

if /i "%~1" equ "disk" if exist ".\scripts\diskpart\list_disk.bat" (diskpart /s ".\scripts\diskpart\listDiskMinimal.bat"
goto end)

if /i "%~1" equ "partition" if exist ".\scripts\diskpart\list_partition.bat" (diskpart /s ".\scripts\diskpart\listDisk.bat"
goto end)

if /i "%~1" equ "volume" if exist ".\scripts\diskpart\list_volume.bat" (diskpart /s ".\scripts\diskpart\listDisk.bat"
goto end)


:end
