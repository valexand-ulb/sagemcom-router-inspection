#!/bin/sh
# Retrieve software versions of ipl, bootloader, operational, rescue
# (c) 2011 SAGEMCOM 
#

VERSION_SCRIPT="0.1.2"

usage="$(basename "$0") [-h] [-c] [-f]

where:
    -h      show this help text
    -c      version executed
    -f      version written in flash (should be used after firmware upgrade)
    -v      script version"

while getopts 'hvcf' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    v) echo "$VERSION_SCRIPT"
       exit
       ;;
    c) CURRENT="YES"
       ;;
    f) FLASH="YES"
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done

if [ "$CURRENT" == "$FLASH" ] && [ "$FLASH" != "$YES" ]
then
#    echo "You can't use -c option and -f option in the same time"
#    printf "illegal option: -%s\n" "$OPTARG" >&2
    echo "$usage" >&2
    exit 1
fi

if [ "$FLASH" == "YES" ] && ! [ -e /usr/sbin/ubinfo ]
then
    echo "Not possible to use -f option because ubinfo is not available"
    exit 1
fi

if [ -e /sys/class/ubi1 ]
then 
   # If ubi1 partition is present, it contains bootloaders and permanent_param
   PREFIX_UBI="ubi1_"
else 
   # One big partition
   PREFIX_UBI="ubi0_"
fi

find_header_offset () {

  D=$1

  #
  # GSDF offset format is BigEndian: read LSB (at offset 151) to MSB (at offset 148)
  # 

  # Guess endianness
  B=`head -c 4 $D 2> /dev/null | hexdump -v -e '"" "%d"'`
  if [ "$B" == "1196639302" ]
  then
    # In Big Endian system :
 
    L=`head -c 152 $D 2> /dev/null | tail -c 4 | hexdump -v -e '"" "%d"'`
    OFFSET=$(($L))

  else
    # In Little Endian system :

    L=`head -c 152 $D 2> /dev/null | tail -c 1 | hexdump -v -e '"" "%0d"'`
    if [ "$L" == "" ]
    then
       echo 0
       return
    fi
    OFFSET=$(($L))
    
    L=`head -c 151 $D 2> /dev/null | tail -c 1 | hexdump -v -e '"" "%0d"'`

    M=$(($L * 256))
    OFFSET=$(($OFFSET + $M))

    L=`head -c 150 $D 2> /dev/null | tail -c 1 | hexdump -v -e '"" "%0d"'`
    M=$(($L * 65536))
    OFFSET=$(($OFFSET + $M))

    L=`head -c 149 $D 2> /dev/null | tail -c 1 | hexdump -v -e '"" "%0d"'`
    M=$(($L * 16777216))
    OFFSET=$(($OFFSET + $M))
  fi

  OFFSET=$(($OFFSET + 64))

  echo $OFFSET
}

BCMFS_MTD=`grep \"bcmfs\" /proc/mtd | awk 'FS=":" {print $1}'`
if [ -n "$BCMFS_MTD" ]
then 
    IS_BCM=yes
fi
CFE_MTD=`grep \"cfe\" /proc/mtd | awk 'FS=":" {print $1}'`
if [ -n "$CFE_MTD" ]
then
    IS_BCM=yes
fi

