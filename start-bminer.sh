#!/bin/bash
# -------------------------------------------------------------------------------
# Simple bminer wrapper script with support for multiple pools.  
# 
# start-bminer.sh [arg1 [val1]],...
#
#  arguments:
#     -w, --worker      name of this worker. Defaults to saturn
#     -d, --devices     list of gpus to mine with (e.g. to mine with gpus 0,1 
#                       and 4, -d "0,1,4"). Defaults to all Nvidia Geforce 10 
#                       series gpus found.
#     -p, --pool        id of pool to mine, valid pool ids are: nano,flypool. 
#                       Defaults to flypool.
#
# -------------------------------------------------------------------------------

# Default pool to mine at
pool="flypool"
# Default worker name
worker="saturn"

# Map of mining pool urls, keyed by pool name
declare -A pool_urls_map=(
  ["flypool"]="us1-zcash.flypool.org:3333"
  ["nano"]="zec-us-west1.nanopool.org:6666"
)

# Try setting payout address and notify email (optional)
# first from local environment variables ...
pay_address="${BMINER_ZEC_PAY_ADDRESS}"
notify_email="${BMINER_NOTIFY_EMAIL}"

# .. then from local env file
if [ ! -f "miner.env" ]; then
  source "miner.env"
fi

# Read in arguments
while [ "$1" != "" ]; do
  case $1 in
    -c|--currency) shift currency=$1 ;;
    -d|--devices) shift devices="-devices $1" ;;
    -w|--worker) shift worker=$1 ;;
  esac
  shift
done

# Make sure we have a pay address
if [ -z "${pay_address}" ]; then
  echo "Missing pay addres! Export the following in your profile or a miner.env file"
  echo "  export BMINER_ZEC_PAY_ADDRESS=...."
  exit 1
fi

# If we have a valid pool, lookup the pool url
if [[ "${pool}" =~ ^(flypool|nano)$ ]]; then
  pool_url=${pool_url_map[${pool}]}
else
  echo "Unsupported pool (${pool}), supported pools are: [flypool|nano]"
  exit 1
fi

# Construct final address/worker/email --userpass argument 
if [ -z "${notify_email}" ]; then
  user_address="${pay_address}.${worker}%2F${notify_email}"
else
  user_address=="${pay_address}.${worker}"
fi

echo "..............................................."
echo "Starting bminer with the following: ..."
echo "User=${user_address}"
echo "Pool=${pool_url} (${pool})"
if [ -z "${devices}" ]; then
   echo "Devices=all"
else
   echo "Devices=${devices}"
fi   
echo "..............................................."

# backup old log file
mkdir -p oldlogs
if [ -f "zec-bminer.log" ]; then
   tstamp=$(date +%s)
   mv "zec-bminer.log" "oldlogs/zec-bminer.log.$tstamp" 
fi

nohup ./bminer/bminer ${devices} -uri stratum://${user_address}@${pool_url} >> zec-bminer.log 2>&1 &

