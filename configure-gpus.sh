#!/bin/bash
# ..............................................................................
# Simple script for configuring Nvidia GeForce 10 series GPU settings for mining.
#  
# configure.sh [arg1 [val1]], ... 
#
#  arguments:
#     -c, --curr     target currency to tweak gpus for. Currently 
#                    supports [etc|eth|zec]. 
#
# ..............................................................................

# map of settings per gpu model/currency
declare -A currency_gpu_settings_map=(
  ["1060_power"]="110"      ["1070_power"]="115"
  ["1060_zec_rate"]="512"   ["1070_zec_rate"]="1024"   
  ["1060_zec_clock"]="100"  ["1070_zec_clock"]="100"
  ["1060_eth_rate"]="1100"  ["1070_eth_rate"]="1400"
  ["1060_eth_clock"]="100"  ["1070_eth_clock"]="100"
  ["1060_etc_rate"]="1100"  ["1070_etc_rate"]="1400"
  ["1060_etc_clock"]="100"  ["1070_etc_clock"]="100"
)

# Parse for installed gpus, specifically we are looking
# for Nvidia GeForce GTX 10 series gpus.
IFS=$'\n' gpus=($(nvidia-smi -L))

# Make sure we found some gpus
if [ ${#gpus[@]} -eq 0 ]; then
   echo "No supported (Nvidia GeForce 10 series) gpus found!!!"
   exit 1
fi

# Simple regex to find GPU id and model from nvidia-smi output.
gpu_id_model_regex="GPU ([0-9]): GeForce GTX ([0-9]{4}) .*"

# Let's get the currency we want to tweak gpu for.
while [ "$1" != "" ]; do
  case $1 in
    -c | --curr) 
      shift 
      currency=$1 
    ;;
  esac
  shift
done

# Enable tweaking gpus
sudo nvidia-persistenced --persistence-mode  
sudo nvidia-smi -pm ENABLED  
sudo nvidia-xconfig --enable-all-gpus
sudo nvidia-xconfig -cool-bits=28

# Let's start tweaking.
for gpu in "${gpus[@]}"; do
  if [[ "$gpu" =~ $gpu_id_model_regex ]]; then
    # Get the gpu id and model (e.g. 1060,1070)
    id="${BASH_REMATCH[1]}"
    model="${BASH_REMATCH[2]}"

    if [ -z "${currency_gpu_settings_map[${model}_${currency}_rate]}" ]; then
      rate_offset="${currency_gpu_settings_map[${model}_${currency}_rate]}"
      clock_offset="${currency_gpu_settings_map[${model}_${currency}_clock]}"
      power="${currency_gpu_settings_map[${model}_${currency}_power]}"

      sudo DISPLAY=:0 nvidia-smi -pl $power -i $id
      sudo DISPLAY=:0 nvidia-settings -a "[gpu:$id]/GPUMemoryTransferRateOffset[3]=$rate_offset"
      sudo DISPLAY=:0 nvidia-settings -a "[gpu:$id]/GPUGraphicsClockOffset[3]=$clock_offset"
    else
      echo "Unable to find proper gpu setting for currency=${currency}, gpu=${model}!"
      echo "Please make sure currency is set to [etc|eth|zec]"
      exit 1
    fi
  fi
done


