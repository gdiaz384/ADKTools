clean
create part pri size=1024
set id=27
active
format fs=ntfs quick label="System"
assign letter=S: noerr
create partition primary
format fs=ntfs quick label="Windows"
assign letter=B: noerr