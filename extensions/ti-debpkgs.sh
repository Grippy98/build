function extension_finish_config__install_kernel_headers_for_ti() {
	if [[ "${KERNEL_HAS_WORKING_HEADERS}" != "yes" ]]; then
		display_alert "Kernel version has no working headers package" "skipping TI for kernel v${KERNEL_MAJOR_MINOR}" "warn"
		return 0
	fi
	declare -g INSTALL_HEADERS="yes"
	display_alert "Forcing INSTALL_HEADERS=yes; for use with TI " "${EXTENSION}" "debug"
}

function post_install_kernel_debs__install_ti_packages() {
	if [[ "${INSTALL_HEADERS}" != "yes" || "${KERNEL_HAS_WORKING_HEADERS}" != "yes" ]]; then
		return 0
	fi

	# Fetch valid suites from TI repo
	valid_suites=($(curl -s "https://api.github.com/repos/TexasInstruments/ti-debpkgs/contents/dists" | jq -r '.[].name'))
	echo "✅ TI Repo has the following valid suites - ${valid_suites[@]}..."

	if [[ " ${valid_suites[@]} " =~ " ${RELEASE} " ]]; then
		echo "✅ $RELEASE is valid"

		# Get the sources file
		chroot_sdcard "wget -qO /tmp/ti-debpkgs.sources https://raw.githubusercontent.com/TexasInstruments/ti-debpkgs/main/ti-debpkgs.sources"
		echo "✅ Got ti-debpkgs.sources..."

		# Update suite in sources file
		chroot_sdcard "sed -i 's/Suite=\${current_suite}/Suite=${RELEASE}/g' /tmp/ti-debpkgs.sources"
		echo "✅ Updated Suite to ${RELEASE}..."

		# Copy updated sources file into chroot
		chroot_sdcard "cp /tmp/ti-debpkgs.sources /etc/apt/sources.list.d/ti-debpkgs.sources"
		echo "✅ Added ti-debpkgs.sources"

		# Clean up inside the chroot
		chroot_sdcard "rm -f /tmp/ti-debpkgs.sources"
	else
		# Error if suite is not valid but continue building image anyway
		echo "❌ Error: Detected OS suite '$RELEASE' is not valid based on TI package repository. Skipping!"
		echo "Valid Options Would Have Been: ${valid_suites[@]}"
	fi
}
