# ADKTools

ADKTools are a set of windows scripts to help manage Windows PE.

The development emphasis is on zero-configuration "just works" software.

## Key Features:

- Automatically install AIK 7, ADK 81 U and ADK 10
- Automatically generate WinPE images (3.1,5.1,10)
- Supports updating the following WinPE aspects:
- - Drivers
- - Packages
- - Scripts
- - Tools

## Basic Usage Guide:

1. Download and extract.
2. Start an admin cmd prompt and navigate to ADKTools\
3. Run installADK.bat to install at least one of the ADKs (not AIK 7), all 3 is preferred.
4. Run createWinPE.bat to generate updated WinPE.wim files (WDS can PXE boot these).
5. If not using WDS, run convertWim.bat to generate ISO files from WinPE.wim.
6. Then burn to optical media or for USB:
7. Use [Rufus](//rufus.akeo.ie) to make a USB drive bootable and then copy the .iso files to the USB drive

## Download:
```
Latest Version: 0.0.1-pre-alpha
In Development: 0.0.1-alpha
```
Click [here](//github.com/gdiaz384/ADKTools/releases) or on "releases" at the top to download the latest version.

## Release Notes:

- If downloading from github manually (instead of using an official release.zip) remember to change the line ending format from Unix back to Windows using Notepad++.
- Consider adding to env path

## Dependencies (included):
```
- Requires Microsoft Windows 7 or newer (but Vista will probably work)
```

## License:
Pick your License: GPL (any) or BSD (any) or MIT/Apache
