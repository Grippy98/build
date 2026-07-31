# PHYTEC phyCORE-AM67 Texas Instruments AM67 (J722S) quad core 4GB LPDDR4 GBE USB3 eMMC OSPI

BOARD_NAME="phyCORE-AM67"
BOARD_VENDOR="phytec"
BOARDFAMILY="k3"
BOARD_MAINTAINER=""
INTRODUCED="2025"
BOOT_SOC="j722s"
BOOTCONFIG="j722s_evm_a53_defconfig"
BOOTFS_TYPE="fat"
BOOT_FDT_FILE="ti/k3-am6754-phyboard-rigel.dts"
TIBOOT3_BOOTCONFIG="j722s_evm_r5_defconfig"
TIBOOT3_FILE="tiboot3-j722s-hs-fs-evm.bin"
DEFAULT_CONSOLE="serial"
KERNEL_TARGET="vendor,vendor-rt"
KERNEL_TEST_TARGET="vendor"
SERIALCON="ttyS2"
ATF_PLAT="k3"
ATF_BOARD="lite"
OPTEE_ARGS=""
OPTEE_PLATFORM="k3-am62x"
# J722S uses the same PowerVR GPU as AM62P
TI_DEBPKGS_FALLBACK_SUITES=("noble" "jammy")
TI_PACKAGES+=(
	"ti-img-rogue-driver-am62p-dkms"
	"ti-img-rogue-umlibs-am62p"
	"ti-img-rogue-tools-am62p"
	"ti-img-rogue-firmware-am62p"
)
if [[ "${RELEASE}" == "bookworm" || "${RELEASE}" == "jammy" ]]; then
	TI_PACKAGES+=("mesa-vulkan-drivers" "libgl1-mesa-dri")
fi

function post_family_config__phycore_am67_phytec_sources() {
	display_alert "$BOARD" "Using PHYTEC kernel and U-Boot sources (PSDK 11.02.11)" "info"

	# Separate LINUXFAMILY so the kernel package does not collide with the
	# standard k3 (TI PSDK 12.x) builds.
	declare -g LINUXFAMILY="k3-phytec"

	# PHYTEC kernel fork – contains the phyBOARD-Rigel DTS which is not yet
	# present in TI's upstream 6.18 tree.
	declare -g KERNELSOURCE="https://github.com/phytec/linux-phytec-ti"
	declare -g KERNEL_MAJOR_MINOR="6.12"
	declare -g KERNELBRANCH="branch:v6.12.57-11.02.11-phy"

	# PHYTEC U-Boot fork – has j722s EVM defconfigs used as a fallback until
	# PHYTEC upstreams a phyCORE-AM67-specific defconfig.
	declare -g BOOTSOURCE="https://github.com/phytec/u-boot-phytec-ti"
	declare -g BOOTBRANCH="branch:v2025.01-11.02.11-phy"
}
