# Cadence MHDP8546 DisplayPort firmware

`mhdp8546.bin` is the unmodified version 2.1.0 firmware distributed by
Texas Instruments' mirror of linux-firmware. It is required by the AM69 SK's
Cadence DisplayPort bridge. Its redistribution terms are in `LICENCE.cadence`.

- Source commit: `f99d6a1d579ec7a32f3906061bfa7921c747cf5b`
- Download: <https://raw.githubusercontent.com/TexasInstruments/ti-linux-firmware/f99d6a1d579ec7a32f3906061bfa7921c747cf5b/cadence/mhdp8546.bin>
- License: <https://raw.githubusercontent.com/TexasInstruments/ti-linux-firmware/f99d6a1d579ec7a32f3906061bfa7921c747cf5b/LICENCE.cadence>
- Size: 131072 bytes
- SHA-256: `81168034d5def08bf779028f22e7e908cd09880a42395b3f407050c139339af8`

The AM69 SK BSP installs it under `/lib/firmware/updates/cadence/` and adds it
to the initramfs. This also works when the optional full firmware package is
installed, without two packages owning the same file. The kernel must load
the initramfs at boot so its built-in bridge driver can find the firmware.
