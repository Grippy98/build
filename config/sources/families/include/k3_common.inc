#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2013-2023 Igor Pecovnik, igor@armbian.com
#
# This file is a part of the Armbian Build Framework
# https://github.com/armbian/build/
#

declare -g ARCH="arm64"
declare -g OVERLAY_DIR="/boot/dtb/ti/overlay"
declare -g BOOTSCRIPT="boot-k3.cmd:uEnv.txt"
declare -g CLEAN_LEVEL="make-atf,make-uboot"

declare -g INSTALL_HEADERS="yes"

[[ -v "TI_PACKAGES" ]] || declare -g TI_PACKAGES=()
if [[ "${CC33XX_SUPPORT}" == "yes" ]]; then
	if [[ "${RELEASE}" == "trixie" || "${RELEASE}" == "noble" ]]; then
		TI_PACKAGES+=("cc33xx-fw" "cc33xx-target-scripts" "cc33conf" "cc33calibrator")
	fi
fi

enable_extension "ti-debpkgs"
enable_extension "apa"

case "${BRANCH}" in

	edge) # experimental (limited testing): uses latest bleeding-edge upstream mainline version

		# KERNELSOURCE defined in mainline-config.sh
		# KERNELBRANCH defined in mainline-kernel.conf.sh
		declare -g KERNEL_MAJOR_MINOR="6.18" # needs updating with each minor kernel release
		declare -g KERNEL_DESCRIPTION="Latest upstream mainline kernel"
		declare -g ATFBRANCH="branch:master"
		declare -g OPTEE_BRANCH="branch:master"
		declare -g TI_LINUX_FIRMWARE_BRANCH="branch:ti-linux-firmware"
		declare -g BOOTSOURCE="https://github.com/u-boot/u-boot"
		declare -g BOOTBRANCH="branch:master"
		;;

esac

ATF_TARGET_MAP="PLAT=${ATF_PLAT} TARGET_BOARD=${ATF_BOARD} SPD=opteed ${ATF_ARGS} all;;build/${ATF_PLAT}/${ATF_BOARD}/release/bl31.bin:bl31.bin ${EXTRA_ATF_TARGETS}"

UBOOT_TARGET_MAP="BL31=bl31.bin ${EXTRA_BOOT_ARGS} TEE=${SRC}/cache/sources/optee-os/out/arm-plat-k3/core/tee-pager_v2.bin BINMAN_INDIRS=${SRC}/cache/sources/ti-linux-firmware all;;tiboot3.bin ${SYSFW_FILE:+sysfw.itb} tispl.bin u-boot.img"

# To match what our current SDK produces
BOOT_FS_LABEL="boot"
ROOT_FS_LABEL="root"

function add_host_dependencies__k3_python3_dep() {
	display_alert "Preparing K3 U-Boot host-side dependencies" "${EXTENSION}" "info"
	declare -g EXTRA_BUILD_DEPS="${EXTRA_BUILD_DEPS} python3-yaml python3-jsonschema yamllint python3-cryptography python3-pyelftools python3-setuptools"
}

