#!/bin/ksh

set -eu

IFS= read -r ports_archive_url_prefix
IFS= read -r ports_cvs_root
IFS= read -r ports_cvs_ref

if [ -z "$ports_archive_url_prefix" ] && [ -z "$ports_cvs_root" ]; then
  echo "ports requires ports-archive-url-prefix or ports-cvs-root" >&2
  exit 2
fi

if [ -n "$ports_cvs_root" ] && [ -z "$ports_cvs_ref" ]; then
  echo "ports-cvs-ref is required when ports-cvs-root is set" >&2
  exit 2
fi

ports_tmp=$(mktemp -d /tmp/openbsd-action-ports.XXXXXXXXXX)
trap 'rm -rf "$ports_tmp"' EXIT HUP INT TERM

archive_file="$ports_tmp/ports.tar.gz"
sig_file="$ports_tmp/SHA256.sig"

if [ -n "$ports_archive_url_prefix" ]; then
  while [ "${ports_archive_url_prefix%/}" != "$ports_archive_url_prefix" ]; do
    ports_archive_url_prefix=${ports_archive_url_prefix%/}
  done

  if [ -z "$ports_archive_url_prefix" ]; then
    echo "ports-archive-url-prefix must not be only slashes" >&2
    exit 2
  fi

  ports_archive="$ports_archive_url_prefix/ports.tar.gz"
  sig_url="$ports_archive_url_prefix/SHA256.sig"

  echo "Download ports archive: $ports_archive"
  ftp -o "$archive_file" "$ports_archive"

  echo "Verify ports archive with $sig_url"
  ftp -o "$sig_file" "$sig_url"

  verified=0
  verify_log="$ports_tmp/signify.log"
  for signify_key in /etc/signify/openbsd-*-base.pub; do
    [ -f "$signify_key" ] || continue
    if (
      cd "$ports_tmp"
      signify -Cp "$signify_key" -x "$sig_file" ports.tar.gz
    ) >"$verify_log" 2>&1; then
      cat "$verify_log"
      verified=1
      break
    fi
  done

  if [ "$verified" -ne 1 ]; then
    echo "ports archive verification failed with /etc/signify/openbsd-*-base.pub" >&2
    cat "$verify_log" >&2 || true
    exit 1
  fi

  echo "Extract ports archive into /usr"
  doas rm -rf /usr/ports
  doas tar -xzf "$archive_file" -C /usr
fi

if [ ! -d /usr/ports ]; then
  if [ -z "$ports_cvs_root" ]; then
    echo "ports tree was not created and ports-cvs-root is empty" >&2
    exit 1
  fi

  echo "Check out ports tree from AnonCVS"
  doas mkdir -p /usr/ports
  doas chown openbsd:wsrc /usr/ports
  doas chmod 775 /usr/ports

  export CVS_RSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/tmp/openbsd-action-ports-known_hosts"

  cd /usr
  case "$ports_cvs_ref" in
    current)
      cvs -qd "$ports_cvs_root" checkout -P ports
      ;;
    *)
      cvs -qd "$ports_cvs_root" checkout -r"$ports_cvs_ref" -P ports
      ;;
  esac
fi

echo "Configure ports permissions"
doas chown -R openbsd:wsrc /usr/ports
doas chmod -R u+rwX,g+rwX /usr/ports

if [ -n "$ports_cvs_root" ]; then
  echo "Update ports tree from AnonCVS"
  export CVS_RSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/tmp/openbsd-action-ports-known_hosts"

  cd /usr/ports
  case "$ports_cvs_ref" in
    current)
      echo "ports-cvs-ref current maps to CVS -A"
      cvs -d "$ports_cvs_root" -q up -Pd -A
      ;;
    *)
      echo "ports-cvs-ref $ports_cvs_ref maps to CVS -r$ports_cvs_ref"
      cvs -d "$ports_cvs_root" -q up -Pd -r"$ports_cvs_ref"
      ;;
  esac
fi
