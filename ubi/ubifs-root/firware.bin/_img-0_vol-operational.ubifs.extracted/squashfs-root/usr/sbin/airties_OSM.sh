#!/bin/sh

set -e

JAIL="/tmp/airties-chroot"
BIN="/bin"
USR_BIN="/usr/bin"
USR_SBIN="/usr/sbin"
USR_LIB="/usr/lib"
LIB="/lib"
PROC="/proc"
DEV="/dev"
SYS="/sys"
SYS_MODULE=${SYS}/module
AIRBUS=${SYS}/class/airbus
AIRBUS_COMMAND=${SYS_MODULE}/airbus_command
AIRBUS_EVENT=${SYS_MODULE}/airbus_event
TMP="/tmp"
CHROOT_PERSIST="/airties-persist"
TMP_AIRTIES=${TMP}${AIRTIES_EDGE}
JAIL_BIN=${JAIL}${BIN}
JAIL_USR_BIN=${JAIL}${USR_BIN}
JAIL_USR_SBIN=${JAIL}${USR_SBIN}
JAIL_USR_LIB=${JAIL}${USR_LIB}
JAIL_LIB=${JAIL}${LIB}
JAIL_PROC=${JAIL}${PROC}
JAIL_PERSIST=${JAIL}${CHROOT_PERSIST}
JAIL_DEV=${JAIL}${DEV}
JAIL_TMP=${JAIL}${TMP}
JAIL_TMP_AIRTIES=${JAIL}${TMP_AIRTIES}
JAIL_EDGE=${JAIL}${AIRTIES_EDGE}
SQUASHFS="/opt/squashfs"
MOUNT_BIND="mount --bind"
IP_LINK_CMD="ip link"
PHYS_DEV="veth_controller"
VIRTUAL_INTERFACE="veth_br_lan"
VETH_INTERFACE_PATH=${SYS}/class/net/${PHYS_DEV}
JAIL_ETC=${JAIL}/etc
IEEE1905_MULTICAST_MAC="01:80:c2:00:00:13"
IEEE1905_PROTOCOL="0x893a"
EBT_FORWARD="ebtables -A FORWARD"
EBT_OUTPUT="ebtables -A OUTPUT"

start()
{
  if [ ! -d ${VETH_INTERFACE_PATH} ] ; then
    ${IP_LINK_CMD} add dev ${PHYS_DEV} type veth peer name ${VIRTUAL_INTERFACE}
    ${IP_LINK_CMD} set dev ${PHYS_DEV} up
    ${IP_LINK_CMD} set ${VIRTUAL_INTERFACE} up
    brctl addif BR_LAN ${VIRTUAL_INTERFACE}
    ${EBT_FORWARD} -o ${VIRTUAL_INTERFACE} -p ${IEEE1905_PROTOCOL} -j ACCEPT
    ${EBT_FORWARD} -o ${VIRTUAL_INTERFACE} -j DROP
    ${EBT_FORWARD} -i !${VIRTUAL_INTERFACE} -p ${IEEE1905_PROTOCOL} -d ${IEEE1905_MULTICAST_MAC} -j DROP
    ${EBT_OUTPUT} -o ${VIRTUAL_INTERFACE} -p ${IEEE1905_PROTOCOL} -j ACCEPT
    ${EBT_OUTPUT} -o ${VIRTUAL_INTERFACE} -p 0x88cc -j ACCEPT
    ${EBT_OUTPUT} -o ${VIRTUAL_INTERFACE} -j DROP
  fi

  if [ ! -d ${JAIL} ] ; then
    mkdir -p ${JAIL_BIN} ${JAIL_LIB} ${JAIL_PROC} ${JAIL_PERSIST} ${JAIL_DEV} \
    ${JAIL_USR_BIN} ${JAIL_USR_SBIN} ${JAIL_USR_LIB} ${JAIL_TMP} ${JAIL_EDGE} \
    ${JAIL}${AIRBUS} ${JAIL}${AIRBUS_COMMAND} ${JAIL}${AIRBUS_EVENT} \
    ${JAIL_TMP_AIRTIES} ${TMP_AIRTIES} ${JAIL_ETC}

    ${MOUNT_BIND} ${SQUASHFS}${AIRTIES_EDGE} ${JAIL}${AIRTIES_EDGE}
    ${MOUNT_BIND} ${SQUASHFS}${BIN} ${JAIL_BIN}
    ${MOUNT_BIND} ${SQUASHFS}${USR_BIN} ${JAIL_USR_BIN}
    ${MOUNT_BIND} ${SQUASHFS}${USR_SBIN} ${JAIL_USR_SBIN}
    ${MOUNT_BIND} ${SQUASHFS}${USR_LIB} ${JAIL_USR_LIB}
    ${MOUNT_BIND} ${SQUASHFS}${LIB} ${JAIL_LIB}
    ${MOUNT_BIND} ${STORAGE_FOLDER} ${JAIL_PERSIST}
    ${MOUNT_BIND} ${DEV} ${JAIL_DEV}
    ${MOUNT_BIND} ${PROC} ${JAIL_PROC}
    ${MOUNT_BIND} ${TMP_AIRTIES} ${JAIL_TMP_AIRTIES}
    ${MOUNT_BIND} ${AIRBUS} ${JAIL}${AIRBUS}
    ${MOUNT_BIND} ${AIRBUS_COMMAND} ${JAIL}${AIRBUS_COMMAND}
    ${MOUNT_BIND} ${AIRBUS_EVENT} ${JAIL}${AIRBUS_EVENT}

    cat> ${JAIL_ETC}/resolv.conf <<EOL
nameserver 127.0.0.1
nameserver ::1
EOL
  fi

  chroot ${JAIL} << EOF
    export ENV_EDGE_STORAGE_FOLDER=${CHROOT_PERSIST}
    ${AIRTIES_RUN} start
    ${AIRTIES_EDGE}${USR_SBIN}/airdata-cli -e "setpv Device.X_AIRTIES_Obj.MultiAPController.InterfaceList ${PHYS_DEV}"
EOF
}

stop()
{
  if [ -d ${VETH_INTERFACE_PATH} ] ; then
    ${IP_LINK_CMD} delete ${PHYS_DEV}
  fi
  ${AIRTIES_RUN} stop
}

case "$1" in
	start)
		start
		;;

	stop)
		stop
		;;

	restart)
		stop
		start
		;;
  *)
    echo "Unknown command. [start|stop|restart]"
    exit 1
    ;;
esac
