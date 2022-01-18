#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
set -e

IFACE=mhi_hwip0
# This is the device name in kernel v5.15, but it might change in other
# versions (e.g. v5.13 is /dev/wwan0p3QMI).
DEVICE=/dev/wwan0qmi0
MUX1=112
MUX2=113

# Change APNs according to your provider.
APN1=ibox.tim.it
APN2=wap.tim.it


PROFILE=0
if [[ $PROFILE == 1 ]]; then
    profile="--profile"
fi

cmd="./tqmi-connect --device $DEVICE --connect --apn $APN1 --iface $IFACE --muxid $MUX1 $profile"
echo $cmd
sudo $cmd

cmd="./tqmi-connect --device $DEVICE --connect --apn $APN2 --iface $IFACE --muxid $MUX2 $profile"
echo $cmd
sudo $cmd

QMIMUXA=$(grep QMUX_IFACE ip-session-rmnet0 | cut -d'=' -f2)
QMIMUXB=$(grep QMUX_IFACE ip-session-rmnet1 | cut -d'=' -f2)

sudo ip link set $QMIMUXA up
sudo ip link set $QMIMUXB up

ping -I $QMIMUXA -c 5 www.telit.com
[[ $? != "0" ]] && exit 1

ping -I $QMIMUXB -c 5 www.telit.com
[[ $? != "0" ]] && exit 1


cmd="./tqmi-connect --device $DEVICE --release --iface $QMIMUXA"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1

cmd="./tqmi-connect --device $DEVICE --release --iface $QMIMUXB"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1
