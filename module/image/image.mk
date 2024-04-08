IMAGE_DEPENDENCIES = toplevel tee ta_enc fw_enc security factory linux

ifeq  ($(CONFIG_PREBOOT),y)
IMAGE_DEPENDENCIES+=preboot
endif
ifeq  ($(CONFIG_EXTERNAL_PREBOOT),y)
IMAGE_DEPENDENCIES+=external_preboot
endif
ifeq  ($(CONFIG_BOOTLOADER),y)
IMAGE_DEPENDENCIES+=bootloader
endif
ifeq  ($(CONFIG_EXTERNAL_BOOTLOADER),y)
IMAGE_DEPENDENCIES+=external_bootloader
endif
ifeq  ($(CONFIG_UBOOT),y)
IMAGE_DEPENDENCIES+=uboot
endif
ifeq ($(CONFIG_AMPSDK),y)
IMAGE_DEPENDENCIES+=ampsdk
endif
ifeq ($(CONFIG_POWERMANAGED),y)
IMAGE_DEPENDENCIES+=powermanaged
endif
ifeq ($(CONFIG_APP_GPIO),y)
IMAGE_DEPENDENCIES+=app_gpio
endif
ifeq ($(CONFIG_APP_SMBOX),y)
IMAGE_DEPENDENCIES+=app_smbox
endif
ifeq ($(CONFIG_TEST_STANDBY),y)
IMAGE_DEPENDENCIES+=test_standby
endif
ifeq ($(CONFIG_TEST_SPI),y)
IMAGE_DEPENDENCIES+=test_spi
endif
ifeq ($(CONFIG_WATCHDOGD),y)
IMAGE_DEPENDENCIES+=watchdogd
endif
ifeq ($(CONFIG_VOICECAPTURE),y)
IMAGE_DEPENDENCIES+=voicecapture
endif
ifeq ($(CONFIG_OTA_API),y)
IMAGE_DEPENDENCIES+=ota_api
endif
ifeq ($(CONFIG_TEST_OTA),y)
IMAGE_DEPENDENCIES+=test_ota
endif
ifeq ($(CONFIG_KEYMASTER),y)
IMAGE_DEPENDENCIES+=keymaster
endif
ifeq ($(CONFIG_GATEKEEPER_CA),y)
IMAGE_DEPENDENCIES+=gatekeeper_ca
endif
ifeq ($(CONFIG_GTVCALITE),y)
IMAGE_DEPENDENCIES+=gtvcalite
endif
ifeq ($(CONFIG_GTVCALITE_TEST),y)
IMAGE_DEPENDENCIES+=gtvcalite_test
endif
ifeq ($(CONFIG_PR_SYNA_CA),y)
IMAGE_DEPENDENCIES+=pr_syna_ca
endif
ifeq ($(CONFIG_DOLBYUDC_CA),y)
IMAGE_DEPENDENCIES+=dolbyUDC_ca
endif
ifeq ($(CONFIG_DOLBYUDC_TEST),y)
IMAGE_DEPENDENCIES+=dolbyUDC_test
endif
ifeq ($(CONFIG_DOLBYUDC_TAREG),y)
IMAGE_DEPENDENCIES+=dolbyUDC_tareg
endif
ifeq ($(CONFIG_SYNAP),y)
IMAGE_DEPENDENCIES+=synap
endif
ifeq ($(CONFIG_DRIVERS),y)
IMAGE_DEPENDENCIES+=drivers
endif
# external
ifneq ($(CONFIG_RUNTIME_OE), y)
ifeq ($(CONFIG_FFMPEG),y)
IMAGE_DEPENDENCIES+=ffmpeg
endif
ifeq ($(CONFIG_ALSA),y)
IMAGE_DEPENDENCIES+=alsa
endif
ifeq ($(CONFIG_BLUEZ),y)
IMAGE_DEPENDENCIES+=bluez
endif
ifeq ($(CONFIG_CURL),y)
IMAGE_DEPENDENCIES+=curl
endif
ifeq ($(CONFIG_DBUS),y)
IMAGE_DEPENDENCIES+=dbus
endif
ifeq ($(CONFIG_EUDEV),y)
IMAGE_DEPENDENCIES+=eudev
endif
ifeq ($(CONFIG_EXPAT),y)
IMAGE_DEPENDENCIES+=expat
endif
ifeq ($(CONFIG_GDB),y)
IMAGE_DEPENDENCIES+=gdb
endif
ifeq ($(CONFIG_GLIB2),y)
IMAGE_DEPENDENCIES+=glib2
endif
ifeq ($(CONFIG_LIBFFI),y)
IMAGE_DEPENDENCIES+=libffi
endif
ifeq ($(CONFIG_LIBSNDFILE),y)
IMAGE_DEPENDENCIES+=libsndfile
endif
ifeq ($(CONFIG_LIBTOOL),y)
IMAGE_DEPENDENCIES+=libtool
endif
ifeq ($(CONFIG_NCURSES),y)
IMAGE_DEPENDENCIES+=ncurses
endif
ifeq ($(CONFIG_PULSEAUDIO),y)
IMAGE_DEPENDENCIES+=pulseaudio
endif
ifeq ($(CONFIG_READLINE),y)
IMAGE_DEPENDENCIES+=readline
endif
ifeq ($(CONFIG_SBC),y)
IMAGE_DEPENDENCIES+=sbc
endif
ifeq ($(CONFIG_ZLIB),y)
IMAGE_DEPENDENCIES+=zlib
endif
ifeq ($(CONFIG_TINYXML2),y)
IMAGE_DEPENDENCIES+=tinyxml2
endif
ifeq ($(CONFIG_BOOST),y)
IMAGE_DEPENDENCIES+=boost
endif
ifeq ($(CONFIG_JSONCPP),y)
IMAGE_DEPENDENCIES+=jsoncpp
endif
ifeq ($(CONFIG_CPPNETLIB),y)
IMAGE_DEPENDENCIES+=cppnetlib
endif
endif

# drm
ifeq ($(CONFIG_DRM_TEST),y)
IMAGE_DEPENDENCIES+=drm_test
endif
ifeq ($(CONFIG_READ_RKEKID),y)
IMAGE_DEPENDENCIES+=read_rkekid
endif
ifeq ($(CONFIG_KM_TEST),y)
IMAGE_DEPENDENCIES+=km_test
endif
ifeq ($(CONFIG_FACTORY_UTIL),y)
IMAGE_DEPENDENCIES+=factory_util
endif
ifeq ($(CONFIG_OEM_COMMAND),y)
IMAGE_DEPENDENCIES+=oem_command
endif
ifeq ($(CONFIG_DRM_PR_TEST),y)
IMAGE_DEPENDENCIES+=drm_pr_test
endif

# applications
ifeq ($(CONFIG_AMPLITUDE),y)
IMAGE_DEPENDENCIES+=amplitude
endif
ifeq ($(CONFIG_ISP_PQTOOL),y)
IMAGE_DEPENDENCIES+=isp_pqtool
endif
$(eval $(generic-module))
