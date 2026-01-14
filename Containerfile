# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/ucore-hci:stable as kernel-query
#We can't use the `uname -r` as it will pick up the host kernel version
RUN rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' > /kernel-version.txt

FROM registry.fedoraproject.org/fedora:43 as builder
COPY --from=kernel-query /kernel-version.txt /kernel-version.txt

RUN dnf install -y \
    git \
    make

# Get the kernel-headers
RUN KERNEL_VERSION=$(cat /kernel-version.txt) && \
    KERNEL_XYZ=$(echo ${KERNEL_VERSION} | cut -d"-" -f1) && \
    KERNEL_DISTRO=$(echo ${KERNEL_VERSION} | cut -d"-" -f2 | cut -d"." -f-2) && \
    KERNEL_ARCH=$(echo ${KERNEL_VERSION} | cut -d"-" -f2 | cut -d"." -f3) && \
    dnf install -y \
    https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_XYZ}/${KERNEL_DISTRO}/${KERNEL_ARCH}/kernel-${KERNEL_VERSION}.rpm \
    https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_XYZ}/${KERNEL_DISTRO}/${KERNEL_ARCH}/kernel-core-${KERNEL_VERSION}.rpm \
    https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_XYZ}/${KERNEL_DISTRO}/${KERNEL_ARCH}/kernel-modules-${KERNEL_VERSION}.rpm \
    https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_XYZ}/${KERNEL_DISTRO}/${KERNEL_ARCH}/kernel-modules-core-${KERNEL_VERSION}.rpm \
    https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_XYZ}/${KERNEL_DISTRO}/x86_64/kernel-devel-${KERNEL_VERSION}.rpm

WORKDIR /home
RUN git clone https://github.com/Boggart/ucore-hci-asustor-nas
WORKDIR  /home/ucore-hci-asustor-nas
RUN KERNEL_VERSION=$(cat /kernel-version.txt) && \
    TARGET=${KERNEL_VERSION} make all

# Base Image
FROM ghcr.io/ublue-os/ucore-hci:stable
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=builder,source=/kernel-version.txt,target=/ctx/kernel_version.txt \
    --mount=type=bind,from=builder,source=/home/ucore-hci-asustor-nas,target=/ctx/asustor-kmod \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
RUN bootc container lint
