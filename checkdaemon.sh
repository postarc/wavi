#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/wavi/checkdaemon.sh

previousBlock=$(cat ~/wavi/blockcount)
currentBlock=$(wavi-cli $1 $2 getblockcount)

wavi-cli $1 $2 getblockcount > ~/wavi/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  wavi-cli $1 $2 stop
  sleep 5
  wavid -daemon $1 $2 
fi 
