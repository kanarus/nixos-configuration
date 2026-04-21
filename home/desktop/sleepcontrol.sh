#!/usr/bin/env bash

LOG="/tmp/niri-suspend.log"
exec >> $LOG 2>&1

echo "--- $(date) ---"

case "$1" in
    pre)
        echo "Event: before-sleep"
        niri msg action move-workspace-to-monitor eDP-1
        swaylock -f -c 000000
        sleep 1 
    ;;

    post)
        echo "Event: after-resume"
        
        i=0
        while ! pgrep swaylock > /dev/null && [ $i -lt 15 ]; do
            sleep 0.2
            ((i++))
        done

        if pgrep swaylock > /dev/null; then
            echo "Lock detected. Waiting for user to unlock..."
            while pgrep swaylock > /dev/null; do
                sleep 0.5
            done
            echo "User unlocked."
        else
            echo "Warning: swaylock not detected, skipping wait."
        fi
        
        echo "Waiting for external monitor to be ready..."
        j=0
        while [ "$(niri msg outputs | grep -c 'Output')" -lt 2 ] && [ $j -lt 20 ]; do
            sleep 0.5
            ((j++))
        done
        sleep 1
        
        echo "Running move-workspace-to-monitor-next"
        niri msg action move-workspace-to-monitor-next
    ;;
esac
