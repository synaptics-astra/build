moduledir = $(dir $(lastword $(MAKEFILE_LIST)))
modulename = $(lastword $(subst /, ,$(moduledir)))
[FROM] := a b c d e f g h i j k l m n o p q r s t u v w x y z - .
[TO]   := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _ _

define caseconvert-helper
$(1) = $$(strip \
    $$(eval __tmp := $$(1))\
    $(foreach c, $(2),\
    $$(eval __tmp := $$(subst $(word 1,$(subst :, ,$c)),$(word 2,$(subst :, ,$c)),$$(__tmp))))\
    $$(__tmp))
endef

# Figure out where we are.
define my-dir
$(strip \
  $(eval LOCAL_MODULE_MAKEFILE := $$(lastword $$(MAKEFILE_LIST))) \
    $(patsubst %/,%,$(dir $(LOCAL_MODULE_MAKEFILE))) \
   \
 )
endef


$(eval $(call caseconvert-helper,UPPERCASE,$(join $(addsuffix :,$([FROM])),$([TO]))))
$(eval $(call caseconvert-helper,LOWERCASE,$(join $(addsuffix :,$([TO])),$([FROM]))))



$(BUILD_DIR)/%/.stamp_target_cleaned:
	$(info cleaning $(MOD_DIR))
	@rm -rf $(@D)
	@mkdir -p $(@D)
	@$(MOD_DIR)build.sh $(CFG_FILE) clean
	@touch $@

$(BUILD_DIR)/%/.stamp_target_built:
	@$(info building $(MOD_DIR))
	@$(MOD_DIR)build.sh $(CFG_FILE)
	@touch $@

$(BUILD_DIR)/%/.stamp_target_released:
	@$(info releasing $(MOD_DIR))
	@mkdir -p $(@D)
	@$(MOD_DIR)release.sh $(CFG_FILE)
	@touch $@


define inner-generic-module

$(2)_KCONFIG_VAR = CONFIG_$(2)

ifeq ($$($$($(2)_KCONFIG_VAR)),y)
PACKAGES += $(1)
$(2)_FINAL_DEPENDENCIES = $(sort $($(2)_DEPENDENCIES))
$(2)_DIR        =  $$(BUILD_DIR)/$(2)

$(2)_TARGET_CLEAN =    $$($(2)_DIR)/.stamp_target_cleaned
$(2)_TARGET_BUILD =    $$($(2)_DIR)/.stamp_target_built
$(2)_TARGET_RELEASE =  $$($(2)_DIR)/.stamp_target_released

ifeq ($(RELEASE), y)
  $(1):                   $(1)-release
  ifeq ($(filter toplevel,$($(2)_DEPENDENCIES)),)
    $(2)_DEPENDENCIES := toplevel $($(2)_DEPENDENCIES)
  endif
else
  $(1):                   $(1)-build
endif

$$($(2)_TARGET_BUILD):	$$($(2)_TARGET_CLEAN)
$$($(2)_TARGET_CLEAN):	|$$($(2)_DEPENDENCIES)
$$($(2)_TARGET_RELEASE):|$$($(2)_DEPENDENCIES)

$(1)-build:             $$($(2)_TARGET_BUILD)
$(1)-clean:             $(2)_TARGET_FORCE_CLEAN
$(1)-depends:           $$($(2)_DEPENDENCIES)
$(1)-release:           $$($(2)_TARGET_RELEASE)

$(2)_TARGET_FORCE_CLEAN:
	rm -rf $$($(2)_DIR)

$(2)_TARGET_REBUILD:
	@rm -rf $$($(2)_TARGET_BUILD)

$(1)-rebuild:	$(2)_TARGET_REBUILD $(1)
$(1)-show-depends:
	@echo "$$($(2)_DEPENDENCIES)"

ifeq ($(1), image)
$(1)-pack:
	@$(3)/pack.sh $(4) $(subimg)

endif

ifeq ($(1), preboot)
$(1)-nocs:
	@$(3)/build.sh $(4) $(module)

endif



$$($(2)_TARGET_CLEAN):         MOD=$(1)
$$($(2)_TARGET_CLEAN):         MOD_DIR=$(3)
$$($(2)_TARGET_CLEAN):         CFG_FILE=$(4)
$$($(2)_TARGET_BUILD):         MOD=$(1)
$$($(2)_TARGET_BUILD):         MOD_DIR=$(3)
$$($(2)_TARGET_BUILD):         CFG_FILE=$(4)
$$($(2)_TARGET_RELEASE):       CFG_FILE=$(4)
$$($(2)_TARGET_RELEASE):       MOD_DIR=$(3)
$$($(2)_TARGET_RELEASE):       MOD=$(1)

.PHONY : $(1) \
	$(1)-build \
	$(1)-clean \
	$(1)-depends \
	$(1)-rebuild	\
	$(1)-release \
	$(1)-show-depends

endif
endef #inner-generic-module


generic-module = $(call inner-generic-module,$(modulename),$(call UPPERCASE,$(modulename)),$(moduledir),$(config_file),$(RELEASE))
#$(info $(generic-module))
include $(sort $(wildcard $(CURDIR)/build/module/*/*.mk))
include $(CURDIR)/external/external.mk
include $(CURDIR)/application/application.mk
include $(CURDIR)/ta_app/ta_app.mk
