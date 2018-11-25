#!/bin/bash

COIN='https://github.com/wavidev-the-man/wavi/releases/download/v0.12.2.4reup/wavicore-0.12.2.4-ubuntu64.tar.gz'
COIN_NAME='wavicore-0.12.2.4-ubuntu64.tar.gz'
RPCPORT=9982
PORT=9983
CONFIG_FILE='wavi.conf'
if [[ "$USER" == "root" ]]; then
        CONFIGFOLDER="/root/.wavicore"
		SCRIPTFOLDER="/root/wavi"
 else
        CONFIGFOLDER="/home/$USER/.wavicore"
		SCRIPTFOLDER="/home/$USER/wavi"
fi
BINFOLDER='/usr/local/bin/'

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m" 
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

cd ~
if [ -n "$(ps -u $USER | grep wavid)" ] && [ -d $CONFIGFOLDER ] ; then
  echo -e "${RED}Wavi daemon is already installed.${NC} Remove folder .wavicore and stop the daemon and try again.{NC}"
  exit 1
else 
  sudo chown -R $USER:$USER ~/
fi
# Start installation
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt update && sudo apt upgrade -y 
sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev 
sudo apt install -y libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev nano git 
sudo apt install -y libminiupnpc-dev libzmq5
sudo apt-get install -y pwgen

mkdir ~/wavi
mkdir ~/.wavicore
cd ~/wavi
wget $COIN
tar xvzf $COIN_NAME
rm $COIN_NAME

if [ ! -f "$BINFOLDER/wavid" ]; then
	echo -e "{GREEN}Copying bin files...{NC}"
	sudo cp wavi* $BINFOLDER
	sudo chown -R root:users $BINFOLDER
else
	echo -e "{GREEN}Bin files exist. Skipping copy...{NC}"
fi
rm wavi*

# writing wavi.conf file:
echo -e "{GREEN}Writing wavi config file...{NC}"
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $RPCPORT)" ]
do
(( RPCPORT--))
done
echo -e "{GREEN}Free RPCPORT address:$RPCPORT{NC}"
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $PORT)" ]
do
(( PORT++))
done
echo -e "{GREEN}Free MN port address:$PORT{NC}"
NODEIP=$(curl -s4 icanhazip.com)
GEN_PASS=`pwgen -1 20 -n`
echo -e "rpcuser=waviuser$PORT\nrpcpassword=${GEN_PASS}\nrpcport=$RPCPORT\nexternalip=$NODEIP:9983\nport=$PORT\nlisten=1\nmaxconnections=256" > $CONFIGFOLDER/$CONFIG_FILE
# set masternodeprivkey
wavid -daemon
sleep 17
MASTERNODEKEY=$(./wavi-cli masternode genkey)
echo -e "masternode=1\nmasternodeprivkey=$MASTERNODEKEY\n" >> $CONFIGFOLDER/$CONFIG_FILE
#echo "addnode=explorer.wavicoin.info\n" >>  $CONFIGFOLDER/$CONFIG_FILE
wavi-cli stop
echo "addnode=203.189.97.135\naddnode=5.14.40.222\naddnode=188.168.4.8\naddnode=212.164.197.117\naddnode=203.189.97.135\naddnode=59.26.73.202\naddnode=92.124.134.38\naddnode=119.130.34.208\naddnode=31.14.135.157">> $CONFIGFOLDER/$CONFIG_FILE

# installing SENTINEL
echo -e "{GREEN}Start Sentinel installing process...{NC}"
cd ~/.wavicore
sudo apt-get install -y git python-virtualenv
git clone https://github.com/wavicom/sentinel.git
cd sentinel
export LC_ALL=C
sudo apt-get install -y virtualenv
virtualenv venv
venv/bin/pip install -r requirements.txt
echo -e "wavi_conf=$CONFIGFOLDER/$CONFIG_FILE" >> sentinel.conf

# get mnchecker
cd ~
#git clone https://github.com/wavicointeam/mnchecker ~/mnchecker
# setup cron
crontab -l > tempcron
echo -e "@reboot $BINFOLDER/wavid -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER" > tempcron
echo -e "* * * * * cd $CONFIGFOLDER/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log" >> tempcron
echo -e "*/1 * * * * $SCRIPTFOLDER/makerun.sh -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER" >> tempcron
echo -e "*/30 * * * * $SCRIPTFOLDER/checkdaemon.sh -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER" >> tempcron
crontab tempcron

rm tempcron
#rm wavi/install.sh
echo -e "{GREEN}VPS ip: $NODEIP{NC}"
echo -e "{GREEN}Masternode private key: $MASTERNODEKEY{NC}"
echo -e "{GREEN}Job completed successfully{NC}" 
