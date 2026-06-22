sudo airmon-ng stop wlp82s0mon #if you used internal wifi card (wlps0mon) for monitor mode 
sudo systemctl start NetworkManager.service
sudo nmcli networking on
