# ADKTools

ADKTools provides a set of windows scripts to help manage ADKs, WIM images and WinPE.

The project goals are to:

1. Create a USB drive that can install any (7+) version of Windows on any hardware (BIOS/UEFI) either from the local media or over the network.
2. Stage [AriaDeploy](//github.com/gdiaz384/AriaDeploy)

The development emphasis is on zero-configuration "just works" software.

## Key Features:

- Automatically install AIK 7, ADK 81 U and ADK 10
- Automatically generate WinPE.wim images (3.1,5.1,10)
- Supports WinPE.wim -> WinPE.iso conversion
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
- Supports WIM <-> ESD conversion
- Creates a WinPE workspace enviornment to easily make changes to WIM images.

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
8. (Optional) Add additional DaRT/WinRE/WinPE.wim images to the boot menu and USB drive.

## Download:
```
Latest Version: 0.0.1-pre-alpha
In Development: 0.0.1-alpha
```
Click [here](//github.com/gdiaz384/ADKTools/releases) or on "releases" at the top to download the latest version.

## Advanced Usage Guide:

To update WinPE 5.0->5.1:

To update WinPE drivers:

To update packages:

To reset the WinPE images:

Add additional DaRT/WinRE/WinPE.wim images to the boot menu and USB drive:

## Release Notes:

- If downloading from github manually (instead of using an official release.zip) remember to change the line ending format from Unix back to Windows using Notepad++.
- Consider adding to env path
- ADKtools is not developed, tested against or designed to work with UAC enabled.

## Dependencies:

- Requires Microsoft Windows 7 or newer (but Vista will probably work).
- Requires Administrative access.
- A relatively recent toaster. Note: "Toaster ovens" are not supported.
- 30GB+ HD space (The ADKs take like 17GB alone).

## License:
Pick your License: GPL (any) or BSD (any) or MIT/Apache
