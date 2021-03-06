#!/bin/bash

## Run this: 
## sudo cat * && sudo wget https://raw.githubusercontent.com/benyanke/configScripts/master/General%20Tidbits/Networking%20Restart/setupNetworkCheck.sh && sudo chmod 111 setupNetworkCheck.sh && sudo ./setupNetworkCheck.sh && sudo rm setupNetworkCheck.sh && echo COMPLETE && exit; echo ERROR;

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


mkdir "/home/benyanke/scripts";
touch "/home/benyanke/scripts/restartNetwork.sh"

wget "https://raw.githubusercontent.com/benyanke/configScripts/master/General%20Tidbits/Networking%20Restart/restartNetwork.sh"  -O "/home/benyanke/scripts/restartNetwork.sh"

chmod 111 "/home/benyanke/scripts/restartNetwork.sh"

crontab -l | { cat; echo "* * * * * /bin/bash /home/benyanke/scripts/restartNetwork.sh >/dev/null 2>&1"; } | crontab -

echo "Successfully added network checker and scheduled to run every minute";
