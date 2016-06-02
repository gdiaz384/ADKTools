Background:
I have been scripting every aspect of Windows deployment from the ADKs and Microsoft's documentation as a side project for the last year or so. Today, marks the release of a major milestone: the automation of ADKtools capable of autobuilding WinPE.iso files.

This ADKTools project lets (nearly) anyone with an internet connection and thumb drive create a single USB that can install any version of Windows (7-10) on both BIOS/UEFI systems with a few clicks.

This project could be seen as an extension to AriaDeploy (my free open source deployment tool available on GitHub) but is also a fully stand alone project sharing similar design considerations. I've tried to make everything as simple as possible while retaining the full functionality of all of the involved systems. This includes support for custom.wim/ESD files and no weird limitations on anything.

Project Page: https://github.com/gdiaz384/ADKTools
Download Link: https://github.com/gdiaz384/ADKTools/releases

Possible Uses:
- The "How do I Clean Install?" problem solved. Forever.
- Supports CD/USB/HD/PXE booting.
- Upgrade to Win 7 or downgrade to Win 10 at leasure.
- Use predefined images on computers that need fixing (OEM style)
    - Recovery tools (can) include DaRT+WindowsRE and a boot menu at startup
- Run arbitary windows software in a temporary (PE) environment
- Quickly regenerate WinPE images when minor changes need to be made.
- Can be configured to multiboot different PE versions (i.e. boot winRE as well)
- Save time when installing Windows in VM enviornments (especially for build enviornments)
- Try out random windows versions.
    - Ever wonder what a properly configured Windows 10 Enterprise LTSB feels like compared to the RTM Home? (hint: night/day)
- Create a .wim backup of the current OS
- Hard disk swap scenarios
- Hardware transfer scenarios
- Create ESDs and deploy MS downloaded ESDs directly
- Stage AriaDeploy

Software Notes:
- Takes like 2 hours and 30GB to generate the PE images (full setup) + more space for the install.wim files. Or about 30 minutes for the ADK10 setup (minimal).
- I don't even try to decifer complicated partition layouts. If you want something more complicated than the default wipe/reload on disk 0, then refer to the documentation on diskpart and use image.bat with the /noformat switch. image /? for more info.
- For USB multiboot scenarios, remember that the windows binaries for booting purposes are version specific (although 8-10 should be cross compatible) and need to be swapped if needing to boot Windows 7 (e.g. WinPE3+ derivates) and vica-versa.
- I'm still tweaking on the scripts to automatically install the drivers, but they can be manually installed post imaging via dism /add-driver drivers:D:\mydrivers /recurse. Type "help" in WinPE for the exact syntax.

Misc:
- Official links to MS ISOs: [link]  (or pm me)
  - Extract the sources\install.wim and copy to USB drive (rename it to Win7x64Home.wim or w/e).
- I reccomend using a 64GB flash drive. A brand name USB 3.0 one for $20 is available from newegg on ebay: 
- All the PE/WinRE/DaRT images + 3 editions of windows (6 wims total for both x86+x64) should fit on a 32GB one ($10) but it's nice to have room for extra software and custom images.

Windows/Licensing Notes:
- Windows is still terrible no matter what version/architecture or edition you use. 
- This is not a way around licensing restrictions or purchasing Windows from Microsoft.
- Do not ask me "How do I activate Windows Version X Edition Y?" type questions. Licensing is beyond the scope of this project.
- Licensing (cont): OOBE can be automated, but I can only provide partial unattend.xml templates. They will only work if you enter the product keys yourself (version/architecture/edition specific). MS publishes some to use here: [link]

Hardware Notes:
- Remember that when not using a CSM, the UEFI architecture must still match the running OS version. This applies both to the PE and installed OS.
- If your hardware manufactuer implemented the UEFI API in a weird way (most do), then bcdboot can't add the boot entry reliably. Expect to have to manually add a UEFI boot entries to the NVRAM boot menu (NVRAM boot menu != windows boot manager) and that sorta requires some reading. [http://homepage.ntlworld.com/jonathan.deboynepollard/FGA/efi-boot-process.html] and [https://www.happyassassin.net/2014/01/25/uefi-boot-how-does-that-actually-work-then/]And also consult your system's user manual.
- Windows Version X will not boot on Hardware Y due to incompatibiliy Z. Sometimes you will need to know about/figure out a random incomptability between whatever and whatever.
- The manufactuer of Hardware X did not make drivers for Windows Version Y.
 - Please consult your OEM's website to see which OSs and in what configurations they support on your system. Always go to your OEM for drivers not random websites or "driver_finder.exe" or w/e. Not following your OEM's advice can mean that drivers may become an issue. You have been warned.
 - Also check if a driver pack is available: Dell, HP, Lenovo
 - I actively consult these lists, especially for Dell laptops (Latitudes), to make sure a driver pack exists prior to purchasing laptops for the OS I intended to use.
- For single deployments of non RTM images, the only important driver to install after the imaging process is the storage driver (AHCI/RAID). The rest can be installed after windows setup completes.

Limitations on Liability:
- I am not responsible for you deleting your data, you pouring gasoline and torching your own hardware, spiling your coffee, letting your ramen get cold, getting your parents mad at you, messing up your flashdrive, windows install, activation status or anything ever period.
- I make no claim that said software is "fit" to perform any particular purpose and provide no warranty or assurance of quality any kind. Neither is implied nor given.
- As always, never trust executable code/scripts written by random people from the internet, especially anything beta quality from Github. I recommend building the PE images in a VM or not at all. 
- You have been warned.

Typical Usage Guide:
1) Obtain a 32GB (minimum) or 64GB (recommended) flash drive
2) In a VM, download ADKTools from [url]
3) extract and click on "do.not.click.me.bat"
4) check to make sure your compy will not sleep when idle (control panel->power options->change plan settings)
5) wait to install AIK manually (next->next->next)
7) obtain installer.wim files (or isos) for the versions/architectures/editions of windows to install
MS links:  - [Windows 7](//www.microsoft.com/en-us/software-download/windows7), [Windows 8.1](//www.microsoft.com/en-us/software-download/windows8), [Windows 10](//www.microsoft.com/en-us/software-download/windows10)
Digital drive:
MDL forum:
or pm me
8) With ISOs (win7x64.iso) look for sources\install.wim, (not boot.wim) extract out and rename
9) place win7x64.wim in ADKTools\WININSTALLER\sources\Win7\ (the presence of this folder indicates setup has completed)
10) Download rufus from [url]
11) Insert USB drive from step #1
12) Launch Rufus
13) Alt+E, and then configure according to this screenshot:
14) when formating completes, copy WININSTALLER\ contents to flash drive
15) after transfer completes, safely eject flash drive
16) Boot target system from flash drive
17) Follow onscreen menus (I will work on the interface more at some point)

To learn about OOBE and driver installation automation mechanisms, along with please consult the documentation here: 

