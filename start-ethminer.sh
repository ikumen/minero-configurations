#!/bin/bash

DEVICES=""
STRATUM="us2.ethermine.org:4444"
STRATUM_FAILOVER="us1.ethermine.org:4444"
ADDRESS="0x97416786E41A98Bb5634CDff8E04Dc8E4fD81A24"
FARM_RECHECK="200"
WORKER="saturn"
USER="$ADDRESS.$WORKER"

while [ "$1" != "" ]; do
   case $1 in
      -d | --devices)  
         shift
         DEVICES="--cuda-devices $1"
         ;;
      -p | --pool)
         shift
         if [ "$1" == "nano" ]; then
            STRATUM="eth-us-west1.nanopool.org:9999"
            STRATUM_FAILOVER="eth-us-east1.nanopool.org:9999"
            USER="$USER/thong@gnoht.com"
         elif [ "$1" == "maxhash" ]; then
            STRATUM="eth-us.maxhash.org:10011"
            STRATUM_FAILOVER="eth-us.maxhash.org:10011"
         fi
         ;;
   esac
   shift
done

echo "ADDRESS=$ADDRESS"
echo "POOL=$STRATUM"
if [ "$DEVICES" == "" ]; then
   echo "DEVICES=all"
else
   echo "DEVICES=$DEVICES"
fi   

nohup ethminer --farm-recheck $FARM_RECHECK --cuda $DEVICES --stratum $STRATUM --stratum-failover $STRATUM_FAILOVER --userpass $USER >> eth-ethminer.log 2>&1 &

