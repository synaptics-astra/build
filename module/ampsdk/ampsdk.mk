AMPSDK_DEPENDENCIES = tee tee_dev
ifeq ($(CONFIG_FFMPEG),y)
AMPSDK_DEPENDENCIES += ffmpeg
endif
ifeq ($(CONFIG_LINUX_OS),y)
ifeq (,$(strip $(CONFIG_RUNTIME_RDK)$(CONFIG_RUNTIME_OE)$(CONFIG_RUNTIME_OE64)))
AMPSDK_DEPENDENCIES += curl
endif
endif
ifeq ($(CONFIG_JSONCPP),y)
AMPSDK_DEPENDENCIES += jsoncpp
endif
ifeq ($(CONFIG_TINYXML2),y)
AMPSDK_DEPENDENCIES += tinyxml2
endif
ifeq ($(CONFIG_SYNAP),y)
AMPSDK_DEPENDENCIES +=synap
endif
$(eval $(generic-module))
