FW_ENC_DEPENDENCIES = toplevel security
ifeq ($(CONFIG_AMPSDK), y)
	FW_ENC_DEPENDENCIES += ampsdk
endif

$(eval $(generic-module))
