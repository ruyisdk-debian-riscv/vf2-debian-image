#!/bin/bash

# It woule be good to test it outside of Docker
OUT_DIR="$1"

ROOTFS_IMG="${OUT_DIR}/vf2-rootfs.img"
SD_DD_OPTS="bs=4k iflag=fullblock oflag=direct conv=fsync status=progress"

function make_image(){

    if [ -f ${ROOTFS_IMG} ]; then
        echo "deleting nvme rootfs image..."
        rm ${ROOTFS_IMG}
    fi

    dd if=/dev/zero of="${ROOTFS_IMG}" bs=1M count=4096

    echo "Creating Blank ${ROOTFS_IMG}"

     sgdisk -g --clear --set-alignment=1 \
         -g --clear --new=1:0:+16M: --new=2:0:+100M: -t 2:EF00 --new=3:0:-1M: --attributes 3:set:2 -d 1 ${ROOTFS_IMG} 


    part_id=$(kpartx -av ${ROOTFS_IMG} | awk '{print $3}' | awk 'NR==1 {print $1}'| awk -F 'p' '{print $2}')
    echo "the output is $part_id"

    LOOP_X_P2="loop${part_id}p2"
    LOOP_X_P3="loop${part_id}p3"

    echo "formatting loopback device ${LOOP_X_P2}"

    mkfs.vfat "/dev/mapper/${LOOP_X_P2}" 

    mkfs.ext4 -m 0 -L root "/dev/mapper/${LOOP_X_P3}"

    # Copy Files, first the rootfs partition
    echo "Mounting  partitions ${LOOPDEV}"
    ROOTFS_POINT=/nvme_rootfs
    mkdir -p "${ROOTFS_POINT}"

    mount "/dev/mapper/${LOOP_X_P3}" "${ROOTFS_POINT}"

    #mount ${LOOPDEV} /mnt
    #debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring,ca-certificates  unstable ${ROOTFS_POINT} https://mirror.iscas.ac.cn/debian-ports
    #
    copy_rootfs

    kpartx -d ${ROOTFS_IMG}
}

function copy_rootfs(){
    
    # from docker image has been defined 
    cp -a /builder/rv64-port/* "${ROOTFS_POINT}"

    # Copy the rootfs
    cp /usr/bin/qemu-riscv64-static ${ROOTFS_POINT}/usr/bin/
    chroot "${ROOTFS_POINT}" qemu-riscv64-static /bin/sh /setup_rootfs.sh
    rm "${ROOTFS_POINT}/setup_rootfs.sh" "${ROOTFS_POINT}/usr/bin/qemu-riscv64-static"

    umount "${ROOTFS_POINT}" 

    rm -rf "${ROOTFS_POINT}"

}

make_image

if [ $? -eq 0 ]; then
    echo "make_immge executed successfully."
    # Now compress the image
    echo "Compressing the image: ${ROOTFS_IMG}"
    cd "${OUT_DIR}" && xz -T0 "${ROOTFS_IMG}"
else
    kpartx -d ${ROOTFS_IMG}
    exit 1
fi
