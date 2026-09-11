# PowerVR BXS-4-64 firmware

`rogue_36.53.104.796_v1.fw` is the unmodified firmware version
`1.0.OS@6852738` distributed by Texas Instruments' mirror of linux-firmware.
It matches the GPU hardware identifier requested by the AM69 SK's upstream
`powervr` kernel driver. Its redistribution terms are in `LICENSE.powervr`.

- Source commit: `237071793594723bf1c2e9eef8ff836ffa3b09df`
- Download: <https://raw.githubusercontent.com/TexasInstruments/ti-linux-firmware/237071793594723bf1c2e9eef8ff836ffa3b09df/powervr/rogue_36.53.104.796_v1.fw>
- License: <https://raw.githubusercontent.com/TexasInstruments/ti-linux-firmware/237071793594723bf1c2e9eef8ff836ffa3b09df/LICENSE.powervr>
- Size: 155648 bytes
- SHA-256: `8191e170335463ce63e8c15e32a1a282d76806a0e6ec6e6ba0f101cac1359df4`

The AM69 SK BSP installs it under `/lib/firmware/updates/powervr/`, avoiding
file ownership conflicts with the optional full firmware package. The
`powervr` driver is a module and loads after mounting the root filesystem,
so this firmware does not need an explicit initramfs hook.

Successful GPU initialization is separate from desktop acceleration. The
upstream Mesa PowerVR driver provides Vulkan; its [Zink support for OpenGL
and OpenGL ES was added in Mesa 26.1](https://blog.imaginationtech.com/powervr-the-path-to-open-source-zink-and-opengl-es-support).
Installing this firmware does not
replace the distribution's Mesa packages or force a rendering backend.
