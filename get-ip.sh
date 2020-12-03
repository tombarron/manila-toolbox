#!/bin/bash

RES=$(sudo virsh domifaddr --source lease ubuntu-focal |
      awk -F'/'  '/ipv4/ {print $1}' | awk '{print $NF}')
while [ -z $RES ]; do
  echo 'waiting 10s for ubuntu-focal IP address ...'
  sleep 10
  RES=$(sudo virsh domifaddr --source lease ubuntu-focal |
      awk -F'/'  '/ipv4/ {print $1}' | awk '{print $NF}')
done

echo "You should now be able to ssh to 'ubuntu-focal' guest at $RES"
