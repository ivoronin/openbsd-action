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

## Ports tree

Set `ports: true` to prepare `/usr/ports` before `run`.

```yaml
- uses: ivoronin/openbsd-action@v1
  with:
    release: "20260708"
    image: openbsd-79-generic-full-amd64-bios-2bd66ca-202607080953.tar.gz
    arch: amd64
    ports: true
    ports-archive-url-prefix: https://cdn.openbsd.org/pub/OpenBSD/7.9
    run: |
      cd /usr/ports/shells/zsh
      make show=PKGNAME
```

Use the ports tree flavor that matches the guest image:

| Tree | Source form | `ports-archive-url-prefix` | `ports-cvs-root` | `ports-cvs-ref` |
|---|---|---|---|---|
| release | mirror archive | `https://cdn.openbsd.org/pub/OpenBSD/7.9` | omit | omit |
| stable | release archive + AnonCVS | `https://cdn.openbsd.org/pub/OpenBSD/7.9` | `anoncvs@anoncvs.example.org:/cvs` | `OPENBSD_7_9` |
| snapshot | mirror archive | `https://cdn.openbsd.org/pub/OpenBSD/snapshots` | omit | omit |
| current | snapshot archive + AnonCVS | `https://cdn.openbsd.org/pub/OpenBSD/snapshots` | `anoncvs@anoncvs.example.org:/cvs` | `current` |

The prefix must contain `ports.tar.gz` and `SHA256.sig`. The archive is verified
before extraction.

## Inputs

| Input | Required | Default | Description |
|---|---:|---|---|
| `repo` | no | `ivoronin/openbsd-cloudimg` | Image repository. |
| `release` | yes | | Image release tag. |
| `image` | yes | | Exact image release asset name. |
| `arch` | yes | | OpenBSD image architecture, `amd64` or `arm64`. |
| `ports` | no | `false` | Prepare `/usr/ports` before running the command. |
| `ports-archive-url-prefix` | no | | URL prefix containing `ports.tar.gz` and `SHA256.sig`. |
| `ports-cvs-root` | no | | AnonCVS root for updating `/usr/ports`. |
| `ports-cvs-ref` | no | | CVS ref for `/usr/ports`; required with `ports-cvs-root`. `current` maps to CVS `-A`. |
| `run` | yes | | Command executed in `/home/openbsd/work`. |
