#!/bin/bash
#
# Simple script for configuring Nvidia GeForce 10 series GPU settings for mining.
#  
# configure.sh [option1 [arg1]], ... 
#
#  options:
#     -c, --curr     target currency to tweak gpus for
#
######################################################## 
currency=""
while [ "$1" != "" ]; do
   case $1 in
      -c | --curr)
         shift
         currency=$1
         ;;
   esac
   shift
done

if [ -z "$currency" ]; then
   echo "-c | --currency is required argument (supported currencies are zec,eth,etc)"
   exit 1
fi

# parse for installed gpus
IFS=$'\n' gpus=($(nvidia-smi -L))
gpu_id_model_regex="GPU ([0-9]): GeForce GTX ([0-9]{4}) .*"

# make sure we found some gpus
if [ ${#gpus[@]} -eq 0 ]; then
   echo "No supported (Nvidia GeForce 10 series) gpus found!!!"
   exit 1
fi

# enable tweaking gpus
sudo nvidia-persistenced --persistence-mode  
sudo nvidia-smi -pm ENABLED  
sudo nvidia-xconfig --enable-all-gpus
sudo nvidia-xconfig -cool-bits=28

for gpu in "${gpus[@]}"
do
   if [[ "$gpu" =~ $gpu_id_model_regex ]]; then
      id="${BASH_REMATCH[1]}"
      model="${BASH_REMATCH[2]}"

      rate_offset=0
      clock_offset=100
      power=115 # default for 1070

      # custom settings for 1070's
      if [ "$model" == "1070" ]; then
         if [ "$currency" == "zec" ]; then rate_offset=1024;
         elif [[ "$currency" =~ ^(etc|eth)$ ]]; then rate_offset=1400; fi
         power=115

      # custom settings for 1060's
      elif [ "$model" == "1060" ]; then
         if [ "$currency" == "zec" ]; then rate_offset=512;
         elif [[ "$currency" =~ ^(etc|eth)$ ]]; then rate_offset=1100; fi
         power=110
      fi

      sudo DISPLAY=:0 nvidia-smi -pl $power -i $id
      sudo DISPLAY=:0 nvidia-settings -a "[gpu:$id]/GPUMemoryTransferRateOffset[3]=$rate_offset"
      sudo DISPLAY=:0 nvidia-settings -a "[gpu:$id]/GPUGraphicsClockOffset[3]=$clock_offset"
   fi
done


