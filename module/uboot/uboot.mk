UBOOT_DEPENDENCIES = security toplevel

ifeq  ($(CONFIG_PREBOOT),y)
UBOOT_DEPENDENCIES+=preboot
endif
ifeq  ($(CONFIG_EXTERNAL_PREBOOT),y)
UBOOT_DEPENDENCIES+=external_preboot
endif
$(eval $(generic-module))
