#!/usr/bin/env bash

set -euo pipefail

case "$INPUT_ARCH" in
  amd64) firmware=bios ;;
  arm64) firmware=uefi ;;
  *) echo "arch must be amd64 or arm64" >&2; exit 2 ;;
esac

case "$(uname -m)" in
  x86_64) host_arch=amd64 ;;
  aarch64|arm64) host_arch=arm64 ;;
  *) host_arch=unknown ;;
esac

case "$INPUT_PORTS" in
  true|false) ;;
  *) echo "ports must be true or false" >&2; exit 2 ;;
esac

accel=tcg
if [ "$INPUT_ARCH" = "$host_arch" ] && [ -e /dev/kvm ]; then
  accel=kvm
fi

root="$RUNNER_TEMP/openbsd-action/$GITHUB_RUN_ID"
mkdir -p "$root/image" "$root/cidata"
chmod 700 "$root"

cat >> "$GITHUB_ENV" <<EOF
OBA_REPO=$INPUT_REPO
OBA_RELEASE=$INPUT_RELEASE
OBA_IMAGE=$INPUT_IMAGE
OBA_ARCH=$INPUT_ARCH
OBA_FIRMWARE=$firmware
OBA_ACCEL=$accel
OBA_PORT=$(shuf -i 20000-60000 -n 1)
OBA_ROOT=$root
OBA_ARCHIVE=$root/image.tar.gz
OBA_DISK=$root/image/disk.raw
OBA_CIDATA=$root/cidata
OBA_CIDATA_ISO=$root/cidata.iso
OBA_CONSOLE_LOG=$root/console.log
OBA_QEMU_LOG=$root/qemu.log
OBA_QEMU_PID=$root/qemu.pid
OBA_SSH_KEY=$root/id_ed25519
OBA_KNOWN_HOSTS=$root/known_hosts
OBA_SSH_CONFIG=$root/ssh_config
OBA_EFI_VARS=$root/efi-vars.fd
EOF
