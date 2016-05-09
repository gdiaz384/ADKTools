# ADKTools

ADKTools provides a set of windows scripts to help manage ADKs, WIM images and WinPE.

The project goals are to:

1. Create a USB drive that can install any (7+) version of Windows on any hardware (BIOS/UEFI) either from the local media or over the network.
2. Stage [AriaDeploy](//github.com/gdiaz384/AriaDeploy)

The development emphasis is on zero-configuration "just works" software.

## Features:

- Automatically install AIK 7, ADK 81 U and ADK 10
- Automatically generate WinPE.wim images (3.1,5.1,10)
- Supports WinPE.wim -> WinPE.iso conversion
- Supports WIM <-> ESD conversion
- Supports updating the following WinPE aspects:
    - Drivers (Dell, HP, Lenovo)
    - Packages (WMI)
    - Tools (DISM/BCDboot)
    - Scripts
- The included PE scripts transparently:
    - Map network drives (requires a configured FTP server)
    - Stage AriaDeploy
    - Stage AutoImage (Automatically detect and install WIM/ESD images)
    - Provide a CLI frontend for DISM to help capture/deploy WIM images manually
        - Note: GImageX is also included.
- Creates a WinPE workspace enviornment to easily make changes to WIM images.

## Download:
```
Latest Version: none
In Development: 0.0.1-alpha
```
Click [here](//github.com/gdiaz384/ADKTools/releases) or on "releases" at the top to download the latest version.

## Basic Usage Guide:

1. Download and extract.
2. Start an admin cmd prompt and navigate to ADKTools\
3. Run installADK.bat to install at least one of the ADKs (not AIK 7), all 3 is preferred.
4. Run createWinPE.bat to generate updated WinPE.wim files
    - Note: WDS can PXE boot these WinPE.wim files (WDS 2012+ does both BIOS PXE and UEFI PXE)
5. If not using WDS: Run convertWim.bat to generate ISO files from WinPE.wim.
    - Note: It is possible to burn these ISO files to optical media.
6. USB: Use [Rufus](//rufus.akeo.ie) to make a USB drive bootable and then copy the WinPE.iso contents to the USB drive
7. Copy any WIM images to deploy to the \images folder on the disk
    - [Windows 7](//www.microsoft.com/en-us/software-download/windows7), [Windows 8.1](//www.microsoft.com/en-us/software-download/windows8), [Windows 10](//www.microsoft.com/en-us/software-download/windows10)

## Advanced Usage Guide:

To automatically map network drives:

To update the WinPE scripts:

To reset the WinPE images:
```
1. open a Deployment Tools Environment
2. massupdate reset 5 x64
3. massupdate reset all
```
Add additional DaRT/WinRE/WinPE.wim images to the boot menu and USB drive:

## Release Notes:

- If downloading from github manually (instead of using an official release.zip) remember to change the line ending format from Unix back to Windows using Notepad++.
- MUI versions of WinPE and other ADKTools aspects are not currently supported.
- ADKtools is not developed, tested against or designed to work with UAC enabled.
- WinPEx64 versions have Miku mode enabled by default.
- To disable Miku mode: ADKTools\resources\scripts\wimMgmt\update.bat->set MikuModeEnabled=false and then reset the image (massupdate reset)

## Dependencies:

- Requires Microsoft Windows 7 or newer (but Vista will probably work).
- The ADKs require Microsoft .NET Framework 4.5 (included in Win 8+)
- Requires Administrative access.
- 30GB+ HD space (The ADKs take like 17GB alone) + 2hrs.

## License:
Pick your License: GPL (any) or BSD (any) or MIT/Apache
