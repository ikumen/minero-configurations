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
  
# How often to check server for new work (ethminer default is 500)
# but when using stratum we should use 2000 (see ethminer --help).
farm_recheck="2000"
# Default pool to mine at. 
pool="ethermine"
# Default currency to mine.
currency="eth"
# Default worker name.
worker="saturn"

# List of urls for pools we can mine, keyed by currency-pool.
declare -A currency_pool_url_map=(
   ["eth_ethermine"]="us2.ethermine.org:4444"
   ["eth_ethermine_alt"]="us1.ethermine.org:4444"
   ["eth_nano"]="eth-us-west1.nanopool.org:9999"
   ["eth_nano_alt"]="eth-us-east1.nanopool.org:9999"
   ["eth_maxhash"]="eth-us.maxhash.org:10011"
   ["eth_maxhash_alt"]="eth-us.maxhash.org:10011"
   ["etc_ethermine"]="us1-etc.ethermine.org:4444"
   ["etc_ethermine_alt"]="us1-etc.ethermine.org:14444"
   ["etc_nano"]="etc-us-west1.nanopool.org:19999"
   ["etc_nano_alt"]="etc-us-east1.nanopool.org:19999"
)

# Try setting required payout addresses and optional email.
# First from local environment variables...
eth_pay_address="${ETHMINER_ETH_PAY_ADDRESS}"
etc_pay_address="${ETHMINER_ETC_PAY_ADDRESS}"
notify_email="${MINER_NOTIFY_EMAIL}" # optional

# ... then from local environment file
if ![ -f "miner.env" ]; then
  source "miner.env"
fi

# Read in required/optional arguments.
while [ "$1" != "" ]; do
  case $1 in
    -c|--currency) shift currency=$1 ;;
    -p|--pool) shift pool=$1 ;;
    -d|--devices) shift devices="--cuda-devices $1" ;; # TODO: validate gpu ids
    -w|--worker) shift worker=$1 ;;
  esac
  shift
done

# Determine what we are mining and get the proper pay out address.
case ${currency} in
  "eth") pay_address="${eth_pay_address}" ;;
  "etc") pay_address="${etc_pay_address}" ;;
  *)
    echo "Unsupported currency (${currency}), supported are: [etc|eth]."
    exit 1
  ;;
esac

# Make sure we have a pay address.
if [ -z "${pay_address}" ]; then
  echo "Missing pay address for ${currency}!"
  echo "  export ETHMINER_ETH_PAY_ADDRESS=..."
  echo "   or"
  echo "  export ETHMINER_ETC_PAY_ADDRESS=..."
  exit 1
fi

# If we have a valid currency and pool, so let's lookup the corresponding pool url.
if [[ "${pool}" =~ ^(ethermine|nano|maxhash)$ ]]; then
  pool_url=${currency_pool_url_map["${currency}_${pool}"]}
  pool_url_alt=${currency_pool_url_map["${currency}_${pool}_alt"]}
else
  echo "Unsupported pool (${pool}), supported pools are: [ethermine|nano|maxhash]."
  exit 1
fi

# Construct final address/worker/email for --userpass argument 
if [ -z "${notify_email}" ]; then
  user_address="${pay_address}.${worker}/${notify_email}"
else 
  user_address="${pay_address}.${worker}"
fi

echo "..............................................."
echo "Starting ethminer with the following: ..."
echo "User=${user_address}"
echo "Pool=${pool_url} (${pool})"
if [ -z "${devices}" ]; then
   echo "Devices=all"
else
   echo "Devices=${devices}"
fi   
echo "..............................................."

# Lets backup old logs files
mkdir -p oldlogs
if [ -f "${currency}-ethminer.log" ]; then
  tstamp=$(date +%s)
  mv "${currency}-ethminer.log" "oldlogs/${currency}-ethminer.log.${tstamp}"
fi

nohup ethminer --farm-recheck ${farm_recheck} --cuda ${devices} --stratum ${pool_url} --stratum-failover ${pool_url_alt} --userpass ${user_address} >> eth-ethminer.log 2>&1 &

