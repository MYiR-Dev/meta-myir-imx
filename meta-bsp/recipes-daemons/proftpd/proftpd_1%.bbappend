do_install_append() {
	install -m 755 -d ${D}/var/lib/${FTPUSER}
	chown ftp:ftp ${D}/var/lib/${FTPUSER}
}	