# openbsd-action

Run one GitHub Actions command in an OpenBSD QEMU VM booted from an attested image.

```yaml
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: ivoronin/openbsd-action@v1
        with:
          release: "20260708"
          image: openbsd-79-generic-full-arm64-uefi-2bd66ca-202607080953.tar.gz
          arch: arm64
          run: make test
```

The action downloads the exact image asset from `ivoronin/openbsd-cloudimg` by
default, verifies its GitHub attestation, boots it with QEMU, rsyncs the whole
`$GITHUB_WORKSPACE` into `/home/openbsd/work`, runs the command, then rsyncs the
workspace back. Sync-out runs even when the command fails.

Use `ubuntu-24.04` runners. The composite action installs the fixed host package
set it needs with `apt-get`, then runs the VM lifecycle as named shell steps.

Use `generic-full` images for compiler workloads. Base images are accepted by
the action, but they do not include the compiler set.

Inputs:

1. `repo`: image repository, default `ivoronin/openbsd-cloudimg`.
2. `release`: image release tag.
3. `image`: exact release asset name. The action treats it as opaque.
4. `arch`: `amd64` or `arm64`. `amd64` uses BIOS, `arm64` uses UEFI.
5. `run`: command executed in `/home/openbsd/work`.
