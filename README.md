# Steps done by the script for a new connection

Default values used:

- parent network interface: wwan0
- mtu: 16384

At the end the script check if the device is connected and if not it terminates
with a non zero exit value.

## Configure the parent network interface

Flush and shutdown the interface:

    # ip addr flush wwan0
    # ip link set wwan0 down

Configure the data format on the modem side:

    # qmicli -p -d /dev/cdc-wdm0 --wda-set-data-format=link-layer-protocol=raw-ip,ul-protocol=qmap,dl-protocol=qmap,dl-max-datagrams=32,dl-datagram-max-size=16384
    ...
    Downlink data aggregation max size: '16384'

Use in following command the value returned by the previous command in the last
line, e.g. 16384, we reference to it as $MTU.

Set the MTU and the correct data format in the host parent netdevice:

    # qmicli -p -d /dev/cdc-wdm0 --set-expected-data-format=802-3
    # ip link set wwx2e6427c0dfaf mtu $MTU
    # qmicli -p -d /dev/cdc-wdm0 --set-expected-data-format=raw-ip

Create a qmux netdevice:

    # qmicli -p -d /dev/cdc-wdm0 --link-add=iface=wwan0,mux-id=112

Obtain a CID that should be used in the following commands:

    # qmicli  -p -d /dev/cdc-wdm0 --wds-noop --client-no-release-cid
    ...
    CID: '15'

Use in following commands the value returned by the previous command in the
last line, e.g. 15, we reference to it as $CID.

Bind mux data port "112":

    # qmicli -p -d /dev/cdc-wdm0 --wds-bind-mux-data-port=mux-id=112,ep-iface-number=2,ep-type=hsusb --client-no-release-cid --client-cid=$CID

Create profile (for the APN you should use the correct one, in this example is
web.omnitel.it):

    # qmicli  -p -d /dev/cdc-wdm0 --wds-create-profile=3gpp,apn=web.omnitel.it,pdp-type=IP --client-no-release-cid --client-cid=$CID
    ...
    Profile index: '6'
    ...

In should be noted that the previous command returns a profile id that is used
in this start network command:

    # qmicli  -p -d /dev/cdc-wdm0 --wds-start-network=3gpp-profile=6 --client-no-release-cid --client-cid=$CID
    ...
    Packet data handle: '1841621344'
    ...

The value "Packet data handle: '1841621344'" will be used later to disconnect the modem.

Show the IP configuration:

    # qmicli  -p -d /dev/cdc-wdm0 --wds-get-current-settings --client-no-release-cid --client-cid=$CID
        [/dev/cdc-wdm0] Current settings retrieved:
               IP Family: IPv4
            IPv4 address: 176.247.92.166
        IPv4 subnet mask: 255.255.255.252
    IPv4 gateway address: 176.247.92.165
        IPv4 primary DNS: 10.133.106.46
      IPv4 secondary DNS: 10.132.100.212
                     MTU: 1500
                 Domains: none

Use the MTU value shown in the IP configuration (in this example is 1500):

    # ip link set qmimux0 mtu 1500

Set the network address shown in the IP configuration (in this example is 176.247.92.166/30):

    # ip addr add 176.247.92.166/30 dev qmimux0

Enable the network interface:

    # ip link set wwan0 up

The network is currently DOWN, before configuring the routing for qmimux0,
remember to, bring it up (e.g. ip link set qmimux0 up)

To have multiple PDNs run the script again with a different mux-id.

## Steps done to release the connection

Release the connection:

    # qmicli -p -d /dev/cdc-wdm0 --wds-stop-network=1841621344 --client-cid=$CID

It should be noted that the value 1841621344 was returned previously by the -wds-start-network.

Shutdown the network interface:

    # ip link set wwan0 down

Delete the qmux netdevice:

    # qmicli -p -d /dev/cdc-wdm0 --link-delete=link-iface=qmimux0,mux-id=112

Delete the profile:

    # qmicli  -p -d /dev/cdc-wdm0 --wds-delete-profile=3gpp,6

The value 6 that is the profile id was returned by the previous command -wds-create-profile.
