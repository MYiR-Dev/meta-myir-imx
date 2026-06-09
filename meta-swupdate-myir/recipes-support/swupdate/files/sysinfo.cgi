#!/bin/bash

echo "Content-type: text/html"
echo ""
echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>system information</title>'
echo '</head>'
echo '<body>'
echo "$(uname -a) </br>"
echo $(cat /proc/cmdline)
echo '</body>'
echo '</html>'
exit 0