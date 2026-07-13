# Disable 3G/modem-GPS/CDMA location sources so geoclue does not
# pull ModemManager into the image.
# The 4G module runs standalone with ECM/PPP dialer — we don't need
# ModemManager managing it.
PACKAGECONFIG:remove = "3g modem-gps cdma"
