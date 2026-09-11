bootpart=1:1
bootdir=
finduuid=part uuid \${boot} 1:2 uuid
name_rd=uInitrd
get_rd_mmc=load mmc ${bootpart} ${rdaddr} ${bootdir}/${name_rd}
# TI U-Boot can disable legacy image parsing. Pass the raw compressed payload
# after the 64-byte mkimage header so booti works with either configuration.
set_rd=setexpr rd_start ${rdaddr} + 0x40; setexpr rd_size ${filesize} - 0x40; env set rd_spec ${rd_start}:${rd_size}
# TI SDK 12 also tries to load ti-core-initramfs.cpio.xz in get_kern_mmc,
# clearing rd_spec when it is absent. Preserve the Armbian uInitrd loaded below.
get_kern_mmc=load mmc ${bootpart} ${loadaddr} ${bootdir}/${name_kern}

uenvcmd=if run get_rd_${boot}; then run set_rd; else env set rd_spec -; fi; setexpr fdtfile sub ti/ti ti; run bootcmd_ti_mmc
