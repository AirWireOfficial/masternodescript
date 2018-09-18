# Simple Script Based Masternode Setup

### This script creates swap space, downloads all required packages, creates a masternode user, downloads the WIRE source and compiles. It then moves the binary to a system wide folder and installs a systemd script to have it autostart on boot. Aliases are created to always use the same conf directory. Use wire-cli to interact with the client.

## Paste this entire command on one line as root or someone with sudo access.

>wget https://cdn.rawgit.com/Social-Wallet-Inc/masternodescript/master/wiremasternodescript.sh && chmod +x ./wiremasternodescript.sh && ./wiremasternodescript.sh && source ~/.bash_aliases
