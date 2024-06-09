#!/bin/sh
# Copyright (C) 2015 Sagemcom
INTF=wl0
if [ ! -z "$1" ]; then
INTF=$1
fi
wlctl -i $INTF pavars pa2gw0a0=0xff64 pa2gw1a0=0x1656 pa2gw2a0=0xfa2e
wlctl -i $INTF pavars pa2gw0a1=0xff5c pa2gw1a1=0x1665 pa2gw2a1=0xfb1e
