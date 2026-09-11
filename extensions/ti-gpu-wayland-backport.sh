# SPDX-License-Identifier: GPL-2.0
# @description Builds the small Wayland 1.23 backport needed by TI's GPU packages on Ubuntu Noble.

function post_repo_customize_image__010_ti_gpu_wayland_backport() {
	[[ "${RELEASE}" == "noble" && "${SK_AM69_TI_GPU:-no}" == "yes" ]] || return 0

	local work_dir="/tmp/ti-gpu-wayland-backport"
	run_host_command_logged mkdir -p "${SDCARD}${work_dir}"
	run_host_command_logged install -m 755 \
		"${SRC}/packages/bsp/sk-am69/wayland/build-wayland-backport.sh" \
		"${SDCARD}${work_dir}/build-wayland-backport.sh"
	chroot_sdcard "bash ${work_dir}/build-wayland-backport.sh ${work_dir}/debs"

	# Keep the native packages with the other build outputs, excluding debug symbols.
	local deb_file
	for deb_file in "${SDCARD}${work_dir}/debs/"*.deb; do
		[[ -f "${deb_file}" ]] || continue # The helper skips an already sufficient library.
		run_host_command_logged mkdir -p "${SRC}/output/debs"
		run_host_command_logged cp "${deb_file}" "${SRC}/output/debs/"
	done
	run_host_command_logged rm -rf "${SDCARD}${work_dir}"
}