if [ "$IS_BCM" = "yes" ]
then
    CFEROM_OFF=1397
    CFEROM_MTD=`grep \"nvram\" /proc/mtd | awk 'FS=":" {print $1}'`
    if [ "$CFEROM_MTD" != "" ]
    then
        CFEROM_PATTERN=`head -c $CFEROM_OFF /dev/$CFEROM_MTD | tail -c 5`
        if [ "$CFEROM_PATTERN" == "cfe-v" ]
        then
            CFEROM_V=`hexdump -n 5 -s $CFEROM_OFF -e '"" 1/1  "%d."' /dev/$CFEROM_MTD `
            IPL_V="$CFEROM_V"
        else 
            CFEROM_OFF=$(($CFEROM_OFF+65536))
            CFEROM_PATTERN=`head -c $CFEROM_OFF /dev/$CFEROM_MTD | tail -c 5`
            if [ "$CFEROM_PATTERN" == "cfe-v" ]
            then
                CFEROM_V=`hexdump -n 5 -s $CFEROM_OFF -e '"" 1/1  "%d."' /dev/$CFEROM_MTD `
                IPL_V="$CFEROM_V"

                ## SGC - JMPt : Try to find SAGEMCOM Version in cfe-rom
                IPL_SGC_VER=`strings /dev/$CFEROM_MTD | grep "Version cfe-rom:" | awk '{print $3}'`

                ## SGC - JMPt : Try to find SAGEMCOM Version in cfe-rom secure
                BCM_UP_MTD=`grep \"bcmfs_update\" /proc/mtd | awk 'FS=":" {print $1}'`
                IPL_SGC_SEC_1=`strings /dev/$BCM_UP_MTD | grep "Version cfe-rom:" | awk '{print $3}' | sed -n '1p'`
                IPL_SGC_SEC_2=`strings /dev/$BCM_UP_MTD | grep "Version cfe-rom:" | awk '{print $3}' | sed -n '2p'`
                IPL_SGC_SEC_3=`strings /dev/$BCM_UP_MTD | grep "Version cfe-rom:" | awk '{print $3}' | sed -n '3p'`
                if [ "$IPL_SGC_SEC_1" != "" ] || [ "$IPL_SGC_SEC_2" != "" ] || [ "$IPL_SGC_SEC_3" != "" ]
                then
                    ## SGC - JMPt : All SAGEMCOM Version in cfe-rom secure must be same version
                    if [ "$IPL_SGC_SEC_1" == "$IPL_SGC_SEC_2" ] && [ "$IPL_SGC_SEC_1" == "$IPL_SGC_SEC_3" ] && [ "$IPL_SGC_SEC_2" == "$IPL_SGC_SEC_3" ]
                    then
                        IPL_SGC_SEC="same"
                    else
                        IPL_SGC_SEC="differ"
                    fi
                else
                    IPL_SGC_SEC=""
                fi

            fi
        fi
    fi

    if [ "$FLASH" == "YES" ]
    then
        ## SGC - JMPt : Use $ to be sure to find secondaryboot not secondaryboot-secure
        SECONDARYBOOT_VOL=`ubinfo -a | grep -i -B 6 "secondaryboot$" | grep Volume | awk '{print $3}'`
    else
        PREFIX_UBI=""
        SECONDARYBOOT_VOL=`grep \"secondaryboot\" /proc/mtd | awk 'FS=":" {print $1}'`
    fi
    SECONDARYBOOT_SGC=`strings /dev/$PREFIX_UBI$SECONDARYBOOT_VOL  | grep "Version cfe-ram:" | awk '{print $3}'`

    ## SGC - JMPt : In old version (previous 7.15.0) secondaryboot do not contain SGC version
    if [ "$SECONDARYBOOT_SGC" == "%s" ]
    then
        SECONDARYBOOT_SGC=""
    fi

    if [ "$FLASH" == "YES" ]
    then
        ## SGC - JMPt : Use $ to be sure to find secondaryboot-secure not secondaryboot
        SECONDARYBOOT_VOL=`ubinfo -a | grep -i -B 6 "secondaryboot-secure" | grep Volume | awk '{print $3}'`
    else
        PREFIX_UBI=""
        SECONDARYBOOT_VOL=`grep \"secondaryboot-secure\" /proc/mtd | awk 'FS=":" {print $1}'`
    fi
    SECONDARYBOOT_SGC_SEC=`strings /dev/$PREFIX_UBI$SECONDARYBOOT_VOL  | grep "Version cfe-ram:" | awk '{print $3}'`

    ## SGC - JMPt : In old version (previous 7.15.0) secondaryboot do not contain SGC version
    if [ "$SECONDARYBOOT_SGC_SEC" == "%s" ]
    then
        SECONDARYBOOT_SGC_SEC=""
    fi

    if [ "$FLASH" == "YES" ]
    then
        ## SGC - JMPt : Use $ to be sure to find uboot not uboot-rescue
        BOOT_VOL=`ubinfo -a | grep -i -B 6 "uboot$" | grep Volume | awk '{print $3}'`
    else
        PREFIX_UBI=""
        BOOT_VOL=`grep \"uboot\" /proc/mtd | awk 'FS=":" {print $1}'`
    fi
    BOOT_GSDF=`head -c 8 /dev/$PREFIX_UBI$BOOT_VOL 2> /dev/null | grep GSDF`
    if [ "$BOOT_GSDF" != "" ]
    then
        BOOT_OFF=`find_header_offset /dev/$PREFIX_UBI$BOOT_VOL`
        BOOT=`head -c $(( $BOOT_OFF + 32 )) /dev/$PREFIX_UBI$BOOT_VOL 2> /dev/null | tail -c 64`
    else
        BOOT=`strings /dev/$PREFIX_UBI$BOOT_VOL  | grep Version: | head -n 1`
    fi

    BOOT_RESC=""
    if [ "$FLASH" == "YES" ]
    then
        ## SGC - JMPt : Be sure to find uboot-rescue not uboot
        BOOT_VOL_RESC=`ubinfo -a | grep -i -B 6 "uboot-rescue" | grep Volume | awk '{print $3}'`
    else
        PREFIX_UBI=""
        BOOT_VOL_RESC=`grep \"uboot-rescue\" /proc/mtd | awk 'FS=":" {print $1}'`
    fi
    if [ "$BOOT_VOL_RESC" != "" ]
    then
        BOOT_RESC_GSDF=`head -c 8 /dev/$PREFIX_UBI$BOOT_VOL_RESC 2> /dev/null | grep GSDF`
        if [ "$BOOT_RESC_GSDF" != "" ]
        then
            BOOT_RESC_OFF=`find_header_offset /dev/$PREFIX_UBI$BOOT_VOL_RESC`
            BOOT_RESC=`head -c $(( $BOOT_RESC_OFF + 32 )) /dev/$PREFIX_UBI$BOOT_VOL_RESC 2> /dev/null | tail -c 64`
        else
            BOOT_RESC=`strings /dev/$PREFIX_UBI$BOOT_VOL_RESC  | grep Version: | head -n 1`
        fi
    fi
