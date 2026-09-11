# AM69 display and GPU support

The board BSP supplies Cadence MHDP firmware in the initramfs for DisplayPort,
plus firmware for the upstream `powervr` driver. Firmware provenance and
redistribution licenses are recorded in the firmware subdirectories.

For `vendor`, `vendor-rt`, and `vendor-edge` images on Noble or Trixie,
`sk-am69.conf` also selects the matching J784S4 packages from TI's
[`ti-debpkgs` repository](https://github.com/TexasInstruments/ti-debpkgs):

- `ti-img-rogue-driver-j784s4-dkms`
- `ti-img-rogue-umlibs-j784s4`
- `ti-img-rogue-tools-j784s4`
- `ti-img-rogue-firmware-j784s4`

The image hooks install GCC 14 before DKMS runs, and retain that compiler choice
in `/etc/dkms/ti-img-rogue-driver.conf` for future driver/kernel upgrades. The
Rogue build requires `KERNEL_CC`; setting only `CC` still uses Noble's GCC 13,
which rejects the 6.18 kernel headers' `-fmin-function-alignment=8` flag.
The K3 family already installs matching kernel headers.

Noble additionally needs the [native Wayland backport](wayland/README.md) before
the TI graphics libraries can be installed. Trixie has the required Wayland API.
After the TI packages are installed, image hooks blacklist `powervr` and load
`pvrsrvkm`. These drivers match the same device but use different userspace and
firmware ABIs. The release-independent BSP never selects between them, so
mainline images keep their upstream driver.

## Validation

Validated on an AM69 SK with Ubuntu Noble, GNOME 46 Wayland, and
`6.18.13-vendor-k3`:

- DKMS driver `26.1.6967606+git20260513+50e14e425cba-1` built against the exact
  installed headers using Noble's GCC 14.2.
- TI userspace/firmware `26.1.6967606+git20260515+a59e0e6b92df-3` and TI Mesa
  `25.2.8+git20260619+0cb5bad52580-3` installed with clean APT dependencies.
- EGL reported PowerVR B-Series BXS-4-64, OpenGL ES 3.2, on both surfaceless
  and GNOME Wayland platforms. Vulkan reported the integrated PowerVR GPU.
- `vkcube-wayland --c 120 --width 320 --height 240` rendered successfully in
  the desktop session. Driver/firmware status remained OK with zero errors
  and zero hardware recovery events.
- After reboot, SSH, DisplayPort, GNOME, and `pvrsrvkm` returned automatically;
  the user confirmed the login screen and desktop looked normal.

The backport passed all 26 upstream tests and Noble ABI/linkage checks. The
Armbian hook selection/order was checked across 32 interactive and command-line
branch/release cases. The signed TI Trixie repository also passed an APT
dependency simulation using stock Trixie Wayland and GCC 14. A complete new
Armbian image has not been rebuilt as part of this validation.

TI's current Mesa packages disable GLX and replace Ubuntu's GLX vendor library.
Legacy OpenGL applications requiring GLX therefore need a separate userspace
solution. The confirmed hardware APIs in this stack are OpenGL ES and Vulkan
through Wayland/EGL.

For an installed board, useful checks are:

```sh
dkms status
cat /sys/kernel/debug/pvr/status
eglinfo -B -p surfaceless -a gles
vulkaninfo --summary
```

Run Wayland rendering tests as the logged-in desktop user with that session's
`XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY`.
