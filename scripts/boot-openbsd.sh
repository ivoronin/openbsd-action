#!/usr/bin/env bash

set -euo pipefail

case "$OBA_ARCH" in
  amd64)
    qemu="qemu-system-x86_64"
    machine=pc
    cpu=()
    ;;
  arm64)
    qemu="qemu-system-aarch64"
    machine=virt
    if [ "$OBA_ACCEL" = kvm ]; then
      cpu=(-cpu host)
    else
      cpu=(-cpu cortex-a72)
    fi
    ;;
esac

# shellcheck disable=SC2054
args=(
  "$qemu"
  -machine "$machine"
  -accel "$OBA_ACCEL"
  -m 2G
  -smp 2
  -display none
  -serial "file:$OBA_CONSOLE_LOG"
  -drive "file=$OBA_DISK,format=raw,if=none,id=drive0"
  -device virtio-blk-pci,drive=drive0
  -drive "file=$OBA_CIDATA_ISO,format=raw,readonly=on,if=none,id=cidata"
  -device virtio-blk-pci,drive=cidata
  -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:$OBA_PORT-:22"
  -device virtio-net-pci,netdev=n0
  "${cpu[@]}"
)

if [ "$OBA_FIRMWARE" = uefi ]; then
  efi_code=/usr/share/qemu/edk2-aarch64-code.fd
  efi_vars=/usr/share/qemu/edk2-arm-vars.fd
  [ -e "$efi_code" ] || efi_code=/usr/share/AAVMF/AAVMF_CODE.fd
  [ -e "$efi_vars" ] || efi_vars=/usr/share/AAVMF/AAVMF_VARS.fd
  cp "$efi_vars" "$OBA_EFI_VARS"
  args+=(
    -drive "if=pflash,format=raw,readonly=on,file=$efi_code"
    -drive "if=pflash,format=raw,file=$OBA_EFI_VARS"
  )
fi

"${args[@]}" >"$OBA_QEMU_LOG" 2>&1 < /dev/null &
echo "$!" > "$OBA_QEMU_PID"