function compile_k3_bootgen() {
	# Source code checkout
	(fetch_from_repo "https://github.com/TexasInstruments/ti-linux-firmware" "ti-linux-firmware" ${TI_LINUX_FIRMWARE_BRANCH})

	if [[ "${BOOT_SOC}" != "am62l" ]]; then
		pushd ${SRC}/cache/sources/u-boot-worktree/${BOOTDIR}/${BOOTBRANCH##*:} || exit
		run_host_command_logged make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=build-r5 ${TIBOOT3_BOOTCONFIG}
		run_host_command_logged make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=build-r5 BINMAN_INDIRS=${SRC}/cache/sources/ti-linux-firmware
		popd
	fi
}

function compile_k3_optee() {
	(fetch_from_repo "https://github.com/OP-TEE/optee_os.git" "optee-os" ${OPTEE_BRANCH})
	pushd ${SRC}/cache/sources/optee-os || exit
	run_host_command_logged make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabihf- CFG_ARM64_core=y PLATFORM=${OPTEE_PLATFORM} ${OPTEE_ARGS}
	popd
}

function pre_config_uboot_target__build_first_stage() {
	# Compile first stage bootloader
	compile_k3_optee
	compile_k3_bootgen

	if [[ "${BOOT_SOC}" != "am62l" ]]; then
		cp ${SRC}/cache/sources/u-boot-worktree/${BOOTDIR}/${BOOTBRANCH##*:}/build-r5/${TIBOOT3_FILE} tiboot3.bin
		cp ${SRC}/cache/sources/u-boot-worktree/${BOOTDIR}/${BOOTBRANCH##*:}/build-r5/${SYSFW_FILE} sysfw.itb || true
	fi
}

function post_uboot_custom_postprocess__update_uboot_names() {
	cp ${TISPL_FILE} tispl.bin || true
	cp ${UBOOT_FILE} u-boot.img || true
}

function pre_prepare_partitions() {
	# Filesystem must fill partition regardless of alignment
	mkopts[fat]='-a'
}

function post_create_partitions() {
	display_alert "Setting boot partition flags on" "${SDCARD}.raw" "debug"

	# ROM is very particular about boot flags
	run_host_command_logged parted "${SDCARD}".raw set 1 boot on
	run_host_command_logged parted "${SDCARD}".raw set 1 bls_boot off
}

function format_partitions() {
	# ROM is very particular about partition IDs
	run_host_command_logged sfdisk --part-type ${LOOP} 1 e
}

function write_uboot_platform() {
	local uboot_dir="$1"
	local target_device="$2"
	local boot_mount="${BOOTFS_MOUNT:-}"
	local cleanup_mount=no

	if [[ -b "${target_device}" && -z "${MOUNT:-}" ]]; then
		parted -s "${target_device}" set 1 boot on >/dev/null 2>&1 || true
		parted -s "${target_device}" set 1 bls_boot off >/dev/null 2>&1 || true
		sfdisk --part-type "${target_device}" 1 e >/dev/null 2>&1 || true
		partprobe "${target_device}" >/dev/null 2>&1 || true
	fi

	if [[ -z "${boot_mount}" && -n "${MOUNT:-}" && -d "${MOUNT}/boot" ]]; then
		boot_mount="${MOUNT}/boot"
	fi

	if [[ -z "${boot_mount}" ]]; then
		local boot_partition=""
		if [[ -b "${target_device}p1" ]]; then
			boot_partition="${target_device}p1"
		elif [[ -b "${target_device}1" ]]; then
			boot_partition="${target_device}1"
		elif [[ -b "${target_device}" ]]; then
			boot_partition="${target_device}"
		fi

		if [[ -z "${boot_partition}" ]]; then
			echo "Unable to locate K3 boot partition on ${target_device}"
			exit 1
		fi

		boot_mount=$(mktemp -d /mnt/k3-uboot.XXXXXX)
		if ! mount "${boot_partition}" "${boot_mount}"; then
			rmdir "${boot_mount}"
			echo "Unable to mount K3 boot partition ${boot_partition}"
			exit 1
		fi
		cleanup_mount=yes
	fi

	if [[ ! -d "${boot_mount}" ]]; then
		echo "K3 boot mount ${boot_mount} does not exist"
		exit 1
	fi

	local copy_status=0
	cp "${uboot_dir}/tiboot3.bin" "${boot_mount}" || copy_status=$?
	cp "${uboot_dir}/sysfw.itb" "${boot_mount}" || true
	cp "${uboot_dir}/tispl.bin" "${boot_mount}" || copy_status=$?
	cp "${uboot_dir}/u-boot.img" "${boot_mount}" || copy_status=$?
	sync

	if [[ "${cleanup_mount}" == yes ]]; then
		umount "${boot_mount}"
		rmdir "${boot_mount}"
	fi

	if [[ $copy_status -ne 0 ]]; then
		echo "Unable to copy K3 bootloader files into ${boot_mount}"
		exit "$copy_status"
	fi
}