fi

IPL_MTD=`grep ipl /proc/mtd | awk 'FS=":" {print $1}'`
if [ "$IPL_MTD" != "" ]
then
    UBI_BOOT=`strings  /dev/$IPL_MTD | grep "ubi support" | head -n 1`
fi

if [ "$UBI_BOOT" != "" ]
then
    if [ "$IPL_MTD" != "" ]
    then  
        IPL_V=`strings  /dev/$IPL_MTD | grep Version: | head -n 1`
    fi
    SPL_MTD=`grep secondaryboot /proc/mtd | awk 'FS=":" {print $1}'`
    if [ "$SPL_MTD" != "" ]
    then  
        SPL_V=`strings  /dev/$SPL_MTD | grep Version: | head -n 1`
    fi
    BOOT_MTD=`grep uboot /proc/mtd | awk 'FS=":" {print $1}'`
    if [ "$BOOT_MTD" != "" ]
    then  
        BOOT=`strings  /dev/$BOOT_MTD | grep Version: | head -n 1`
        BOOT_RESC=""
    fi
else
    if [ "$IPL_MTD" != "" ]
    then  
        IPL_V=`strings  /dev/$IPL_MTD | grep Sagemcom | head -n 1`
        BOOT=`strings  /dev/$IPL_MTD | grep U-Boot | head -n 1`
        BOOT_RESC=`strings  /dev/$IPL_MTD | grep SAGEMCOM | head -n 1`
    fi
fi


if [ "$FLASH" == "YES" ]
then
    PERM_VOL="$PREFIX_UBI"`ubinfo -a | grep -i -B 6 "permanent_param" | grep Volume | awk '{print $3}'`
else
    PERM_VOL=`grep \"permanent_param\" /proc/mtd | awk 'FS=":" {print $1}'`
fi
if [ "$PERM_VOL" != "" ]
then
    PERM_V=`head -c 8 /dev/$PERM_VOL 2> /dev/null | tail -c 4 `
fi


if [ "$FLASH" == "YES" ]
then
    OPER_VOL="ubi0_"`ubinfo -a | grep -i -B 6 "operational" | grep Volume | awk '{print $3}'`
else
    OPER_VOL=`grep \"operational\" /proc/mtd | awk 'FS=":" {print $1}'`
fi
if [ "$OPER_VOL" != "" ]
then
    OPER_OFF=`find_header_offset /dev/$OPER_VOL`
    OPER_V=`head -c $OPER_OFF /dev/$OPER_VOL 2> /dev/null | tail -c 32`
    OPER_GSDF=`head -c 8 /dev/$OPER_VOL 2> /dev/null | grep GSDF`
fi
if [ "$OPER_GSDF" != "" ]
then
    OPER_GSDF="file format is GSDF"
fi

