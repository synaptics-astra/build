configed=$(shell test -e $(CURDIR)/out/.config;echo $$?)

qstrip = $(strip $(subst ",,$(1)))#"))

ifneq ($(configed), 0)
$(error "ERROR: .config not existed. Please use make xxx_defconfig first")
endif

TOPDIR := $(CURDIR)
config_file=$(CURDIR)/out/.config
-include $(config_file)
OUT_PRODUCT_DIR := $(call qstrip,$(CONFIG_PRODUCT_NAME))
BUILD_DIR := $(call qstrip,$(CONFIG_SYNA_SDK_BUILD_PATH))

.PHONY: target
target: all
include $(CURDIR)/build/module/module.mk

ifeq ($(RELEASE), y)
	script=release.sh
else
	script=build.sh
endif

toplevel: $(config_file)
	@$(CURDIR)/build/$(script) $(config_file)

all: toplevel $(PACKAGES)
