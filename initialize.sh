#!/bin/bash
declare interface

# check for saved setting
if [ -f ./backscatter.cfg ] && IFS= read -r line < ./backscatter.cfg || [[ -n "$line" ]]; then
    interface="$line"
    echo "interface = $interface"
else
    # if there is no saved setting, prompt the user
    readarray -t interfaces <<< $(ifconfig | grep -Po '^.*(?=(: flags))')

    # if no interfaces were found, can't do anything
    if ((${#interfaces} == 0)); then
        echo 'No interfaces located - exiting...'
        exit
    fi
    
    PS3="Select an interface to use: "
    select if_choice in "${interfaces[@]}"
    do
        if (( ${#if_choice} > 1 )); then
            printf 'Selecting interface %s\n' "$if_choice"
            interface="$if_choice"
            break
        fi
    done

    # ask to save
    read -p "Store the interface choice for automatic re-use on future runs? (y/n): " ans
    if [ "$ans" == 'y' -o "$ans" == 'Y' ]; then
        echo 'Saving choice...'
        $(echo ${interface} > ./backscatter.cfg)
    fi  
fi

# use the result of interface selection
echo "Proceeding with interface \"${interface}\"."

#sudo ifconfig <ifname>mon down
#sudo ifconfig <ifname> down
#sudo nmcli networking off
sudo airmon-ng check kill
sudo airmon-ng start "$interface" 3

cd wifi-injection
sudo ./venv/bin/python3 ./test-injection.py "${interface}mon" --channel 3
echo "done"


