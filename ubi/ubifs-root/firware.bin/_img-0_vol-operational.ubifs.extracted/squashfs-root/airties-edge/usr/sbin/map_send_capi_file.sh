#!/bin/sh

# Create sendWFACAPI map_cli command with args from a file.

if [ -z "$1" ]; then
  echo "usage: $0 capi_file"
  exit 0
fi

capi_cmd=`cat ${1}`

cli_cmd="map_cli --command sendWFACAPI --payload '{\"args\":\"${capi_cmd}\"}'"

sh -c "${cli_cmd}"
