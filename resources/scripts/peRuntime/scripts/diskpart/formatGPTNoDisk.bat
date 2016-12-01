clean
convert gpt
create partition efi size=300
format fs=fat32 quick label="System"
assign letter=S: noerr
create partition msr size=128
create partition pri size=1536
set id=de94bba4-06d1-4d40-a16a-bfd50179d6ac
gpt attributes=0x8000000000000001
format fs=ntfs quick label="Recovery"
assign letter=R: noerr
create part pri
format fs=ntfs quick label="Windows"
assign letter=B: noerr