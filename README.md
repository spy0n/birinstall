# BirakeCoin
Shell script to install or update a [BirakeCoin Masternode](https://www.birake.com/) on a Linux server running Ubuntu 14.04, 16.04, 18.04 and 19.04. Use it on your own risk.

***
## Installation:
```
apt-get install -y shc curl;curl https://raw.githubusercontent.com/birake/birinstall/master/bir-setup.sh.x --output bir-setup;chmod +x bir-setup
./bir-setup
```
***

***
## Update:
```
apt-get install -y shc curl;curl https://raw.githubusercontent.com/birake/birinstall/master/bir-setup.sh.x --output bir-setup;chmod +x bir-setup
./bir-setup update
```
***


## Desktop wallet setup

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps for Windows Wallet
1. Open the BirakeCoin Coin Desktop Wallet.
2. Go to RECEIVE and create a New Address: **MN1**
3. Send **50000** **BirakeCoin** to **MN1**.
4. Wait for 15 confirmations.
5. Go to **Tools -> "Debug console - Console"**
6. Type the following command: **masternode outputs**
7. Go to  ** Tools -> "Open Masternode Configuration File"
8. Add the following entry:
```
Alias Address Privkey TxHash Output_index
```
* Alias: **MN1**
* Address: **VPS_IP:PORT**
* Privkey: **Masternode Private Key**
* TxHash: **First value from Step 6**
* Output index:  **Second value from Step 6**
9. Save and close the file.
10. Go to **Masternode Tab**. If you tab is not shown, please enable it from: **Settings - Options - Wallet - Show Masternodes Tab**
11. Click **Update status** to see your node. If it is not shown, close the wallet and start it again. Make sure the wallet is unlocked.
12. Open **Debug Console** and type:
```
startmasternode "alias" "0" "MN1"
```
***

## Available commands:

* `./bir-setup` displays the status of installed nodes. If none is installed it will install the first one
* `./bir-setup 3` it will install multiple nodes and 3 in this case is how many nodes to install
* `./bir-setup reinstall 1` where 1 is the number of the node that you want to reinstall
* `./bir-setup reinstall all` it will reinstall all the mn wallets
* `./bir-setup restart 2` where 2 is the number of node that you want to restart
* `./bir-setup stop 2` where 2 is the number of node that you want to stop
* `./bir-setup delete 2` where 2 is the number of node that you want to delete
* `./bir-setup delete all` it will delete all the mn wallets
* `./bir-setup update` will update the wallet to latest version

If you want to check **BirakeCoin** mn status, run :

```
./bir-setup
```

