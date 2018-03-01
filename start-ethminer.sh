#!/bin/bash
# ----------------------------------------------------------------------
# Simple ethminer wrapper script with support for multiple pools.  
# 
# start-ethminer.sh [optional|required [arg]],...
#
#  required:
#     -a, --address     address for mining payouts
#     -w, --worker      name of this worker
#
#  optional:
#     -d, --devices     list of gpus to mine with (e.g. to mine with gpus 0,1 
#                       and 4, -d "0 1 4"). Defaults to all Nvidia Geforce 10 
#                       series gpus found.
#     -p, --pool        id of pool to mine, valid pool ids are: nano, maxhash, 
#                       ethermine. Defaults to ethermine.
#     -e, --email       your email (for outage notification), some pools require
#                       manual configuration (e.g. ethermine) 
#
# ----------------------------------------------------------------------
STRATUM="us2.ethermine.org:4444"
STRATUM_FAILOVER="us1.ethermine.org:4444"
FARM_RECHECK="200"
ADDRESS="${ETHMINER_ETH_ADDRESS}"
EMAIL="${ETHMINER_EMAIL}"
WORKER="${ETHMINER_WORKER}"
DEVICES=""
USER=""

while [ "$1" != "" ]; do
   case $1 in
      -d | --devices)  # optional, defaults to all gpus
         shift
         DEVICES="--cuda-devices $1"
         ;;
      -p | --pool)     # optional, defaults to ethermine.org
         shift
         if [ "$1" == "nano" ]; then
            STRATUM="eth-us-west1.nanopool.org:9999"
            STRATUM_FAILOVER="eth-us-east1.nanopool.org:9999"
         elif [ "$1" == "maxhash" ]; then
            STRATUM="eth-us.maxhash.org:10011"
            STRATUM_FAILOVER="eth-us.maxhash.org:10011"
         fi
         ;;
      -e | --email)    # optional, some pools use web interface to enter email
         shift
         EMAIL="$1"
         ;;
      -a | --address)  # required
         shift
         ADDRESS="$1" 
         ;;
      -w | --worker)   # required
         shift
         WORKER="$1"
         ;;
   esac
   shift
done

# address & worker not found as environment variable or cmd line argument
if [ -z "$ADDRESS" ] || [ -z "$WORKER" ]; then
   echo "'address' and 'worker' are required parameters."
   echo "Usage: ./start-ethminer.sh -a \"your_address\" -w \"your_worker\""
   exit 1
fi

# construct final address/worker/email --userpass argument 
[[ -z "$EMAIL" ]] && USER="$ADDRESS.$WORKER/$EMAIL" || USER="$ADDRESS.$WORKER"

echo "..............................................."
echo "Starting ethminer with the following: ..."
echo "USER=$USER"
echo "POOL=$STRATUM"
if [ "$DEVICES" == "" ]; then
   echo "DEVICES=all"
else
   echo "DEVICES=$DEVICES"
fi   
echo "..............................................."

nohup ethminer --farm-recheck $FARM_RECHECK --cuda $DEVICES --stratum $STRATUM --stratum-failover $STRATUM_FAILOVER --userpass $USER >> eth-ethminer.log 2>&1 &

