# PHYTEC phyBOARD-Rigel AM67x quad core 4GB LPDDR4 eMMC OSPI GBE USB3 HDMI

BOARD_NAME="PHYTEC phyBOARD-Rigel AM67x"
BOARD_VENDOR="phytec"
BOARDFAMILY="k3"
BOARD_MAINTAINER="Grippy98"
INTRODUCED="2026"
BOOT_SOC="j722s"
BOOTCONFIG="phycore_am67x_a53_defconfig"
BOOTFS_TYPE="fat"
BOOT_FDT_FILE="ti/k3-am6754-phyboard-rigel.dtb"
TIBOOT3_BOOTCONFIG="phycore_am67x_r5_defconfig"
TIBOOT3_FILE="tiboot3-am67x-hs-fs-phycore-som.bin"
DEFAULT_CONSOLE="serial"
KERNEL_TARGET="vendor"
KERNEL_TEST_TARGET="vendor"
SERIALCON="ttyS2"
SRC_EXTLINUX="yes"
ATF_PLAT="k3"
ATF_BOARD="lite"
OPTEE_ARGS=""
OPTEE_PLATFORM="k3-am62x"

function post_family_config_branch_vendor__phycore_am67x_sources() {
	display_alert "$BOARD" "Using PHYTEC AM67x vendor kernel and U-Boot" "info"

	declare -g KERNELSOURCE="https://github.com/phytec/linux-phytec-ti"
	declare -g KERNEL_MAJOR_MINOR="6.12"
	declare -g KERNELBRANCH="tag:v6.12.57-11.02.11-phy6"
	declare -g KERNEL_DESCRIPTION="PHYTEC phyCORE-AM67x vendor kernel"
	declare -g LINUXCONFIG="linux-k3-phytec-vendor"
	declare -g KERNELPATCHDIR="archive/k3-phytec-6.12"

	declare -g BOOTSOURCE="https://github.com/phytec/u-boot-phytec-ti"
	declare -g BOOTBRANCH="tag:v2025.01-11.02.11-phy6"
	declare -g BOOTPATCHDIR="u-boot-phytec-k3"
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTDELAY=1

	declare -g ATFSOURCE="https://github.com/TexasInstruments/arm-trusted-firmware"
	declare -g ATFBRANCH="tag:11.02.08"
	declare -g OPTEE_BRANCH="tag:4.6.0"
	declare -g TI_LINUX_FIRMWARE_BRANCH="tag:11.02.11"
}
