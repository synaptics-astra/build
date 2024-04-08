#
# For a description of the syntax of this configuration file,
# see Documentation/kbuild/kconfig-language.txt.
#

menuconfig AMP_COMPONENT_APP_ENABLE
	bool "Audio Post-Processor"
	default y

if AMP_COMPONENT_APP_ENABLE

comment "General"

config AMP_IP_AUDIO_MS12_APP_ENABLE
	depends on  AMP_IP_AUDIO_MS12_SUPPORTED
	bool
	prompt "MS12 APP"
	default y

config AMP_AUDIO_GAIN_RANGE_EXTENSION
	bool "Gain Range Extension"
	default n

config AMP_AUDIO_ROUTER_SUPPORTED
	bool "ROUTER"
	default y

source "module/ampsdk/kconfig/audio/Kconfig.audio.app.type"

endif
