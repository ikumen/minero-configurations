#!/bin/bash
# ......................................................
# Little helper for killing a miner process.
#
# ......................................................


if [ -z $1 ]; then
  ps aux | grep -i "ethminer\|bmin" | awk {'print $2, $11'}
else
  ps aux | grep -i "$1" | awk {'print $2'} | xargs kill -9
fi
