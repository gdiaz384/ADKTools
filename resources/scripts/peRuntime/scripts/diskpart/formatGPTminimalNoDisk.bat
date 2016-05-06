clean
convert gpt
create partition efi size=300
format fs=fat32 quick label="System"
assign letter=S: noerr
create partition msr size=128
create part pri
format fs=ntfs quick label="Windows"
assign letter=B: noerr