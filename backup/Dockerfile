FROM debian:sid as builder
MAINTAINER Bo YU "tsu.yubo@gmail.com"

ENV KERNEL_VERSION=${KERNEL_VERSION}

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,sharing=shared,target=/var/cache \
    --mount=type=cache,sharing=shared,target=/var/lib/apt/lists \
    --mount=type=tmpfs,target=/usr/share/man \
    --mount=type=tmpfs,target=/usr/share/doc \
    apt-get update \
    && apt-get install -y eatmydata \
    && eatmydata apt-get install -y debootstrap qemu-user-static \
        binfmt-support debian-ports-archive-keyring gdisk kpartx \
        parted \
        autoconf automake autotools-dev bc binfmt-support \
        build-essential cpio curl \
        dosfstools e2fsprogs fdisk flex gawk  \
        git gperf kmod libexpat-dev \
        libgmp-dev libmpc-dev libmpfr-dev libssl-dev \
        libtool mmdebstrap multistrap openssl parted \
        patchutils python3 python3-dev python3-distutils \
        python3-setuptools qemu-user-static swig \
        systemd-container texinfo zlib1g-dev wget

# build rootfs 
FROM builder as build_rootfs
WORKDIR /build
COPY rootfs/multistrap_nvme.conf multistrap.conf

RUN --mount=type=cache,sharing=shared,target=/var/cache \
    --mount=type=cache,sharing=shared,target=/var/lib/apt/lists \
    --mount=type=tmpfs,target=/usr/share/man \
    --mount=type=tmpfs,target=/usr/share/doc \
    eatmydata multistrap -f multistrap.conf


FROM builder as build_image
WORKDIR /builder
COPY --from=build_rootfs /build/rv64-sid/ ./rv64-port/
COPY create_image.sh build.sh ./
COPY rootfs/setup_rootfs.sh ./rv64-port/

CMD eatmydata /builder/build.sh ${KERNEL_VERSION}

