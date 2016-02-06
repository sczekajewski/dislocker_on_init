# dislocker_on_init
This installs a init.d script mounting your Bitlocker encrypted partition to selected mountpoint.
Needs root to start.
Uses [dislocker](https://github.com/Aorimn/dislocker). to decrypt the partition - needs it installed beforehand.
Use `sudo ./mountBitlocker.sh install` to install it.

Install creates sample configuration file /etc/dislocker.conf
Write everything you need there (you'll need to give it encrypted partition location and user password at least).

I recommend using this only on fully encrypted systems (your root partition needs to be encrypted).
If your root partition is not encrypted, you're leaking your Bitlocker password in the configuration file.

**Use at own risk!**

