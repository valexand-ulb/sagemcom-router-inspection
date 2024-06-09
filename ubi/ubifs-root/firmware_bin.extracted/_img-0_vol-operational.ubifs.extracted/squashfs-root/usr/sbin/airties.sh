#!/bin/sh

set -e

export AIRTIES_EDGE="/airties-edge"
BBOX3_AIRTIES_OSM_SCRIPT="/usr/sbin/airties_OSM.sh"
AIRBUS_RUN=${AIRTIES_EDGE}/sbin/airbus.run
export STORAGE_FOLDER="/opt/conf/airties-edge-storage"
export AIRTIES_RUN=${AIRTIES_EDGE}/sbin/airties.run

start()
{
  if [ ! -d ${STORAGE_FOLDER} ];then
    mkdir -p ${STORAGE_FOLDER}
  fi

  ${AIRBUS_RUN} start

  if test -f "$BBOX3_AIRTIES_OSM_SCRIPT"; then
    ${BBOX3_AIRTIES_OSM_SCRIPT} start
  else
    export ENV_EDGE_STORAGE_FOLDER=${STORAGE_FOLDER}
    ${AIRTIES_RUN} start
  fi
}

stop()
{
  if test -f "$BBOX3_AIRTIES_OSM_SCRIPT"; then
    ${BBOX3_AIRTIES_OSM_SCRIPT} stop
  else
    ${AIRTIES_RUN} stop
  fi
  ${AIRBUS_RUN} stop
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
