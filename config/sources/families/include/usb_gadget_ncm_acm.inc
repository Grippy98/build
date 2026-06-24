#
# SPDX-License-Identifier: GPL-2.0
#
# Shared USB NCM ethernet + ACM serial gadget BSP helpers.
#

function install_usb_gadget_ncm_acm_bsp() {
	local gadget_name="${USB_GADGET_NCM_ACM_NAME:-${BOARD}}"
	local manufacturer="${USB_GADGET_NCM_ACM_MANUFACTURER:-BeagleBoard.org}"
	local product="${USB_GADGET_NCM_ACM_PRODUCT:-${BOARD_NAME} NCM+ACM}"
	local serial_prefix="${USB_GADGET_NCM_ACM_SERIAL_PREFIX:-NCMACM}"
	local fallback_serial="${USB_GADGET_NCM_ACM_FALLBACK_SERIAL:-${serial_prefix}0001}"
	local id_vendor="${USB_GADGET_NCM_ACM_ID_VENDOR:-0x1d6b}"
	local id_product="${USB_GADGET_NCM_ACM_ID_PRODUCT:-0x0105}"
	local max_power="${USB_GADGET_NCM_ACM_MAX_POWER:-250}"
	local source_dir="$SRC/packages/bsp/usb-gadget-ncm-acm"
	local defaults_file="$destination/etc/default/usb-gadget-ncm-acm"

	display_alert "$BOARD" "Installing NCM+ACM USB gadget" "info"

	install -Dm755 "$source_dir/usb-gadget-ncm-acm" \
		"$destination/usr/local/sbin/usb-gadget-ncm-acm"

	install -Dm644 "$source_dir/usb-gadget-ncm-acm.service" \
		"$destination/usr/lib/systemd/system/usb-gadget-ncm-acm.service"

	install -Dm644 "$source_dir/90-usb0-ncm.network" \
		"$destination/usr/lib/systemd/network/90-usb0-ncm.network"

	install -Dm600 "$source_dir/usb0-ncm-static.nmconnection" \
		"$destination/etc/NetworkManager/system-connections/usb0-ncm-static.nmconnection"

	install -Dm644 "$source_dir/serial-getty-ttyGS0.conf" \
		"$destination/usr/lib/systemd/system/serial-getty@ttyGS0.service.d/10-usb-gadget-ncm-acm.conf"

	install -Dm644 /dev/null "$defaults_file"
	cat > "$defaults_file" <<- EOF
		USB_GADGET_NCM_ACM_NAME="${gadget_name}"
		USB_GADGET_NCM_ACM_MANUFACTURER="${manufacturer}"
		USB_GADGET_NCM_ACM_PRODUCT="${product}"
		USB_GADGET_NCM_ACM_SERIAL_PREFIX="${serial_prefix}"
		USB_GADGET_NCM_ACM_FALLBACK_SERIAL="${fallback_serial}"
		USB_GADGET_NCM_ACM_ID_VENDOR="${id_vendor}"
		USB_GADGET_NCM_ACM_ID_PRODUCT="${id_product}"
		USB_GADGET_NCM_ACM_MAX_POWER="${max_power}"
	EOF
}

function enable_usb_gadget_ncm_acm() {
	display_alert "$BOARD" "Enabling NCM+ACM USB gadget" "info"

	chroot_sdcard chmod 600 /etc/NetworkManager/system-connections/usb0-ncm-static.nmconnection
	chroot_sdcard setcap cap_net_raw+ep /usr/bin/ping || chroot_sdcard chmod u+s /usr/bin/ping
	chroot_sdcard systemctl --no-reload enable usb-gadget-ncm-acm.service
	chroot_sdcard systemctl --no-reload enable serial-getty@ttyGS0.service
}
