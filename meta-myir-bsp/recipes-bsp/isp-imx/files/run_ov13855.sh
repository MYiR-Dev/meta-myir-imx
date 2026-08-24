#!/bin/sh
# OV13855 RAW10 multi-mode ISP path for MYD-JS8MPQ.

set -eu

RUNTIME_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$RUNTIME_DIR"

OV13855_MODE="${OV13855_MODE:-0}"
case "$OV13855_MODE" in
    0|1) ;;
    *)
        echo "OV13855_MODE must be 0 (2112x1568@60) or 1 (4224 sensor, 4096x3072 ISP crop @15)" >&2
        exit 2
        ;;
esac

for module in ov13855 imx8-media-dev vvcam-dwe vvcam-isp vvcam-video; do
    module_name=$(printf '%s' "$module" | tr '-' '_')
    if ! grep -q "^${module_name} " /proc/modules; then
        modprobe "$module"
    fi
done

printf '%s\n' \
    '[mode.0]' \
    'xml = "OV13855_13M_10_2112x1568_linear.xml"' \
    'dwe = "dewarp_config/sensor_dwe_ov13855_2112x1568_bypass.json"' \
    '' \
    '[mode.1]' \
    'xml = "OV13855_13M_10_4096x3072_linear.xml"' \
    'dwe = "dewarp_config/sensor_dwe_ov13855_4096x3072_bypass.json"' \
    > OV13855_MODES.txt

printf '%s\n' \
    'name = "ov13855"' \
    'drv = "ov13855.drv"' \
    "mode = $OV13855_MODE" \
    > Sensor0_Entry.cfg
cat OV13855_MODES.txt >> Sensor0_Entry.cfg

for required in ov13855.drv \
                OV13855_13M_10_2112x1568_linear.xml \
                OV13855_13M_10_4096x3072_linear.xml \
                OV13855_13M_10_4224x3136_linear.xml \
                dewarp_config/sensor_dwe_ov13855_2112x1568_bypass.json \
                dewarp_config/sensor_dwe_ov13855_4096x3072_bypass.json \
                dewarp_config/sensor_dwe_ov13855_4224x3136_bypass.json; do
    if [ ! -f "$required" ]; then
        echo "Missing OV13855 ISP bring-up file: $required" >&2
        exit 1
    fi
done

ISP_PID_FILE=/run/isp_media_server.pid
if [ -r "$ISP_PID_FILE" ]; then
    isp_pid=
    IFS= read -r isp_pid < "$ISP_PID_FILE" || true
    case "$isp_pid" in
        ''|*[!0-9]*) ;;
        *)
            if kill "$isp_pid" 2>/dev/null; then
                sleep 1
            fi
            ;;
    esac
fi
exec ./isp_media_server CAMERA0
