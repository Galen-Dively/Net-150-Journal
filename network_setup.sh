#!/bin/bash

### Attempt to change hostname

read -p "Hostname For Device: " hostname # get new hostname using read prompt

# change hostname for this session
sudo hostnamectl set-hostname "$hostname"

# use the sed command to replace lines in /etc/hosts for hostname persistance
sudo sed -i "s/127.0.0.1*/127.0.0.1   localhost $hostname/" /etc/hosts

# check hostname change
check=$(hostname)

case check in
  *$hostnamey*)
      echo "Hostname has changed to '$hostname'"
      ;;
   *)
      echo "Hostname did not change succesfully"
      ;;
esac

### Changing IP info

read -p "Interface: " interface # get interface
read -p "New IP: " ip # get ip address
read -p "Subnet Mask: " mask # get netmask
read -p "Gateway: " gateway # get gateway

sudo ip addr flush dev "$interface" # get rid of existing info if any
sudo ip addr add "$ip/$mask" dev "$interface" #  add ip address and subnet mask to interface

sudo ip route add default via "$gateway" dev "$interface" # set the default gateway

echo "IP Info Has been Changed"
