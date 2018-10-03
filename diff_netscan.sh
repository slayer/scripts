#!/bin/sh

net="$1"
if [ -z "${net}" ]; then
  echo "Usage: $0 10.0.0.0/24"; exit 1
fi

counter=0
rm -rf /tmp/scan
mkdir -p /tmp/scan
prev="/tmp/scan/${counter}"
curr="${prev}"
while sleep 2s; do
  echo "--------------- ${counter}  ${prev} ${curr}"
  curr="/tmp/scan/${counter}"
  nmap "${net}" -n -sP | grep report | awk '{print $5}' >${curr}
  diff -u $prev $curr
  prev="${curr}"
  counter=$(($counter+1))
done
