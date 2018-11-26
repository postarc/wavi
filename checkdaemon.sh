#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/wavi/checkdaemon.sh

previousBlock=$(cat ~/wavi/blockcount)
currentBlock=$(/usr/local/bin/wavi-cli $1 $2 getblockcount)

/usr/local/bin/wavi-cli $1 $2 getblockcount > ~/wavi/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  /usr/local/bin/wavi-cli $1 $2 stop
  sleep 5
  /usr/local/bin/wavid -daemon $1 $2 
fi 