if [ "$FLASH" == "YES" ]
then
    ## SGC - JMPt : Use [[:space:]] to be sure to find rescue not uboot-rescue
    RESC_VOL="ubi0_"`ubinfo -a | grep -i -B 6 "[[:space:]]rescue" | grep Volume | awk '{print $3}'`
else
    RESC_VOL=`grep \"rescue\" /proc/mtd | awk 'FS=":" {print $1}'`
fi
if [ "$RESC_VOL" != "" ]
then
    RESC_OFF=`find_header_offset /dev/$RESC_VOL`
    RESC_V=`head -c $RESC_OFF /dev/$RESC_VOL 2> /dev/null | tail -c 32`
    RESC_GSDF=`head -c 8 /dev/$RESC_VOL 2> /dev/null | grep GSDF`
fi
if [ "$RESC_GSDF" != "" ]
then
    RESC_GSDF="file format is GSDF"
fi

## SGC - JMPt : Try to find running software in Kernel Args
RUN_SOFT=`cat /proc/cmdline | sed 's/.*image_ubivol=*/\1/' | awk 'FS=" " {print $1}'`

echo ""
if [ "$RUN_SOFT" != "" ]
then
 echo "SOFTWARE RUNNING     : $RUN_SOFT"
else
 echo "SOFTWARE RUNNING     : UNKNOW"
fi

echo ""
if [ "$IPL_SGC_VER" != "" ]
then
 echo "CFE-ROM              : $IPL_SGC_VER (BCM = $IPL_V)"
else
 echo "IPL                  : $IPL_V"
fi
if [ "$IPL_SGC_SEC" != "" ]
then
 echo "CFE-ROM Secure       : $IPL_SGC_SEC_1"
if [ "$IPL_SGC_SEC" == "differ" ]
then
 echo "WARNING !!!   Copy 2 : $IPL_SGC_SEC_2"
 echo "Images differ Copy 3 : $IPL_SGC_SEC_3"
 echo ""
fi
fi
if [ "$SPL_V" != "" ]
then
 echo "SPL                  : $SPL_V"
fi
if [ "$SECONDARYBOOT_SGC" != "" ]
then
 echo "CFE-RAM              : $SECONDARYBOOT_SGC"
fi
if [ "$SECONDARYBOOT_SGC_SEC" != "" ]
then
 echo "CFE-RAM Secure       : $SECONDARYBOOT_SGC_SEC"
fi
 echo "BOOT                 : $BOOT"
if [ "$BOOT_RESC" != "" ]
then
 echo "BOOT rescue          : $BOOT_RESC"
fi
echo "PERMANENT Parameters : $PERM_V"
echo "OPERATIONAL software : $OPER_V  $OPER_GSDF"
echo "RESCUE software      : $RESC_V  $RESC_GSDF"
echo ""

# In case of gui partition
if [ "$FLASH" == "YES" ]
then
    PREFIX_UBI="ubi0_"
    GUI_VOL=`ubinfo -a | grep -i -B 6 "gui" | grep Volume | awk '{print $3}'`
else
    PREFIX_UBI=""
    GUI_VOL=`grep \"gui\" /proc/mtd | awk 'FS=":" {print $1}'`
fi
if [ "$GUI_VOL" != "" ]
then
    GUI_OFF=64
    GUI_V=`head -c $GUI_OFF /dev/$PREFIX_UBI$GUI_VOL 2> /dev/null | tail -c 32 | strings`
    echo "GUI                  : $GUI_V"
fi

# In case of factory test software
if [ -e /bin/mcpu_utils ]
then
    # Get Board Type
    source /bin/get_board_type.sh
    
    # Configuration for Fast3965 in LBPROV3
    if [ "$BOARD_TYPE_FAST" = "Fast3965" ] && [ "$BOARD_TYPE_SHORT" = "LBPROV3" ]
    then
        echo ""
        # Get MCPU FW Version
        GET_VERSION=`mcpu_utils -v`
        MCPU_FW_VERSION=`cat /tmp/mcpu_fw_ver.txt`
        echo "MCPU Fw Version      : $MCPU_FW_VERSION"
    
        # Test if SIM Card Present
        TEST_CONNECT=`mcpu_utils -s`
        if [ "$?" != 0 ]
        then
            echo "SIM Card             : PRESENT"
        else
            echo "SIM Card             : ABSENT"
        fi
    fi
fi

