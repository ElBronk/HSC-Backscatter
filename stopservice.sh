readarray -t interfaces <<< $(ifconfig | grep -Po '^.*mon(?=(: flags))')

for intf in ${interfaces[@]}
do 
    echo "stopping monitor interface '${intf}'"
    sudo airmon-ng stop ${intf}
done

# return to US regulatory region
sudo iw reg set US

#sudo airmon-ng stop wlan0mon #if you used internal wifi card (wlps0mon) for monitor mode 
#sudo airmon-ng stop wlp82s0mon
sudo systemctl start NetworkManager.service
sudo nmcli networking on
