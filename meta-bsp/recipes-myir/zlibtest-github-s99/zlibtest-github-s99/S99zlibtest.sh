#!/bin/sh
# Start the zlibtest application

DAEMON=/usr/bin/zlibtest

[ -x "$DAEMON" ] || exit 0

case "$1" in
  start)
    echo "Starting zlibtest"
    $DAEMON &
    ;;
  stop)
    echo "Stopping zlibtest"
    killall zlibtest
    ;;
  restart|reload)
    killall zlibtest
    sleep 1
    $DAEMON &
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
