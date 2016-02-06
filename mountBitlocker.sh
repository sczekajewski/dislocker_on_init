#! /bin/sh
### BEGIN INIT INFO
# Provides:          mountBitlocker
# Required-Start:    $local_fs
# Required-Stop:
# Should-Start:      $network $portmap nfs-common  udev-mtab
# Default-Start:     1 2 3 5
# Default-Stop:      0 6
# Short-Description: Mount Bitlocker partition on /dev/sdb5 using dislocker
# Description:       First mounts /dev/sdb5 with dislocker and fuse to 
#                    /dev/bitlocker/sdb5/dislocker_file
#                    then mounts the device setup to /media/bitlocker
### END INIT INFO

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check for missing binaries
DISLOCKER_COMMAND=/usr/local/bin/dislocker
test -x $DISLOCKER_COMMAND || { echo "$DISLOCKER_COMMAND not installed";
        if [ "$1" = "stop" ]; then exit 0;
        else exit 5; fi; }

DISLOCKER_CONFIG=/etc/dislocker.conf

if [ "$1" != "install" ]; then
# Check for existence of needed config file and read it
	test -r $DISLOCKER_CONFIG || { echo "$DISLOCKER_CONFIG not existing";
		    if [ "$1" = "stop" ]; then exit 0;
		    else exit 6; fi; }
# Read config
	. $DISLOCKER_CONFIG
fi


case "$1" in
    start)
		mkdir -p $dislocker_mount
		if mountpoint $decrypted_mount > /dev/null; then
			echo "Already mounted."
			exit 0
		else
		    echo -n "Mounting Bitlocker partition."
			$DISLOCKER_COMMAND -u$volume_user_password -V $source_volume $dislocker_mount
		    echo -n "."
			mount -o loop,rw,nouser $dislocker_mount/dislocker-file $decrypted_mount
			echo ".mounted."
			exit 0
		fi
        ;;
    stop)
		if mountpoint $decrypted_mount > /dev/null; then
		    echo -n "Unmounting Bitlocker partition."
		    umount $decrypted_mount
		    echo -n "."
			sleep 2
		    umount $dislocker_mount
			echo -n ".unmounted.\n"
		else
			echo "Already unmounted."
			exit 0
		fi
        ;;
    restart)
        ## Stop the service and regardless of whether it was
        ## running or not, start it again.
        $0 stop
        $0 start
        ;;
    status)
        echo -n "Checking if partition is mounted.."
		if mountpoint $decrypted_mount > /dev/null;	then
			echo -n ".mounted\n"
			exit 0
		else
			echo -n ".unmounted\n"
			exit 3
		fi
        ;;
	install)
		if [ -r $DISLOCKER_CONFIG ]; then
			echo "Already installed."
			exit 0
		else
			echo -n "Installing."
			printf 'source_volume="/dev/sdb5"\nvolume_user_password="???"\ndislocker_mount="/dev/dislocker/sdb5"\ndecrypted_mount="/media/bitlocker"' > $DISLOCKER_CONFIG
			cp $0 /etc/init.d/mountBitlocker
			echo -n "."
			chmod 755 /etc/init.d/mountBitlocker
			chown root:root /etc/init.d/mountBitlocker
			echo -n "."
			ln -s /etc/init.d/mountBitlocker /sbin/mountBitlocker
			echo -n "."
			update-rc.d mountBitlocker defaults
			echo "done."
			exit 0
		fi
		;;
	uninstall)
		if [ -r $DISLOCKER_CONFIG ]; then
			echo -n "Uninstalling."
			update-rc.d mountBitlocker remove
			echo -n "."
			rm -rf /sbin/mountBitlocker
			rm -rf /etc/init.d/mountBitlocker
			rm -rf $DISLOCKER_CONFIG
			echo -n "."
			echo "done."
			exit 0
		else
			echo "Already uninstalled."
			exit 0
		fi
		;;
    *)
        ## If no parameters are given, print which are avaiable.
        echo "Usage: $0 {start|stop|status|restart|install|uninstall}"
        exit 1
        ;;
esac
