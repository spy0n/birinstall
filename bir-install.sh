#!/bin/bash

CONFIG_FILE='birakecoin.conf'
CONFIGFOLDER='/root/.birakecoin'
COIN_DAEMON='/usr/local/bin/birakecoind'
COIN_CLI='/usr/local/bin/birakecoin-cli'
COIN_REPO='https://github.com/birake/birakecoin/releases/download/v1.0.0.0/birakecoin-1.0.0-x86_64-linux-gnu.tar.gz'
COIN_SNAPSHOT='https://s3.eu-central-1.amazonaws.com/birake-snapshot/snapshot.zip'
COIN_NAME='BirakeCoin'
COIN_BIN_NAME='BirakeCoin'
COIN_PORT=39697
RPC_PORT=39698
BIND=""
if [[ "$1" != "" ]]
then
CONFIGFOLDER="$1"
fi

if [[ "$2" != "" ]]
then
COIN_NAME="$2"
fi

NODEIP=$(curl -s4 icanhazip.com)

if [[ "$3" != "" ]]
then
NODEIP="$3"
BIND="bind=$3"
fi

if [[ "$4" != "" ]]
then
RPC_PORT="$4"
fi


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

progressfilt () {
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    if $flag
    then
      printf '%c' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]
      then
        count=0
      else
        ((count++))
        if ((count > 1))
        then
          flag=true
        fi
      fi
    fi
  done
}

function compile_node() {
  if [ ! -f "/usr/local/bin/birakecoind" ]; then
  echo -e "Prepare to download $COIN_NAME"
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_REPO 2>&1 | progressfilt
  compile_error

  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  COIN_VER=$(echo $COIN_ZIP | awk -F'/' '{print $NF}' | sed -n 's/.*\([0-9]\.[0-9]\.[0-9]\).*/\1/p')
  COIN_DIR=$(echo ${COIN_BIN_NAME,,}-$COIN_VER)
  tar xvzf $COIN_ZIP --strip=2 ${COIN_DIR}/bin/${COIN_BIN_NAME,,}d ${COIN_DIR}/bin/${COIN_BIN_NAME,,}-cli>/dev/null 2>&1
  compile_error
  rm -f $COIN_ZIP >/dev/null 2>&1
  cp birakecoin* /usr/local/bin
  compile_error
  strip $COIN_DAEMON $COIN_CLI
  cd -
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
  fi
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function configure_startup() {
  cat << EOF > /etc/init.d/$COIN_NAME
#! /bin/bash
### BEGIN INIT INFO
# Provides: $COIN_NAME
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: $COIN_NAME
# Description: This file starts and stops $COIN_NAME MN server
#
### END INIT INFO

case "\$1" in
 start)
   $COIN_DAEMON -datadir=$CONFIGFOLDER -daemon
   sleep 5
   ;;
 stop)
   $COIN_CLI -datadir=$CONFIGFOLDER stop
   ;;
 restart)
   $COIN_CLI -datadir=$CONFIGFOLDER stop
   sleep 10
   $COIN_DAEMON -datadir=$CONFIGFOLDER -daemon
   ;;
 *)
   echo "Usage: $COIN_NAME -datadir=$CONFIGFOLDER {start|stop|restart}" >&2
   exit 3
   ;;
esac
EOF
chmod +x /etc/init.d/$COIN_NAME >/dev/null 2>&1
update-rc.d $COIN_NAME defaults >/dev/null 2>&1
/etc/init.d/$COIN_NAME start >/dev/null 2>&1
if [ "$?" -gt "0" ]; then
 sleep 5
 /etc/init.d/$COIN_NAME start >/dev/null 2>&1
fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
listen=1
prune=500
server=1
daemon=1
port=$COIN_PORT
rpcport=$RPC_PORT
$BIND
EOF
}

function download_snapshot() {
  echo -e "Prepare to download snapshot"
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_SNAPSHOT 2>&1 | progressfilt
  unzip snapshot.zip -d $CONFIGFOLDER/
  mv $CONFIGFOLDER/snapshot/* $CONFIGFOLDER/
  rm -rf $CONFIGFOLDER/snapshot
  cd -
  rm -rf $TMP_FOLDER >/dev/null 2>&1
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}.\nLeave it blank to generate a new ${RED}$COIN_NAME Masternode Private Key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_DAEMON -datadir=$CONFIGFOLDER -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_CLI -datadir=$CONFIGFOLDER masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
    sleep 30
    COINKEY=$($COIN_CLI -datadir=$CONFIGFOLDER masternode genkey)
  fi
  $COIN_CLI -datadir=$CONFIGFOLDER stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=64
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
EOF
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow ssh >/dev/null 2>&1
  ufw allow $COIN_PORT >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}

function detect_ubuntu() {
 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *14.04* ]]; then
   UBUNTU_VERSION=14
 elif [ -f "/etc/debian_version" ]; then
   UBUNTU_VERSION=14
else
   echo -e "${RED}You are not running Ubuntu 14.04 or 16.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function checks() {
 detect_ubuntu 
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(ps ax|grep '$COIN_DAEMON -datadir=$CONFIGFOLDER'|grep -v grep)" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
apt-get install -y wget curl binutils zip unzip >/dev/null 2>&1
}

function important_information() {
 echo
 echo -e "================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 if (( $UBUNTU_VERSION == 16 )); then
   echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
   echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
   echo -e "Status: ${RED}systemctl status $COIN_NAME.service${NC}"
 else
   echo -e "Start: ${RED}/etc/init.d/$COIN_NAME start${NC}"
   echo -e "Stop: ${RED}/etc/init.d/$COIN_NAME stop${NC}"
   echo -e "Status: ${RED}/etc/init.d/$COIN_NAME status${NC}"
 fi
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY${NC}"
 if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${RED}Sentinel${NC} is installed in ${RED}$CONFIGFOLDER/sentinel${NC}"
  echo -e "Sentinel logs is: ${RED}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "Check if $COIN_NAME is running by using the following command:\n${RED}ps -ef | grep $COIN_DAEMON | grep -v grep${NC}"
 echo -e "================================================================================"
}

function setup_node() {
  create_config
  download_snapshot
  create_key
  update_config
  enable_firewall
  important_information
  if (( $UBUNTU_VERSION == 16 )); then
    configure_systemd
  else
    configure_startup
  fi    
}


##### Main #####
clear

checks
prepare_system
compile_node
get_ip
if [[ "$3" != "" ]]
then
NODEIP="$3"
fi
setup_node
