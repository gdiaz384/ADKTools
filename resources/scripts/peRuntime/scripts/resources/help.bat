@echo off
echo   Syntax help:
echo   net use Y: \\192.168.106.150\d$ /u:localhost\administrator mypassword
echo   drvload E:\e1000NIC\driver1.inf
echo.
echo   diskpart /s .\scripts\diskpart\listdisk.bat
echo   diskpart /s .\scripts\diskpart\formatMBR.bat  //selects disk 0
echo   diskpart /s .\scripts\diskpart\formatGPT.bat   //selects disk 0
echo.
echo   dism /image:B:\ /add-driver /driver:Y:\drivers\Win7_x64\storage /recurse
echo   dism /capture-image /imagefile:Y:\install.wim /capturedir:B:\ /Name:Win8
echo   dism /apply-image /imagefile:E:\install.wim /index:1 /applydir:B:\
echo   dism /apply-image /imagefile:install.wim /SWMFile:install*.wim 
echo   /applydir:B:\ /index:1
echo.
echo   bcdboot B:\Windows OR scripts\bcdfix.bat OR bcdboot B:\Windows /s S: /f UEFI
echo   bcdboot B:\Windows /s S: /f ALL    OR       bcdboot B:\Windows /s S: /f BIOS
echo   copy scripts\Win7Ultx64.xml  B:\Windows\system32\sysprep\unattend.xml /y
echo.  
echo   For more comprehensive help: "notepad detailedHelp.txt"
echo   or to begin:  autoImage.bat   or   image.bat