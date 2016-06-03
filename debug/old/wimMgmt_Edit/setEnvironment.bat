@echo off

::set winPERoot=D:\WinPE
set winPERoot=%~dp0
::set pe root to wherever the current script (setEnvironment.bat) is being run from
set peFileName=boot
set default_mountPath=D:\mount
set peRuntimeScripts=D:\scripts\peRuntime
set peMgmtScripts=%~dp0wimMgmt
set pxePath=D:\RemoteInstall\boot
set peDriverRoot=D:\updates\drivers\winPE

set bootFilesPath=%winperoot%winpeBootFiles
::set bootFilesPath=%winperoot%\bootFiles
::Note: The directory tree should look like this:
::bootFilesPath\bootManager\3\x86\ (boot/efi folders and bootmgr/bootmgr.efi)
::bootFilesPath\bootManager\5\x64\ (boot/efi folders and bootmgr/bootmgr.efi)
::bootFilesPath\isoBootSector\ (efisys_x64.bin/efisys_x86.bin/etfsboot.com)

set pe2driverDirectory=2_x
set pe3driverDirectory=3_x
set pe4driverDirectory=4_x
set pe5driverDirectory=5_x
set pe10driverDirectory=10_x

set peToolsPath_x86=D:\updates\tools\x86
set peToolsPath_x64=D:\updates\tools\x64

set x86PEisoPath2=2_x\PE_x86
set x64PEisoPath2=2_x\PE_x64
set x86PEwimPath2=%x86PEisoPath2%\ISO\media\sources
set x64PEwimPath2=%x64PEisoPath2%\ISO\media\sources
set x86PEmountPath2=%x86PEisoPath2%\ISO\mount
set x64PEmountPath2=%x64PEisoPath2%\ISO\mount

set x86PEisoPath3=3_x\PE_x86
set x64PEisoPath3=3_x\PE_x64
set x86PEwimPath3=%x86PEisoPath3%\ISO\media\sources
set x64PEwimPath3=%x64PEisoPath3%\ISO\media\sources
set x86PEmountPath3=%x86PEisoPath3%\ISO\mount
set x64PEmountPath3=%x64PEisoPath3%\ISO\mount

set x86PEisoPath4=4_x\PE_x86
set x64PEisoPath4=4_x\PE_x64
set x86PEwimPath4=%x86PEisoPath4%\ISO\media\sources
set x64PEwimPath4=%x64PEisoPath4%\ISO\media\sources
set x86PEmountPath4=%x86PEisoPath4%\ISO\mount
set x64PEmountPath4=%x64PEisoPath4%\ISO\mount

set x86PEisoPath5=5_x\PE_x86
set x64PEisoPath5=5_x\PE_x64
set x86PEwimPath5=%x86PEisoPath5%\ISO\media\sources
set x64PEwimPath5=%x64PEisoPath5%\ISO\media\sources
set x86PEmountPath5=%x86PEisoPath5%\ISO\mount
set x64PEmountPath5=%x64PEisoPath5%\ISO\mount

set x86PEisoPath10=10_x\PE_x86
set x64PEisoPath10=10_x\PE_x64
set x86PEwimPath10=%x86PEisoPath10%\ISO\media\sources
set x64PEwimPath10=%x64PEisoPath10%\ISO\media\sources
set x86PEmountPath10=%x86PEisoPath10%\ISO\mount
set x64PEmountPath10=%x64PEisoPath10%\ISO\mount

set toolPath=%~dp0
set OSCDImgRoot=%toolPath%ocdimg
set tempDism=%toolPath%dism
set tempBcdBoot=%toolPath%bcdboot
set tempUSMT=%toolPath%\usmt

set tempPath=%tempDism%;%tempBcdBoot%;%OSCDImgRoot%;%peMgmtScripts%
set path=%NewPath%;%PATH%
