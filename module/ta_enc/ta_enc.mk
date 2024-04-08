TA_ENC_DEPENDENCIES = toplevel security
ifeq ($(CONFIG_AMPSDK), y)
	TA_ENC_DEPENDENCIES += ampsdk
endif
ifeq ($(CONFIG_TA_CALC), y)
	TA_ENC_DEPENDENCIES += ta_calc
endif

ifeq ($(CONFIG_TA_CAF), y)
ta_caf_en=$(wildcard ta_app/voice/ta_caf/Makefile)
ifneq ($(ta_caf_en),)
	TA_ENC_DEPENDENCIES += ta_caf
endif
endif

ifeq ($(CONFIG_GENCRYPTO), y)
gencrypto_en=$(wildcard ta_app/drm/gencrypto/Makefile)
ifneq ($(gencrypto_en),)
    TA_ENC_DEPENDENCIES += gencrypto
endif
endif

ifeq ($(CONFIG_GATEKEEPER_TA), y)
gatekeeper_ta_en=$(wildcard drm/gatekeeper_ta/Makefile)
ifneq ($(gatekeeper_ta_en),)
    TA_ENC_DEPENDENCIES += gatekeeper_ta
endif
endif

ifeq ($(CONFIG_TA_FACTORY), y)
ta_factory_en=$(wildcard ta_app/drm/ta_factory/Makefile)
ifneq ($(ta_factory_en),)
    TA_ENC_DEPENDENCIES += ta_factory
endif
endif

ifeq ($(CONFIG_GTVCA), y)
gtvca_en=$(wildcard drm/gtvca/gtvca/Makefile)
ifneq ($(gtvca_en),)
    TA_ENC_DEPENDENCIES += gtvca
endif
endif

ifeq ($(CONFIG_PR_SYNA_TA), y)
pr_syna_ta_en=$(wildcard drm/playready/pr_syna/pr_syna_ta/Makefile)
ifneq ($(pr_syna_ta_en),)
    TA_ENC_DEPENDENCIES += pr_syna_ta
endif
endif

ifeq ($(CONFIG_DOLBYUDC_TA), y)
udc_ta_en=$(wildcard thirdparty/dolbyUDC_ta/Makefile)
ifneq ($(udc_ta_en),)
    TA_ENC_DEPENDENCIES += dolbyUDC_ta
endif
endif

ifeq ($(CONFIG_SYNAP), y)
synap_ta_en=$(wildcard synap/vsi_npu_driver/vipta/build/Makefile)
ifneq ($(synap_ta_en),)
    TA_ENC_DEPENDENCIES += synap
endif
endif

$(eval $(generic-module))
