#!/bin/sh
# Copyright (C) 2021 Sagemcom

mkdir  /tmp/RestoreUsername

while :
do
   if [ -e /etc/passwd+ ]; then
       echo "FileCorrupted" >/tmp/RestoreUsername/restoreUSername.txt
   else
      id Admin && id mosquitto && id wifidr
      if [ $? -eq 1 ]; then
          echo "FileCorrupted" >/tmp/RestoreUsername/restoreUSername.txt
      fi
   fi
   sleep 86400
done
