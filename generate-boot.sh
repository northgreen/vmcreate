#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s CONFIG.m4 OUTPUT/boot.sh\n' "$0" >&2
    exit 2
fi

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
input=$1
output=$2
if [[ ! -f "$input" ]]; then
    printf 'vmcreate: configuration not found: %s\n' "$input" >&2
    exit 1
fi
if [[ -d "$output" ]]; then
    printf 'vmcreate: output must be a file, not a directory\n' >&2
    exit 1
fi
if [[ "$input" -ef "$output" ]]; then
    printf 'vmcreate: output must not replace the configuration\n' >&2
    exit 1
fi
# Reject misspelled public macros before discarded m4 text can hide them.
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*(VM_[A-Z_]+) ]]; then
        case "${BASH_REMATCH[1]}" in
            VM_MACHINE|VM_ARCH|VM_QEMU|VM_ACCEL|VM_CPU_MODEL|VM_CPU_FLAGS|VM_BOOT|VM_FLOPPY|VM_SNAPSHOT|VM_KERNEL|VM_NET_USER|VM_NET_FORWARD|VM_NET_TAP|VM_NET_BRIDGE|VM_MONITOR|VM_SERIAL|VM_HEADLESS|VM_VNC|VM_SPICE|VM_LOG|VM_QMP|VM_USB_HOST|VM_VFIO|VM_INIT|VM_MEMORY|VM_CPU|VM_UEFI|VM_DISK|VM_CDROM|VM_NETWORK_USER|VM_TPM|VM_SHARE|VM_DISPLAY|VM_AUDIO|VM_GUEST_AGENT|VM_OUTPUT) ;;
            *) printf 'vmcreate: unknown macro: %s\n' "${BASH_REMATCH[1]}" >&2; exit 1 ;;
        esac
    fi
done < "$input"
command -v m4 >/dev/null || { printf 'vmcreate: GNU m4 is required\n' >&2; exit 1; }
mkdir -p -- "$(dirname -- "$output")"
# Stage beside the destination: failed expansion never replaces an existing script.
temporary=$(mktemp "${output}.tmp.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
# Prefixed builtins avoid collisions with ordinary words in shell/config text.
m4 --fatal-warnings -P -I "$root/m4" -I "$root" -- "$root/m4/vm.m4" "$input" > "$temporary"
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*VM_[A-Z_]+ ]]; then
        printf 'vmcreate: unexpanded macro: %s\n' "$line" >&2
        exit 1
    fi
done < "$temporary"
# Publish only a syntactically valid script; same-directory rename is atomic.
bash -n "$temporary"
chmod +x "$temporary"
mv -f -- "$temporary" "$output"
printf 'Generated %s\n' "$output"
