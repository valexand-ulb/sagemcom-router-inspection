# NAND info
Nand chip has been identified as MX25L160E

# Memory Organization

Memory is composed of 32 block of 16 sector each of 4096 bits or 512B or 0.5 KiB.

 
In term of size : 
- **Page** : 2048 b - 256B - 0,25 KiB
- **Sector** : 4096 b - 512 B - 0.5 KiB
- **Block** : 65536 b - 8192 B - 8 KiB
- **Chip** : 2097152 b - 262144 B - 256 KiB



## Sectors addresses 

Since all sector are the same size, sector offset cab be determined by : 

`Sector Offset = Sector Number × Sector Size`


For sector addresses range please refer to sectors.txt


## Blocks addresses


Since all block are the same size, block offset can be determined by : 

`Block Offset = Block Number × Block Size`

# NAND dump 

Command `nand dump` read :

```
nand dump[.oob] off - dump page
```

Command `nand info` read : 

```
f3865 > nand info

Device 0: nand0, sector size 128 KiB
  Page size      2048 b
  OOB size         64 b
  Erase size   131072 b
```
> Page size are actually 2048b, (confirmed with dump_1)
> TODO : write a python script that generate log file for each dump each `2048b = 0x800b`

## python pseudo code 

```python
total total_memory = 2097152
page_size = 2048
current_dump = 0
while current_dump < total_memory :
	logfile = create_logfile(f"dump_{hex(current_dump)}")
	launch_picocom(logfile);
	execute_through_UART(f"nand dump {hex(current_dump)}")
	print(f"dumped {hex(current_dump)} in {current_dump//page_size}.dmp ")
	current_dump += page_size



```
> You can use serial lib of python to directly use uart. Need to figure out how to wait sufficiently to gain access to u-boot and not CFE