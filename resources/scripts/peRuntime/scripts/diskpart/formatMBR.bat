select disk 0
clean
create part pri size=1536
set id=27
active
format fs=ntfs quick label="System"
assign letter=S: noerr
create partition primary
format fs=ntfs quick label="Windows"
assign letter=B: noerr