dnl Paths are relative to the generated boot.sh, not this configuration.
VM_INIT([ubuntu])
VM_MEMORY([16384])
VM_CPU([1], [4], [1])

dnl Existing firmware, disk and installation media; no files are created.
VM_UEFI([/usr/share/OVMF/x64/OVMF_CODE.secboot.4m.fd], [my_vars.fd])
VM_DISK([hdd.img], [qcow2], [ahci])
VM_CDROM([/home/ictye/Downloads/ubuntukylin-16.04.7-desktop-amd64.iso])

dnl Host-local forwarding and optional guest devices.
VM_NETWORK_USER([2223], [22])
VM_DISPLAY([gtk], [virtio-gpu-pci])
VM_AUDIO([pa])

dnl Emit the standalone startup script after all settings.
VM_OUTPUT
