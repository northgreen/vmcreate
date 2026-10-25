dnl Advanced settings are expressed in m4; the wizard intentionally stays basic.
VM_INIT([server])
VM_MACHINE([q35])
VM_MEMORY([4096])
VM_CPU([1], [4], [1])
VM_DISK([system.qcow2], [qcow2], [virtio])
VM_DISK([scratch.raw], [raw], [ahci], [snapshot])
VM_NET_USER([management], [virtio-net-pci])
VM_NET_FORWARD([management], [tcp], [2225], [22])
VM_NET_FORWARD([management], [udp], [5353], [53])
VM_SHARE([shared], [hostshare], [ro])
VM_HEADLESS
VM_QMP([control.sock])
VM_LOG([debug.log], [guest_errors,unimp])
dnl The kernel/initrd must exist; the command line is literal data, not shell.
VM_KERNEL([vmlinuz], [initrd.img], [root=/dev/vda console=ttyS0])
VM_OUTPUT
