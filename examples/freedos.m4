dnl Legacy PC hardware with software acceleration; no UEFI or VirtIO drivers needed.
dnl Place existing images beside the generated boot.sh (or use absolute paths).
VM_INIT([freedos])
VM_MACHINE([pc])
VM_ACCEL([tcg])
VM_CPU_MODEL([qemu32])
VM_MEMORY([64])
VM_CPU([1], [1], [1])
VM_DISK([hdd.img], [raw], [ide])
VM_FLOPPY([FD14BOOT.img], [0], [ro])
VM_CDROM([FD14LIVE.iso])
VM_BOOT([cad], [a], [on])
VM_DISPLAY([gtk], [VGA])
VM_OUTPUT
