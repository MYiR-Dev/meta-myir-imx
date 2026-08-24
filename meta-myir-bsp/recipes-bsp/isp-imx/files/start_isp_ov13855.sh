#!/bin/sh
# Select the MYIR OV13855 ISP bring-up path, retaining all NXP defaults.

RUNTIME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if find /sys/firmware/devicetree/base -name compatible -type f \
        -exec grep -l 'ovti,ov13855' {} \; 2>/dev/null | grep -q .; then
    echo "Starting isp_media_server for OV13855 (multi-mode RAW10, default 2112x1568@60)"
    exec "$RUNTIME_DIR/run_ov13855.sh"
fi

exec "$RUNTIME_DIR/start_isp_nxp.sh" "$@"
