${TOC}
# Introduction
After inspection of the u-boot environment variables via `printenv`. We rearranged the various variables and cleaned everything up to make it look clearer. We provided a basic explanation (📖) and hypotheses (💡).
You can find the less explanatory text version in the same folder.
# Variables
```
_platform=sc_bcm63xxx											

baudrate=115200
bootargs=### no default boot args ###
bootcmd=sb
bootdelay=3
ethact=BCM63xxx
ethaddr=00:01:02:03:04:05

ipaddr=192.168.1.1

mtdparts=mtdparts=nand:768k(bcm),125184k(partAll),5120k(data)
netretry=once

part_boot=partAll
part_main=partAll

serverip=192.168.1.10

stderr=serial
stdin=serial
stdout=serial
```
> 💡
>  - hardware platform, [Broadcom BCM63xx](https://openwrt.org/docs/techref/hardware/soc/soc.broadcom.bcm63xx#broadcom_bcm63xx)
> - mtdparts :  Defines partitions for NAND flash memory.
> - part_boot & part_main : partitions for booting and main usage, set to partAll 
> - netretry : Network retry policy, set to retry once
> - tftp server provably on : 192.168.1.10
> - stderr, stdin, stdout: I/O redirection, all set to serial, (UART ?)

# Commands

## Simple commands
Command with at most one operation

### UBI related
<a id='partAll'></a>

`UBI` - Unsorted Block Images
```
_select_boot=ubi part partAll
_select_main=ubi part partAll
```
> 📖
> Selects the partAll UBI partition for boot / main operations.

### TFTP related
`tftpboot` - boot image via network using TFTP protocol

```
_tftp_gsdf_oper=tftpboot sc_bcm63xxx.scos.oper.gsdf
_tftp_gsdf_resc=tftpboot sc_bcm63xxx.scos.resc.gsdf
```
> 💡
> - **gsdl** : General distribution format ?
> - **oper** :  Operational ?
> - **resc** : Rescue  ?

```
_tftp_ipl=tftpboot sc_bcm63xxx.fboot.fbin	
_tftp_oldipl=tftpboot sc_bcm63xxx.oldfboot.fbin
```
>💡
> - **ipl** : Initial Program Load ?


```
_tftp_uboot=tftpboot sc_bcm63xxx.u-boot.bin
_tftp_olduboot=tftpboot sc_bcm63xxx.oldu-boot.bin
```

```
_tftp_oper=tftpboot sc_bcm63xxx.scos.oper.secure
```
> 💡
> - **scos** : Specialized Core Operating System ?


```
_tftp_pp=tftpboot sc_bcm63xxx.ppBIN
```
> 💡
> - **pp** : Permanent parameters ? Later refered to permanent_parameter [here](#permanent)


```
_tftp_resc=tftpboot sc_bcm63xxx.scos.resc.secure
```
> 💡
> - none

```
_tftp_spl=tftpboot sc_bcm63xxx.sboot.sbin
```
> 💡
> - **spl** : Secondary Program Loader ? Later refered to secondary boot [here](#secondaryboot)

## Composed commands
Commands with at least two operations

### UBI related

#### `ubi_eraze`
```
_ubi_eraze=
	nand erase 0xC0000 0x7A40000;
	run _select_main
```
> 📖
>  Erases specified NAND memory range and selects the main UBI partition [partAll](#partAll).
>  💡
>  Memory range seems to be : ??


#### `ubi_mkvol`
```
_ubi_mkvol1=
	ubi create operational 0x1f00000 static
```
> 📖
>  Creates a UBI volume named operational with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB

```
_ubi_mkvol2=
	ubi create permanent_param 0x1f000 static;
	ubi create rescue 0x1f00000 static
```
> 📖
>  Creates a UBI volume named permanent_param with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiBB
>  Creates a UBI volume named rescue with size `0x1f00000` =  32505856 bits = 4063232 B = 4,063232 MB


#### `_write_x`
```
_write_oper=
	ubi remove operational;
	ubi create operational 0x1f00000 static;
	ubi write 0x80400000 operational ${filesize}
```
> 📖
> Remove previous volume operational
>  Creates a UBI volume named operational with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB
>  Write volume from address `0x80400000` with size `${filesize}`
<a id='permanent'></a>
```
_write_pp=
	ubi remove permanent_param;
	ubi create permanent_param 0x1f000 static;
	ubi write 0x80400000 permanent_param ${filesize}
```
> 📖
> Remove previous volume permanent_param
>  Creates a UBI volume named permanent_param with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB
>  Write volume from address `0x80400000` with size `${filesize}`

```
_write_resc=
	ubi remove rescue;
	ubi create rescue 0x1f00000 static;
	ubi write 0x80400000 rescue ${filesize}
```
> 📖
> Remove previous volume  rescue
>  Creates a UBI volume named  rescue with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB
>  Write volume from address `0x80400000` with size `${filesize}`

<a id='secondaryboot'></a>
```
_write_spl=
	ubi remove secondaryboot;
	ubi create secondaryboot ${filesize} static;
	ubi write 0x80400000 secondaryboot ${filesize}
```
> 📖
> Remove previous volume secondaryboot
>  Creates a UBI volume named secondaryboot with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB
>  Write volume from address `0x80400000` with size `${filesize}`


```
_write_uboot=
	ubi remove uboot;
	ubi remove bootenv;
	ubi create uboot ${filesize} static;
	ubi write 0x80400000 uboot ${filesize}
```
> 📖
> Remove previous volume uboot & bootenv
>  Creates a UBI volume named uboot with size `0x1f00000` =  32505856 bits = 4063232 B = 3968 KiB =  3,875 MiB
>  Write volume from address `0x80400000` with size `${filesize}`

### NAND related
```
_write_ipl=
	nand erase 0x00000 0x20000;
	nand write 0x80400000 0x00000 0x9000

```
> 📖
>  Erase `0x20000` bytes (131072b or 16384B or 16 KiB) from offset `0x00000`
>  Write `0x9000`  bytes (36864b or 4608B or 4,5 KiB) starting at offset `0x00000` to address `0x80400000`

```
_write_oldipl=
	nand erase 0x00000 0x20000;
	nand write 0x80400000 0x00000 0x20000
```
> 📖
>  Erase `0x20000` bytes (131072b or 16384B or 16 KiB) from offset `0x00000`
>  Write `0x2000`  bytes (8192b or 1024B or 1 KiB) starting at offset `0x00000` to address `0x80400000`

```
_write_olduboot=
	nand erase 0x40000 0x80000;
	nand write 0x80400000 0x40000 0x60000
```
> 📖
>  Erase `0x80000` bytes (524288b or 65536B or 64 KiB) from offset `0x40000`
>  Write `0x60000`  bytes (393216b or 49152B or 48 KiB) starting at offset `0x40000` to address `0x80400000`


### Cumulatives

```
load_allboot=
	run _select_boot
	_tftp_uboot 
	_tftp_spl 
	_tftp_ipl 
	_tftp_uboot 
	_write_uboot 
	_tftp_spl 
	_write_spl 
	_tftp_ipl 
	_write_ipl
```
```
load_gsdf_oper=
	run _select_main 
	_tftp_gsdf_oper 
	_write_oper

load_gsdf_resc=
	run _select_main 
	_tftp_gsdf_resc 
	_write_resc
```

```
load_ipl=
	run _tftp_ipl
	_write_ipl
	
load_oldipl=
	run _tftp_oldipl
	_write_oldipl
```

```
load_oldboot=
	run _select_boot 
	_tftp_olduboot  
	_tftp_oldipl 
	_tftp_olduboot 
	_write_olduboot 
	_tftp_oldipl 
	_write_oldipl
	
load_olduboot=
	run _tftp_olduboot 
	_write_olduboot
	
load_oper=
	run _select_main 
	_tftp_oper 
	_write_oper
	
load_pp=
	run _select_main 
	_tftp_pp 
	_write_pp

load_resc=
	run _select_main 
	_tftp_resc 
	_write_resc

load_spl=
	run _select_boot 
	_tftp_spl 
	_write_spl

load_uboot=
	run _select_boot 
	_tftp_uboot 
	_write_uboot

reset_env=
	run _select_boot;
	ubi remove bootenv;
	ubi create bootenv 0x1f000

ubi_init=
	run _ubi_eraze;
	run _ubi_mkvol1;
	run _ubi_mkvol2
```


# Conclusion : 

UBI volumes :
- uboot
- secondaryboot
- permanent_param
- operational
- rescue


