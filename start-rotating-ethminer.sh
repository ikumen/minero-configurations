#!/bin/bash
# ------------------------------------------------------------
# start-rotating-ethminer.sh 
#
# Wrapper for our custom start-ethminer.sh that rotates between 
# list of payout addresses. Note this for eth mining.
#
# Make sure to put an entry in crontab to have this run:
#
#    */5 * * * * start-rotating-ethminer.sh
#
# ------------------------------------------------------------

# Minimum threshold each address should mine until (default 0.01)
pool_payout_threshold=10000000000000000

# File holding current eth address that is being mined
current_eth_address_file="current_eth_address.txt"

# List of our eth addresses we like our payouts from 
# mining to be paid to, in a rotation
eth_addresses=(
  # TODO: put in some addresses here
  # "some address 1asdasdas"
  # "more address ...."
  # "even more addresses..."
)

# Given a current eth payout address, find it in our list
# above and return the next address on the list, or the 
# first address if the end of the list is reached.
#
# @param $1 current eth payout address
# @return the next address in list or first
#
get_next_eth_address() {
  for i in $(seq 0 ${#eth_addresses[@]}); do
    if [ "$1" == "${eth_addresses[$i]}" ]; then
      if [ $((i+=1)) -lt ${#eth_addresses[@]} ]; then
        return ${eth_addresses[$i]}
      else
        return ${eth_addresses[0]}
      fi
    fi 
  done
}

# Get our address we're currently mining to, otherwise get 
# first address on our list.
if [ -f "${current_eth_address_file}" ]; then
  current_eth_address=$(head -n 1 "${current_eth_address_file}")
else
  current_eth_address=${eth_addresses[0]}
fi

echo "Current payout address: ${current_eth_address}"

# Fetch the stats for current address (e.g. hashrate, unpaid balance)
miner_stats="${current_eth_address}.stat"
wget -O "${miner_stats}" "https://api.ethermine.org/miner/${current_eth_address}/currentStats"

# Extract just the unpaid balance
unpaid=($(grep -Po '"unpaid":[0-9]{1,}' ${miner_stats} | grep -Po '[0-9]{1,}'))
unpaid=$((unpaid+0))

# Cleanup
rm "${miner_stats}"

# If the unpaid balance is greater than, threshold, we need to 
# rotate to next address.
if [ ${unpaid} -gt ${pool_payout_threshold} ]; then
  echo "Unpaid (${unpaid}) is above the pool payout threshold (${pool_payout_threshold})"
  current_eth_address=get_next_eth_address "${current_eth_address}"

  echo ${current_eth_address} > "${current_eth_address_file}"
  export ETHMINER_ETH_PAY_ADDRESS=${current_eth_address}  

  # TODO: stop  miner
  . stop-miner.sh eth
  # TODO: restart miner 
  . start-ethminer.sh
else
  echo "Unpaid (${unpaid}) is still under threshold, continue mining .. ${current_eth_address}"
fi


