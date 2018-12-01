# BirakeCoin
Shell script to install a [BirakeCoin Masternode](https://www.birake.com/) on a Linux server running Ubuntu 14.04 or 16.04. Use it on your own risk.

***
## Installation:
```
git clone https://github.com/birake/birinstall.git
cd birinstall
bash bir-install.sh
```
***

## Desktop wallet setup

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps for Windows Wallet
1. Open the BirakeCoin Coin Desktop Wallet.
2. Go to RECEIVE and create a New Address: **MN1**
3. Send **25000** **BirakeCoin** to **MN1**.
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

## Usage:
```
birakecoin-cli getinfo
birakecoin-cli mnsync status
birakecoin-cli masternode status
```
Also, if you want to check/start/stop **BirakeCoin** , run one of the following commands as **root**:

**Ubuntu 16.04**:
```
systemctl status BirakeCoin #To check the service is running.
systemctl start BirakeCoin #To start BirakeCoin service.
systemctl stop BirakeCoin #To stop BirakeCoin service.
systemctl is-enabled BirakeCoin #To check whetether BirakeCoin service is enabled on boot or not.
```
**Ubuntu 14.04**:  
```
/etc/init.d/BirakeCoin start #To start BirakeCoin service
/etc/init.d/BirakeCoin stop #To stop BirakeCoin service
/etc/init.d/BirakeCoin restart #To restart BirakeCoin service
```
***
