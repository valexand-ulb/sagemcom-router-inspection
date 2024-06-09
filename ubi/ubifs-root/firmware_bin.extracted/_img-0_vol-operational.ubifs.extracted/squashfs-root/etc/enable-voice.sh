#!/bin/sh

if [ -f /bin/check_voice ] ;then
    check_voice
    if [ "$?" = "1" ]; then
        exit 1
    fi 
fi
exit 0
