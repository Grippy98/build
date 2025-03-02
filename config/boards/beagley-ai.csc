#Texas Instruments AM67A quad core 4GB USB3 DDR4 4TOPS

BOARD_NAME="BeagleY-AI"
BOARDFAMILY="k3"
BOARD_MAINTAINER="grippy98"
BOOTCONFIG="am67a_beagley_ai_a53_defconfig"
BOOTFS_TYPE="fat"
BOOT_FDT_FILE="k3-am67a-beagley-ai.dts"
TIBOOT3_BOOTCONFIG="am67a_beagley_ai_r5_defconfig"
TIBOOT3_FILE="tiboot3-j722s-hs-fs-evm.bin"
DEFAULT_CONSOLE="serial"
KERNEL_TARGET="edge"
KERNEL_TEST_TARGET="edge"
SERIALCON="ttyS2"
ATF_BOARD="lite"
BOOTPATCHDIR="u-boot-beagle"

#Until BeagleY and J722s goes upstream, use this branch
function post_family_config_branch_edge__beagley_ai_use_beagle_kernel_uboot() {
	display_alert "$BOARD" " beagleboard (next branch) u-boot and kernel overrides for $BOARD / $BRANCH" "info"

	declare -g KERNELSOURCE="https://github.com/beagleboard/linux" # BeagleBoard kernel
	declare -g KERNEL_MAJOR_MINOR="6.12"
	declare -g KERNELBRANCH="branch:v6.12.13-ti-arm64-r24"
	declare -g LINUXFAMILY="k3-beagle" # Separate kernel package from the regular `k3` family

	declare -g BOOTSOURCE="https://github.com/beagleboard/u-boot" # Beagle u-boot
	declare -g BOOTBRANCH="branch:v2023.04-ti-09.02.00.009-BeagleY-AI-Production"
	declare -g BOOTPATCHDIR="u-boot-beagle"
}
