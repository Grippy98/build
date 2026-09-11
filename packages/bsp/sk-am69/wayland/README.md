# Wayland for the TI GPU stack on Noble

TI's Noble repository currently publishes PowerVR Mesa 25.2.8 packages that
import `wl_display_create_queue_with_name`, introduced in Wayland 1.23. Ubuntu
Noble provides Wayland 1.22. The dependency cannot be relaxed without rebuilding
the graphics libraries or supplying the missing API.

`build-wayland-backport.sh` builds Debian's Wayland 1.23.1-3 source against
Noble's own libraries. It verifies all three source checksums and runs Debian's
normal tests. It installs the four runtime libraries, also upgrading any
previously installed development or scanner packages with exact-version
dependencies. It saves the other non-debug packages in the requested output
directory, and restores APT's previous manual/automatic package selections so
build tools can be removed by normal image cleanup. It does not add an APT
repository.

Run it as root in a disposable Ubuntu Noble container, chroot, or build host:

```sh
bash build-wayland-backport.sh /tmp/wayland-debs
```

The Armbian extension `ti-gpu-wayland-backport` invokes this helper before the
TI package installer and copies the resulting packages to `output/debs`.
The board registers the extension before Armbian's interactive release/branch
selection; its image hook runs only for Noble images using the TI GPU stack.
The helper skips its work when the installed Wayland client library is already
at least 1.23.0. Backport version: `1.23.1-3~armbian24.04+1`.

Sources:

- [Debian Wayland 1.23.1-3 source description](https://deb.debian.org/debian/pool/main/w/wayland/wayland_1.23.1-3.dsc)
- [TI's Mesa build checks for the optional Wayland API](https://github.com/TexasInstruments/mesa/blob/0cb5bad52580/meson.build)
- [TI Noble package index](https://TexasInstruments.github.io/ti-debpkgs/dists/noble/main/binary-arm64/Packages)

Wayland's upstream and Debian packaging licenses are included in the source
and resulting packages. The helper and extension are GPL-2.0.
