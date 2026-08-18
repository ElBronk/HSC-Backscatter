#!/bin/bash
declare txInterface
declare rxInterface

# if there is no saved setting, prompt the user
readarray -t interfaces <<< $(ifconfig | grep -Po '^.*(?=(: flags))')

# if no interfaces were found, can't do anything
if ((${#interfaces} == 0)); then
    echo 'No interfaces located - exiting...'
    exit
fi

PS3="Select an interface to use for transmitting: "
select if_choice in "${interfaces[@]}"
do
    if (( ${#if_choice} > 1 )); then
        printf 'Selecting interface %s\n' "$if_choice"
        txInterface="$if_choice"
        break
    fi
done

PS3="Select an interface to use for receiving: "
select if_choice in "${interfaces[@]}"
do
    if (( ${#if_choice} > 1 )); then
        printf 'Selecting interface %s\n' "$if_choice"
        rxInterface="$if_choice"
        break
    fi
done

# use the result of interface selection
echo "Proceeding with interfaces tx: \"${txInterface}\", rx: \"${rxInterface}\"."
read -p "Enter the channel to use for transmitting: " txChannel
read -p "Enter the channel to use for receiving: " rxChannel
echo "Using channels ${txChannel} (tx) and ${rxChannel} (rx)"

# enter a different regulatory territory so we dont have any ch13 issues
sudo iw reg set DE

#sudo ifconfig <ifname>mon down
#sudo ifconfig <ifname> down
#sudo nmcli networking off
sudo airmon-ng check kill
sudo airmon-ng start "$txInterface" "$txChannel"

# if adding 'mon' to the end would exceed linux's 15 char limit, expect wlan0 to become name
if ((${#txInterface} > 12)); then
    txInterface='wlan0'  # assume there are no other wlan's around
fi

echo "About to inject packets; Waiting 10s to allow for Wireshark to be started..."
sleep 10
echo "Done sleeping; beginning injection"

# cause switch to 802.11b
cd wifi-injection
source "./venv/bin/activate"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
sudo ./venv/bin/python3 ./test-injection.py "${txInterface}mon" --channel "$txChannel"
echo "done"

# enable reciever 
sudo ifconfig ${rxInterface} up
sudo airmon-ng check kill
sudo airmon-ng start "${rxInterface}" "$rxChannel"

if ((${#rxInterface} > 12)); then
    # assumes no other wlan interfaces around other than tx
    if ((${#txInterface} > 12)); then
        rxInterface='wlan1'  
    else 
        rxInterface='wlan0'
    fi
fi

# manually up this new monitor interface
sudo ifconfig "${rxInterface}mon" up

# start transmitting
cd ../
sudo ./inject_ch3

