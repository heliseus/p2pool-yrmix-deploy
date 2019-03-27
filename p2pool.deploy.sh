#!/bin/bash
# Author: Chris Har
# Thanks to all who published information on the Internet!
#
# Disclaimer: Your use of this script is at your sole risk.
# This script and its related information are provided "as-is", without any warranty, 
# whether express or implied, of its accuracy, completeness, fitness for a particular 
# purpose, title or non-infringement, and none of the third-party products or information 
# mentioned in the work are authored, recommended, supported or guaranteed by The Author. 
# Further, The Author shall not be liable for any damages you may sustain by using this 
# script, whether direct, indirect, special, incidental or consequential, even if it 
# has been advised of the possibility of such damages. 
#

#
# NOTE:
# This script is based on:
# - Git Commit: 18dc987 => https://github.com/dashpay/p2pool-dash
# - Git Commit: 20bacfa => https://github.com/dashpay/dash
#
# You may have to perform your own validation / modification of the script to cope with newer 
# releases of the above software.
#
# Tested with Ubuntu 17.10
#

#
# Variables
# UPDATE THEM TO MATCH YOUR SETUP !!
#
PUBLIC_IP=46.105.148.127
EMAIL=heliseus76@gmail.com
PAYOUT_ADDRESS=YkruWhJibHJKkF4vn3KCmnkkz8sLYHA6RE
USER_NAME=yrmix
RPCUSER=yrmixcoin
RPCPASSWORD=dfgdfalkasadfg65adf6gad3f1g6adf5g4

FEE=0.5
DONATION=0
YRMIX_WALLET_URL=https://github.com/heliseus/yrmixcoin/releases/tag/v1.0.0.0/yrmixcore-linux64.tar.gz
YRMIX_WALLET_ZIP=yrmixcore-linux64.tar.gz
YRMIX_WALLET_LOCAL=yrmixcore
#P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
#P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
#P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

#
# Install Prerequisites
#
cd ~
sudo apt-get --yes install python-zope.interface python-twisted python-twisted-web python-dev
sudo apt-get --yes install gcc g++
sudo apt-get --yes install git

#
# Get latest p2pool-DASH
#
mkdir git
cd git
git clone https://github.com/heliseus/p2pool-yrmix
cd p2pool-yrmix
git clone https://github.com/heliseus/yrmix-hash
git submodule init
git submodule update
cd yrmix-hash
python setup.py install --user

#
# Install Web Frontends
#
#cd ..
#mv web-static web-static.old
#git clone $P2POOL_FRONTEND web-static
#mv web-static.old web-static/legacy
#cd web-static
#git clone $P2POOL_FRONTEND2 status
#git clone $P2POOL_FRONTEND3 ext

#
# Get specific version of DASH wallet for Linux
#
cd ~
mkdir yrmixcore
cd yrmixcore
wget $YRMIX_WALLET_URL
tar -xvzf $YRMIX_WALLET_ZIP
rm $YRMIX_WALLET_ZIP

#
# Copy YRMIX daemon
#
sudo cp ~/$YRMIX_WALLET_LOCAL/bin/yrmixd /usr/bin/yrmixd
sudo cp ~/$YRMIX_WALLET_LOCAL/bin/yrmix-cli /usr/bin/yrmix-cli
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/yrmixd
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/yrmix-cli

#
# Prepare YRMIX configuration
#
mkdir ~/.yrmixcore
cat <<EOT >> ~/.yrmixcore/yrmix.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
alertnotify=echo %s | mail -s "YRMIX Alert" $EMAIL
server=1
daemon=1
EOT

#
# Get latest DASH core
#
#cd ~/git
#git clone https://github.com/dashpay/dash

#
# Install YRMIX daemon service and set to Auto Start
#
cd /etc/systemd/system
sudo ln -s /home/$USER_NAME/yrmixcoin/contrib/init/yrmixd.service yrmixd.service
sudo sed -i 's/User=yrmixcore/User='"$USER_NAME"'/g' yrmixd.service
sudo sed -i 's/Group=yrmixcore/Group='"$USER_NAME"'/g' yrmixd.service
sudo sed -i 's/\/var\/lib\/yrmixd/\/home\/'"$USER_NAME"'\/.yrmixcore/g' yrmixd.service
sudo sed -i 's/\/etc\/yrmixcore\/dash.conf/\/home\/'"$USER_NAME"'\/.yrmixcore\/yrmix.conf/g' yrmixd.service
sudo systemctl daemon-reload
sudo systemctl enable dashd
sudo service yrmixd start

#
# Prepare p2pool startup script
#
cat <<EOT >> ~/p2pool.start.sh
python ~/git/p2pool-yrmix/run_p2pool.py --external-ip $PUBLIC_IP -f $FEE --give-author $DONATION -a $PAYOUT_ADDRESS
EOT

if [ $? -eq 0 ]
then
echo
echo Installation Completed.
echo You can start p2pool instance by command:
echo
echo bash ~/p2pool.start.sh
echo
echo NOTE: you will need to wait until YRMIX daemon has finished
echo blockchain synchronization before the p2pool instance is usable.
echo
fi
