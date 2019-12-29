#!/bin/sh


while getopts "h?vi:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    i)  ignore_regexp="${OPTARG}"
        ;;
    esac
done

shift $((OPTIND-1))

net="$1"
if [ -z "${net}" ]; then
  echo "Usage: $0 [-i ignore_regexp] 10.0.0.0/24"; exit 1
fi

counter=0
rm -rf /tmp/scan
mkdir -p /tmp/scan
prev="/tmp/scan/${counter}"
curr="${prev}"
while sleep 2s; do
  echo "--------------- ${counter}  ${prev} ${curr}"
  curr="/tmp/scan/${counter}"
  nmap "${net}" -n -sP --max-retries 5 --host-timeout 3s | \
        egrep -v ${ignore_regexp} | \
        grep report | awk '{print $5}' >${curr}
  diff -u $prev $curr | egrep -v "(${curr}|${prev})"
  prev="${curr}"
  counter=$(($counter+1))
done

# fping -agq 10.8.0.0/24 # works too
