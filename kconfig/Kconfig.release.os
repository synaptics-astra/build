config ANDROID_OS
	bool "Android"
	select BL_DTB

config LINUX_OS
	bool "Linux"

config BERLIN_TARGET_LIST
	string "Format is OS,Sysroot,Toolchain,ToolchainPath"
	default "LINUX,linux-baseline,arm-linux-gnueabihf-,aarch32/gcc-arm-linux-gnueabi-8.3 ANDROID,android,arm-linux-androideabi-,aarch32/arm-linux-androideabi-4.9 LINUX,linux-rootfs64,aarch64-cros-linux-gnu-,aarch64/gcc-arm-aarch64-linux-gnu-8.3"
