ifeq ($(CONFIG_RDK_SYS), y)
    TEE_DEPENDENCIES = toplevel security
else
    TEE_DEPENDENCIES = toplevel security sysroot
endif
ifeq ($(CONFIG_TZK_PRELOAD_TA), y)
TEE_DEPENDENCIES += ta_enc
endif

$(eval $(generic-module))
