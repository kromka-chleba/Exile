#!/bin/bash
# A basic startup script for Exile

# Place this in $WORKDIR or anywhere that's convenient. The script expects
# a $WORKDIR/logs/ folder, where debug.log will be copied upon a crash

#Customize these values to match your setup
WORKDIR="/home/minetest"
GAMEDIR="$WORKDIR/games/Exile"
PIDFILE="$WORKDIR/server.pid"
MINETEST_CONFIG_FILE="$WORKDIR/minetest.conf"
BINARY="bin/minetestserver" # A run-in-place setup

# Drops a file that shows what git revision was active on start
REVDIR=$WORKDIR
#REVDIR=$GAMEDIR/mods/minimal  # Uncomment to enable /version command in-game

function start_mt {
    cd $GAMEDIR # Remove these four lines to disable auto-updates
    git pull
    git submodule update
    git show --oneline -s > $REVDIR/currentrevision.txt
    cd $WORKDIR
    var=`date +"%FORMAT_STRING"`
    now=`date +"%m_%d_%Y"`
    now=`date +"%Y-%m-%d"`
    didntcrsh=$(awk 'END {print $NF}' debug.txt)
    stest(){
        if [ "${didntcrsh}" != "use?)" ]; then
            cp debug.txt ./logs/crash_debug_${now}.txt
        fi
    }
    stest
    $BINARY --config $MINETEST_CONFIG_FILE 2>error.txt &
    echo $! > $PIDFILE
    #cp debug.txt ./logs/debug${now}.txt
}

function start {
    if [ -e $PIDFILE ]; then
	kill -0 $(cat $PIDFILE) 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
	    echo "Minetest is already running. Aborting"
            else
                echo "restarting server"
                rm $PIDFILE
                start_mt
        fi
            else
                echo "starting server"
                start_mt
        fi
}

function close {
    if [ -e $PIDFILE ]; then
	echo "PID file found. Shutting down server."
	kill $(cat $PIDFILE)
	sleep 5s
	ps --no-headers $(cat $PIDFILE) 1>/dev/null \
	    && echo "Warning: process still running, leaving pidfile" \
		|| rm $PIDFILE
    else
	echo "Pidfile not found, unable to stop safely"
	echo "Suspected process to kill:"
	echo `ps -ax | grep -v grep | grep ${WORKDIR}${BINARY}`
    fi
}


cd $WORKDIR
case $1 in
    close)
	close;;
    *)
	start;;
esac
