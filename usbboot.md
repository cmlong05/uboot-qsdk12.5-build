# 设置uboot支持从u盘启动
# 无需设置，“boot_targets=usb0 mmc0 nvme0 dhcp”，如下bootcmd会覆盖它
bootcmd=usb start; if fatload usb 0:1 0x44000000 fit.itb; then bootm 0x44000000; fi; bootipq
