select disk 0
clean
create partition primary
active
format fs=ntfs quick label="Windows"
assign letter=B: noerr