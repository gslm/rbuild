#!/bin/bash

emit_kernel() {
  local VERSION="$1"
  local APPEND="$2"
  local NAME="$3"

  echo "label kernel-$VERSION$NAME"
  echo "    kernel /vmlinuz-$VERSION"

  if [[ -f "/etc/kernel/cmdline" ]]; then
    if [[ -f "/boot/initrd.img-$VERSION" ]]; then
      echo "    initrd /initrd.img-$VERSION"
    fi
  fi

  if [[ -f "/boot/dtb-$VERSION" ]]; then
    echo "    fdt /dtb-$VERSION"
  else
    if [[ ! -d "/boot/dtbs/$VERSION" ]]; then
      mkdir -p /boot/dtbs
      cp -au "/usr/lib/linux-image-$VERSION" "/boot/dtbs/$VERSION"
    fi
    echo "    devicetreedir /dtbs/$VERSION"
  fi

  echo "    append $APPEND"
  echo ""
}

TIMEOUT=""
DEFAULT=""
APPEND=""

set -eo pipefail

. /etc/default/extlinux

if [[ -f "/etc/kernel/cmdline" ]]
then
    APPEND="$APPEND $(cat /etc/kernel/cmdline)"
fi

if [[ -f "/etc/default/console" ]]
then
    APPEND="$APPEND $(cat /etc/default/console)"
fi

echo "Kernel configuration : $APPEND" 1>&2
echo ""

echo "Creating new extlinux.conf..." 1>&2

mkdir -p /boot/extlinux/
exec 1> /boot/extlinux/extlinux.conf.new

echo "timeout ${TIMEOUT:-10}"
echo "menu title select kernel"
[[ -n "$DEFAULT" ]] && echo "default $DEFAULT"
echo ""
rm -rf /boot/dtbs
linux-version list | linux-version sort --reverse | while read VERSION; do
  emit_kernel "$VERSION" "$APPEND"
done

exec 1<&-

echo "Installing new extlinux.conf..." 1>&2
mv /boot/extlinux/extlinux.conf.new /boot/extlinux/extlinux.conf