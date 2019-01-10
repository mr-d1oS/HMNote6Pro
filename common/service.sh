#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

# Log file location
LOG_FILE=/data/sqlite.log

#Interval between SQLite3 runs, in seconds, 259200=3 days
RUN_EVERY=259200

# Get the last modify date of the Log file, if the file does not exist, set value to 0
if [ -e $LOG_FILE ]; then
	LASTRUN=`stat -t $LOG_FILE | awk '{print $14}'`
else
	LASTRUN=0
fi;

# Get current date in epoch format
CURRDATE=`date +%s`

# Check the interval
INTERVAL=$(expr $CURRDATE - $LASTRUN)

# If interval is more than the set one, then run the main script
if [ $INTERVAL -gt $RUN_EVERY ];
then
	if [ -e $LOG_FILE ]; then
		rm $LOG_FILE;
	fi;
		
	echo "SQLite database VACUUM and REINDEX started at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;

	for i in `busybox find /d* -iname "*.db"`; do
		/system/xbin/sqlite3 $i 'VACUUM;';
		resVac=$?
		if [ $resVac == 0 ]; then
			resVac="SUCCESS";
		else
			resVac="ERRCODE-$resVac";
		fi;
		
		/system/xbin/sqlite3 $i 'REINDEX;';
		resIndex=$?
		if [ $resIndex == 0 ]; then
			resIndex="SUCCESS";
		else
			resIndex="ERRCODE-$resIndex";
		fi;
		echo "Database $i:  VACUUM=$resVac  REINDEX=$resIndex" | tee -a $LOG_FILE;
	done
	  
	echo "SQLite database VACUUM and REINDEX finished at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;
fi;

LOG_FILE=/data/zipalign.log
#Interval between ZipAlign runs, in seconds, 604800=1 week
RUN_EVERY=604800

# Get the last modify date of the Log file, if the file does not exist, set value to 0
if [ -e $LOG_FILE ]; then
	LASTRUN=`stat -t $LOG_FILE | awk '{print $14}'`
else
	LASTRUN=0
fi;

# Get current date in epoch format
CURRDATE=`date +%s`

# Check the interval
INTERVAL=$(expr $CURRDATE - $LASTRUN)

# If interval is more than the set one, then run the main script
if [ $INTERVAL -gt $RUN_EVERY ];
then
	if [ -e $LOG_FILE ]; then
		rm $LOG_FILE;
	fi;

	echo "Starting Automatic ZipAlign $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;
	for apk in /data/app/*.apk ; do
		zipalign -c 4 $apk;
		ZIPCHECK=$?;
		if [ $ZIPCHECK -eq 1 ]; then
			echo ZipAligning $(basename $apk)  | tee -a $LOG_FILE;
			zipalign -f 4 $apk /cache/$(basename $apk);

			if [ -e /cache/$(basename $apk) ]; then
				cp -f -p /cache/$(basename $apk) $apk  | tee -a $LOG_FILE;
				rm /cache/$(basename $apk);
			else
				echo ZipAligning $(basename $apk) Failed  | tee -a $LOG_FILE;
			fi;
		else
			echo ZipAlign already completed on $apk  | tee -a $LOG_FILE;
		fi;
	done;
	for apk in /system/app/*.apk ; do
		zipalign -c 4 $apk;
		ZIPCHECK=$?;
		if [ $ZIPCHECK -eq 1 ]; then
			echo ZipAligning $(basename $apk)  | tee -a $LOG_FILE;
			zipalign -f 4 $apk /cache/$(basename $apk);

			if [ -e /cache/$(basename $apk) ]; then
				cp -f -p /cache/$(basename $apk) $apk  | tee -a $LOG_FILE;
				rm /cache/$(basename $apk);
			else
				echo ZipAligning $(basename $apk) Failed  | tee -a $LOG_FILE;
			fi;
		else
			echo ZipAlign already completed on $apk  | tee -a $LOG_FILE;
		fi;
	done;
	for apk in /system/priv-app/*.apk ; do
		zipalign -c 4 $apk;
		ZIPCHECK=$?;
		if [ $ZIPCHECK -eq 1 ]; then
			echo ZipAligning $(basename $apk)  | tee -a $LOG_FILE;
			zipalign -f 4 $apk /cache/$(basename $apk);

			if [ -e /cache/$(basename $apk) ]; then
				cp -f -p /cache/$(basename $apk) $apk  | tee -a $LOG_FILE;
				rm /cache/$(basename $apk);
			else
				echo ZipAligning $(basename $apk) Failed  | tee -a $LOG_FILE;
			fi;
		else
			echo ZipAlign already completed on $apk  | tee -a $LOG_FILE;
		fi;
	done;
	echo "Automatic ZipAlign finished at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $LOG_FILE;
fi;

echo "500" > /proc/sys/vm/dirty_expire_centisecs
echo "1000" > /proc/sys/vm/dirty_writeback_centisecs

echo «8» > /proc/sys/vm/page-cluster;
echo «64000» > /proc/sys/kernel/msgmni;
echo «64000» > /proc/sys/kernel/msgmax;
echo «10» > /proc/sys/fs/lease-break-time;
echo «500, 512000, 64, 2048» > /proc/sys/kernel/sem;

echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
echo "1" > /proc/sys/net/ipv4/tcp_sack;
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes;
echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout;
echo "404480" > /proc/sys/net/core/wmem_max;
echo "404480" > /proc/sys/net/core/rmem_max;
echo "256960" > /proc/sys/net/core/rmem_default;
echo "256960" > /proc/sys/net/core/wmem_default;
echo "4096,16384,404480" > /proc/sys/net/ipv4/tcp_wmem;
echo "4096,87380,404480" > /proc/sys/net/ipv4/tcp_rmem;

echo «4096» > /proc/sys/vm/min_free_kbytes
echo «0» > /proc/sys/vm/oom_kill_allocating_task;
echo «0» > /proc/sys/vm/panic_on_oom;
echo «0» > /proc/sys/vm/laptop_mode;
echo «0» > /proc/sys/vm/swappiness
echo «50» > /proc/sys/vm/vfs_cache_pressure
echo «90» > /proc/sys/vm/dirty_ratio
echo «70» > /proc/sys/vm/dirty_background_ratio