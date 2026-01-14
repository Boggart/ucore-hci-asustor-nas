#!/bin/bash

set -ouex pipefail

### Install Asustor platform drivers
KERNEL_VERSION="$(< /ctx/kernel-version.txt)"
install -m 644 -D /ctx/asustor-platform-driver/asustor.ko \
  "/lib/modules/${KERNEL_VERSION}/kernel/drivers/platform/x86/asustor.ko"
install -m 644 -D /ctx/asustor-platform-driver/asustor_it87.ko \
  "/lib/modules/${KERNEL_VERSION}/kernel/drivers/hwmon/asustor_it87.ko"
install -m 644 -D /ctx/asustor-platform-driver/asustor_gpio_it87.ko \
  "/lib/modules/${KERNEL_VERSION}/kernel/drivers/gpio/asustor_gpio_it87.ko"
depmod -a "${KERNEL_VERSION}"
printf "# Asustor modules\nasustor_gpio_it87\nasustor_it87\nasustor\n" > /etc/modules-load.d/asustor.conf
