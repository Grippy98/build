#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Build and install a Noble-native Wayland backport without another distro's APT repository.
set -euo pipefail

if [[ ${EUID} -ne 0 || $# -ne 1 || "$1" != /* ]]; then
	echo "Usage: sudo bash $0 /absolute/output/directory (on Ubuntu Noble)" >&2
	exit 2
fi
. /etc/os-release
if [[ "${ID}" != "ubuntu" || "${VERSION_CODENAME}" != "noble" ]]; then
	echo "This backport must be built with Ubuntu Noble's libraries and toolchain." >&2
	exit 2
fi

installed_version=$(dpkg-query -W -f='${Version}' libwayland-client0 2>/dev/null || true)
installed_status=$(dpkg-query -W -f='${db:Status-Status}' libwayland-client0 2>/dev/null || true)
if [[ "${installed_status}" == "installed" ]] && dpkg --compare-versions "${installed_version}" ge 1.23.0; then
	echo "Wayland ${installed_version} already satisfies TI's GPU packages."
	exit 0
fi

output_dir="$1"
work_dir=$(mktemp -d /tmp/ti-wayland-build.XXXXXX)
apt-mark showmanual | LC_ALL=C sort > "${work_dir}/manual.before"
cleanup() {
	local status=$?
	# apt-get marks explicitly requested build dependencies manual. Restore the
	# original marks so normal image cleanup can remove these temporary tools.
	apt-mark showmanual | LC_ALL=C sort > "${work_dir}/manual.after"
	mapfile -t added_manual < <(LC_ALL=C comm -13 "${work_dir}/manual.before" "${work_dir}/manual.after")
	if (( ${#added_manual[@]} )); then
		apt-mark auto "${added_manual[@]}" >/dev/null || true
	fi
	rm -rf "${work_dir}"
	exit "${status}"
}
trap cleanup EXIT

# Upgrade installed development packages too: their exact-version dependencies
# must remain consistent with the runtime libraries. Do not add them to images
# that did not already use them.
packages=(libwayland-client0 libwayland-server0 libwayland-cursor0 libwayland-egl1)
for package in libwayland-dev libwayland-egl-backend-dev libwayland-bin; do
	if [[ "$(dpkg-query -W -f='${db:Status-Status}' "${package}" 2>/dev/null || true)" == "installed" ]]; then
		packages+=("${package}")
	fi
done

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y --no-remove --no-install-recommends install \
	build-essential debhelper quilt pkgconf libexpat1-dev libffi-dev \
	libxml2-dev meson ninja-build ca-certificates curl

cd "${work_dir}"
source_url="https://deb.debian.org/debian/pool/main/w/wayland"
for source_file in wayland_1.23.1-3.dsc wayland_1.23.1.orig.tar.gz wayland_1.23.1-3.diff.gz; do
	curl --fail --location --retry 3 --output "${source_file}" "${source_url}/${source_file}"
done
sha256sum --check <<'CHECKSUMS'
03b4da461e507338731b86183e989e0e9c3fa28f34d8739f0b30d8dd9b88bce8  wayland_1.23.1-3.dsc
158ec49af498f2558c7fbf7e8b070d010d4e270cc6076003a18a6c813f87e244  wayland_1.23.1.orig.tar.gz
f48a224e6d744d33ab00378b7a7f2b3ab6461706e30b722e320d047d880e70c8  wayland_1.23.1-3.diff.gz
CHECKSUMS
# Every source file was checked above; a Debian maintainer keyring is unnecessary.
dpkg-source --no-check -x wayland_1.23.1-3.dsc
cd wayland-1.23.1
version="1.23.1-3~armbian24.04+1"
cat > debian/changelog.new <<'CHANGELOG'
wayland (1.23.1-3~armbian24.04+1) noble; urgency=medium

  * Rebuild for Ubuntu Noble to provide the Wayland 1.23 client API required
    by the TI PowerVR Mesa packages.

 -- Armbian Linux <info@armbian.com>  Fri, 11 Sep 2026 00:00:00 +0000

CHANGELOG
cat debian/changelog >> debian/changelog.new
mv debian/changelog.new debian/changelog

# -B excludes documentation; Debian's normal rules run the upstream test suite.
dpkg-buildpackage -B -us -uc -j"$(nproc)"
cd "${work_dir}"
mkdir -p "${output_dir}"
for deb_file in ./*.deb; do
	[[ "${deb_file}" == *-dbgsym_* ]] && continue
	cp "${deb_file}" "${output_dir}/"
done

architecture=$(dpkg --print-architecture)
install_debs=()
for package in "${packages[@]}"; do
	install_debs+=("${output_dir}/${package}_${version}_${architecture}.deb")
done
apt-get -y --no-remove --no-install-recommends install "${install_debs[@]}"
