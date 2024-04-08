config TOOLS
	bool
	default y

config TOOLS_REL_PATH
	string
	default "bin"
	help
		Used as ${CONFIG_SYNA_SDK_OUT_HOST_PATH}/${CONFIG_PREBOOT_REL_PATH}

config TOOLS_BIN_PATH
	string
	default "build/tools/bin"
	help
		Used as ${CONFIG_SYNA_SDK_PATH}/${CONFIG_TOOLS_BIN_PATH}

config SECURITY_TOOL_PATH
	string
	default "release/SECURITY/tools"
	help
		Used as ${CONFIG_SYNA_SDK_OUT_TARGET_PATH}/${CONFIG_SECURITY_TOOL_PATH}
