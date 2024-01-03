# Depends
```bash
sudo apt install -y qemu-user-static qemu-system qemu-utils qemu-system-misc binfmt-support
```

# How to build image
Need docker docker-compose installed, then type:
```bash
sudo DOCKER_BUILDKIT=1 docker-compose build vf2 

# need kernel tag from
# https://github.com/yuzibo/vf2-linux/tags
sudo KERNEL_VERSION=vf2-v6.6.8-v1 docker-compose up vf2
```

Please note, any modify need to be done with step first.

Because there is no Debian kernel, which was missing some patch to boot vf2, so I have to maintain
the kernel by myself.

One image files will be generated into `image`:

```bash
vf2-rootfs.img.xz
```

# How to install image
The `vf2-rootfs.img` you can use cmd below to flash to nvme:

```bash
sudo dd if=vf2-rootfs.img of=/dev/[nvme-device] bs=64k iflag=fullblock oflag=direct conv=fsync status=progress
```

If the bootloader you want to use it that in sd card, you can `dd` the `vf2-rootfs.img` to sd card:
```bash
sudo dd if=vf2-rootfs.img of=/dev/[sd-device] bs=64k iflag=fullblock oflag=direct conv=fsync status=progress
```

# Username and passwd
```
user: root,     passwd: rv 
user: debian,   passwd: debian
```

Once you boot the system, maybe the first thing is `sudo apt update && upgrade`.

# Increase nvme disk  
Maye you need reszie nvme volume with cmd below:

```
parted -f -s /dev/nvme0n1 print
echo 'yes' | parted ---pretend-input-tty /dev/nvme0n1 resizepart 1 100% 
resize2fs /dev/nvme0n1p1
```
(Better to reboot after this operation)

# sync time
If you see the info after `apt update`:

```
E: Release file for https://mirror.iscas.ac.cn/debian-ports/dists/sid/InRelease is not valid yet (invalid for another 48d 6h 38min 42s).
```
Please fix it by `ntpdate`:

```
sudo ntpdate cn.pool.ntp.org
```

# Thanks
The code demo I learn from [d1_build](https://github.com/tmolteno/d1_build)
