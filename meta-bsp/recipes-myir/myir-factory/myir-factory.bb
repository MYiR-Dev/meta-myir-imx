SUMMARY = "auto run  scripts"
DESCRIPTION = "sometimes we need a scripts auto run with system boot up"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"


inherit  systemd

S = "${WORKDIR}"

SRC_URI = "file://myir_factory.service \
					 file://myir_factory.sh \
					 file://main.py \
					 file://subtest/__init__.py \
					 file://subtest/bt_test.py \
					 file://subtest/gpio_test.py \
					 file://subtest/key_test.py \
					 file://subtest/m2_test.py \
					 file://subtest/net_test.py \
					 file://subtest/qspi_test.py \
					 file://subtest/rtc_test.py \
					 file://subtest/usb_test.py \
					 file://subtest/wifi_test.py \
           file://licenses/GPL-2 \
          "
          


ROOT_HOME="/home/root"
FAC_SUB_DIR="/subtest"

do_install(){
	install -d ${D}${systemd_system_unitdir}
	install -d ${D}${ROOT_HOME}
	install -d ${D}${ROOT_HOME}${FAC_SUB_DIR}
	
	install -m 755 ${WORKDIR}/myir_factory.sh ${D}${ROOT_HOME}/myir_factory.sh
	install -m 755 ${WORKDIR}/main.py ${D}${ROOT_HOME}/main.py

	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/__init__.py  ${D}${ROOT_HOME}${FAC_SUB_DIR}/__init__.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/bt_test.py   ${D}${ROOT_HOME}${FAC_SUB_DIR}/bt_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/gpio_test.py ${D}${ROOT_HOME}${FAC_SUB_DIR}/gpio_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/key_test.py  ${D}${ROOT_HOME}${FAC_SUB_DIR}/key_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/m2_test.py   ${D}${ROOT_HOME}${FAC_SUB_DIR}/m2_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/net_test.py  ${D}${ROOT_HOME}${FAC_SUB_DIR}/net_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/qspi_test.py ${D}${ROOT_HOME}${FAC_SUB_DIR}/qspi_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/rtc_test.py  ${D}${ROOT_HOME}${FAC_SUB_DIR}/rtc_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/usb_test.py  ${D}${ROOT_HOME}${FAC_SUB_DIR}/usb_test.py
	install -m 755 ${WORKDIR}${FAC_SUB_DIR}/wifi_test.py ${D}${ROOT_HOME}${FAC_SUB_DIR}/wifi_test.py

	install -m 644 ${WORKDIR}/myir_factory.service ${D}${systemd_system_unitdir}/myir_factory.service
}

FILES_${PN} = "/"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "myir_factory.service"
SYSTEMD_AUTO_ENABLE = "enable"

