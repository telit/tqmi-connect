#!/usr/bin/env bash
# -*- coding: UTF-8 -*-

IFACE=wwan0
APN1=web.omnitel.it
APN2=mobile.vodafone.it
MUX1=112
MUX2=113
PROFILE=0

if [[ $(ls /dev/cdc-wdm* | wc -l) -gt 1 ]]; then
    echo [!] Automatic tests require only 1 modem connected
    exit 1
fi

device=$(ls /dev/cdc-wdm*)

if [[ $PROFILE == 1 ]]; then
    profile="--profile"
fi

cmd="./tqmi-connect --device $device --connect --apn $APN1 --iface $IFACE --muxid $MUX1 $profile"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1

cmd="./tqmi-connect --device $device --connect --apn $APN2 --iface $IFACE --muxid $MUX2 $profile"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1

QMIMUXA=$(grep QMUX_IFACE ip-session-qmimux0 | cut -d'=' -f2)
QMIMUXB=$(grep QMUX_IFACE ip-session-qmimux1 | cut -d'=' -f2)

sudo ip link set $QMIMUXA up
sudo ip link set $QMIMUXB up

ping -I $QMIMUXA -c 5 www.telit.com
[[ $? != "0" ]] && exit 1

ping -I $QMIMUXB -c 5 www.telit.com
[[ $? != "0" ]] && exit 1


cmd="./tqmi-connect --device $device --release --iface $QMIMUXA"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1

cmd="./tqmi-connect --device $device --release --iface $QMIMUXB"
echo $cmd
sudo $cmd
[[ $? != "0" ]] && exit 1
