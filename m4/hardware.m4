m4_divert(-1)m4_dnl

m4_dnl Hardware/storage extension: include after vm.m4, before configuration.
m4_define([_VM_HW_MACHINE], [])
m4_define([_VM_HW_ARCH], [x86_64])
m4_define([_VM_HW_QEMU], [])
m4_define([_VM_HW_ACCEL], [kvm])
m4_define([_VM_HW_CPU], [host])
m4_define([_VM_IDE_COUNT], [0])
m4_define([_VM_IDE_CAPACITY], [6])
m4_define([_VM_IDE_DISKS], [])
m4_define([_VM_CDROM_FILES], [])
m4_define([_VM_FLOPPY_FILES], [])
m4_define([_VM_DISK_COUNT], [0])
m4_define([_VM_AHCI_COUNT], [0])

m4_dnl _VM_HW_ARITY(actual, minimum, maximum, name)
m4_define([_VM_HW_ARITY], [
    m4_ifelse(m4_eval($1 < $2 || $1 > $3), [1], [_VM_FAIL([$4: expected $2 to $3 arguments, got $1])])
])

m4_dnl _VM_HW_FIELD(value, regex, limit, name)
m4_dnl Bound text before parsing; never feed user numbers into m4_eval.
m4_define([_VM_HW_FIELD], [
    _VM_VALUE([$1])
    m4_ifelse(m4_eval(m4_len([$1]) > $3), [1], [_VM_FAIL([$4: value too long (maximum $3 characters)])])
    m4_ifelse(m4_regexp([$1], [$2]), [0], [], [_VM_FAIL([$4: invalid value: $1])])
])

m4_dnl VM_MACHINE(spec)
m4_dnl pc/q35 aliases or versioned pc-i440fx/pc-q35, with safe key=value fields.
m4_define([VM_MACHINE], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_MACHINE])
    _VM_ONCE([VM_MACHINE])
    _VM_HW_FIELD([$1], [^\(pc\|q35\|pc-\(i440fx\|q35\)-[0-9]+\.[0-9]+\)\(,[a-zA-Z][a-zA-Z0-9_-]*=[a-zA-Z0-9_.-]+\)*$], [1024], [VM_MACHINE])
    m4_ifelse(m4_regexp([$1], [,type=]), [-1], [], [_VM_FAIL([VM_MACHINE: type property is not allowed])])
    m4_ifelse(m4_regexp([$1], [,accel=]), [-1], [], [_VM_FAIL([VM_MACHINE: accel property is not allowed; use VM_ACCEL])])
    m4_define([_VM_HW_MACHINE], m4_ifelse(m4_regexp([$1], [^\(q35\|pc-q35-\)]), [0], [q35], [pc]))
    m4_ifelse(_VM_HW_MACHINE, [pc], [m4_define([_VM_IDE_CAPACITY], [4])])
    m4_divert(1)m4_dnl
machine_spec='[$1]'
m4_divert(-1)
])

m4_dnl VM_ACCEL(kvm|tcg)
m4_define([VM_ACCEL], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_ACCEL])
    _VM_ONCE([VM_ACCEL])
    m4_ifelse([$1], [kvm], [], [$1], [tcg], [], [_VM_FAIL([VM_ACCEL: expected kvm or tcg])])
    m4_define([_VM_HW_ACCEL], [$1])
    m4_divert(1)m4_dnl
accel='[$1]'
m4_divert(-1)
])

m4_dnl VM_ARCH(arch)
m4_dnl Emulated architecture; selects qemu-system-<arch> when VM_QEMU is absent.
m4_dnl Non-x86 guests keep QEMU's own default machine and must not use VM_MACHINE.
m4_define([VM_ARCH], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_ARCH])
    _VM_ONCE([VM_ARCH])
    _VM_HW_FIELD([$1], [^[a-z][a-z0-9_]*$], [32], [VM_ARCH])
    m4_define([_VM_HW_ARCH], [$1])
])

m4_dnl VM_QEMU(command)
m4_dnl QEMU binary name or absolute path; arguments are not accepted, use a wrapper.
m4_define([VM_QEMU], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_QEMU])
    _VM_ONCE([VM_QEMU])
    _VM_HW_FIELD([$1], [^[A-Za-z0-9_./+][A-Za-z0-9_./+-]*$], [1024], [VM_QEMU])
    m4_define([_VM_HW_QEMU], [$1])
])

m4_dnl VM_CPU_MODEL(model)
m4_define([VM_CPU_MODEL], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_CPU_MODEL])
    _VM_ONCE([VM_CPU_MODEL])
    _VM_HW_FIELD([$1], [^[a-zA-Z0-9][a-zA-Z0-9_.-]*$], [128], [VM_CPU_MODEL])
    m4_define([_VM_HW_CPU], [$1])
    m4_divert(1)m4_dnl
cpu_model='[$1]'
m4_divert(-1)
])

m4_dnl VM_CPU_FLAGS(flags)
m4_dnl Safe comma-separated +feature/-feature or feature=value, at most 1024 bytes.
m4_define([VM_CPU_FLAGS], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_CPU_FLAGS])
    _VM_ONCE([VM_CPU_FLAGS])
    _VM_HW_FIELD([$1], [^\([+-][a-zA-Z][a-zA-Z0-9_.-]*\|[a-zA-Z][a-zA-Z0-9_.-]*=[a-zA-Z0-9_.-]+\)\(,\([+-][a-zA-Z][a-zA-Z0-9_.-]*\|[a-zA-Z][a-zA-Z0-9_.-]*=[a-zA-Z0-9_.-]+\)\)*$], [1024], [VM_CPU_FLAGS])
    m4_divert(1)m4_dnl
cpu_flags='[$1]'
m4_divert(-1)
])

m4_dnl _VM_BOOT_ORDER(order)
m4_dnl Each of a/c/d/n may appear at most once.
m4_define([_VM_BOOT_ORDER], [
    _VM_HW_FIELD([$1], [^[acdn]+$], [4], [VM_BOOT])
    m4_ifelse(m4_regexp([$1], [\(.\).*\1]), [-1], [], [_VM_FAIL([VM_BOOT: duplicate boot letter])])
])

m4_dnl VM_BOOT(order[, once[, menu]])
m4_define([VM_BOOT], [
    _VM_READY
    _VM_HW_ARITY([$#], [1], [3], [VM_BOOT])
    _VM_ONCE([VM_BOOT])
    _VM_BOOT_ORDER([$1])
    m4_ifelse([$2], [], [], [_VM_BOOT_ORDER([$2])])
    m4_ifelse([$#], [3], [m4_ifelse([$3], [on], [], [$3], [off], [], [_VM_FAIL([VM_BOOT: menu must be on or off])])])
    m4_divert(1)m4_dnl
boot_opt='order=[$1]m4_ifelse([$2], [], [], [,once=[$2]])m4_ifelse([$#], [3], [,menu=[$3]])'
m4_divert(-1)
])

m4_dnl _VM_STORAGE_MODE(mode)
m4_define([_VM_STORAGE_MODE], [
    m4_ifelse([$1], [rw], [], [$1], [ro], [], [$1], [snapshot], [], [_VM_FAIL([storage mode must be rw, ro or snapshot])])
])

m4_dnl _VM_STORAGE_OPTIONS(mode): emit only validated QEMU option suffixes.
m4_define([_VM_STORAGE_OPTIONS], [m4_ifelse([$1], [ro], [,readonly=on], [$1], [snapshot], [,snapshot=on], [])])

m4_dnl _VM_IDE_ALLOC: reserve one shared IDE slot; family-specific check is final.
m4_define([_VM_IDE_ALLOC], [
    m4_ifelse(m4_eval(_VM_IDE_COUNT >= 6), [1], [_VM_FAIL([IDE supports at most 6 devices on q35 (4 on pc)])])
    m4_define([_VM_IDE_INDEX], _VM_IDE_COUNT)
    m4_define([_VM_IDE_COUNT], m4_incr(_VM_IDE_COUNT))
])

m4_dnl VM_DISK(file, format, bus[, mode])
m4_dnl Repeatable raw/qcow2 disks; AHCI controllers each provide six ports.
m4_define([VM_DISK], [
    _VM_READY
    _VM_HW_ARITY([$#], [3], [4], [VM_DISK])
    _VM_PATH([$1])
    m4_ifelse([$2], [raw], [], [$2], [qcow2], [], [_VM_FAIL([disk format must be qcow2 or raw])])
    m4_ifelse([$3], [ahci], [], [$3], [ide], [], [$3], [virtio], [], [_VM_FAIL([disk bus must be ahci, ide or virtio])])
    m4_pushdef([_VM_MODE], m4_ifelse([$#], [3], [rw], [$4]))
    _VM_STORAGE_MODE(m4_defn([_VM_MODE]))
    m4_ifelse(_VM_MODE, [ro], [m4_ifelse([$3], [virtio], [], [_VM_FAIL([read-only disks require virtio; IDE/AHCI disks do not support ro])])])
    m4_ifelse([$3], [ide], [_VM_IDE_ALLOC])
    m4_pushdef([_VM_DISK_ID], [vmcreate_disk]_VM_DISK_COUNT)
    m4_divert(1)m4_dnl
m4_ifelse([$3], [ahci], [m4_ifelse(m4_eval(_VM_AHCI_COUNT % 6), [0], [args+=(-device ahci,id=vmcreate_ahci[]m4_eval(_VM_AHCI_COUNT / 6))
])args+=(-drive "id=_VM_DISK_ID,if=none,file=$(vm_path '[$1]'),format=[$2]_VM_STORAGE_OPTIONS(_VM_MODE)"
    -device ide-hd,drive=_VM_DISK_ID,bus=vmcreate_ahci[]m4_eval(_VM_AHCI_COUNT / 6).[]m4_eval(_VM_AHCI_COUNT % 6))
], [args+=(-drive "id=_VM_DISK_ID,if=[$3],file=$(vm_path '[$1]'),format=[$2]m4_ifelse([$3], [ide], [,index=_VM_IDE_INDEX])[]_VM_STORAGE_OPTIONS(_VM_MODE)")
])m4_divert(-1)
    m4_ifelse([$3], [ahci], [m4_define([_VM_AHCI_COUNT], m4_incr(_VM_AHCI_COUNT))])
    m4_define([_VM_DISK_COUNT], m4_incr(_VM_DISK_COUNT))
    m4_popdef([_VM_DISK_ID], [_VM_MODE])
])

m4_dnl VM_CDROM(iso_file)
m4_dnl Recorded now, placed at VM_OUTPUT so IDE indexes match declared order and
m4_dnl the boot script can replace them from the command line.
m4_define([VM_CDROM], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_CDROM])
    _VM_PATH([$1])
    _VM_IDE_ALLOC
    m4_divert(1)m4_dnl
args+=(-drive "file=$(vm_path '[$1]'),format=raw,media=cdrom,readonly=on,if=ide,index=_VM_IDE_INDEX")
m4_divert(-1)
])

m4_dnl VM_FLOPPY(file[, unit[, mode]])
m4_dnl Unit defaults to 0, mode to rw; explicitly selected units must be unique.
m4_define([VM_FLOPPY], [
    _VM_READY
    _VM_HW_ARITY([$#], [1], [3], [VM_FLOPPY])
    _VM_PATH([$1])
    m4_pushdef([_VM_UNIT], m4_ifelse([$#], [1], [0], [[$2]]))
    m4_pushdef([_VM_MODE], m4_ifelse([$#], [3], [[$3]], [rw]))
    m4_ifelse(m4_defn([_VM_UNIT]), [0], [], m4_defn([_VM_UNIT]), [1], [], [_VM_FAIL([VM_FLOPPY: unit must be 0 or 1])])
    _VM_STORAGE_MODE(m4_defn([_VM_MODE]))
    _VM_ONCE([VM_FLOPPY_UNIT_]_VM_UNIT)
    m4_divert(1)m4_dnl
args+=(-drive "file=$(vm_path '[$1]'),format=raw,if=floppy,index=_VM_UNIT[]_VM_STORAGE_OPTIONS(_VM_MODE)")
m4_divert(-1)
    m4_popdef([_VM_UNIT], [_VM_MODE])
])

m4_dnl VM_SNAPSHOT (bare): apply QEMU's global temporary-write mode.
m4_define([VM_SNAPSHOT], [
    _VM_READY
    _VM_ARITY([$#], [0], [VM_SNAPSHOT])
    _VM_ONCE([VM_SNAPSHOT])
    m4_divert(1)m4_dnl
args+=(-snapshot)
m4_divert(-1)
])

m4_dnl VM_KERNEL(kernel[, initrd[, cmdline]])
m4_dnl Empty initrd/cmdline omit their options; command line is a literal, not eval.
m4_define([VM_KERNEL], [
    _VM_READY
    _VM_HW_ARITY([$#], [1], [3], [VM_KERNEL])
    _VM_ONCE([VM_KERNEL])
    _VM_PATH([$1])
    m4_ifelse([$2], [], [], [_VM_PATH([$2])])
    m4_ifelse([$3], [], [], [_VM_VALUE([$3])])
    m4_divert(1)m4_dnl
args+=(-kernel "$(vm_path '[$1]')")
m4_ifelse([$2], [], [], [args+=(-initrd "$(vm_path '[$2]')")
])m4_ifelse([$3], [], [], [args+=(-append '[$3]')
])m4_divert(-1)
])

m4_dnl _VM_ARCH_IS_X86: 1 for the architectures served by qemu-system-x86_64.
m4_define([_VM_ARCH_IS_X86], [m4_ifelse(m4_regexp(_VM_HW_ARCH, [^\(x86_64\|i386\)$]), [0], [1], [0])])

m4_dnl _VM_IDE_CDROMS_WANTED: how many CDROMs the own lists declare.
m4_define([_VM_IDE_CDROMS_WANTED], [m4_ifelse(_VM_CDROM_FILES, [], [0], [m4_len(_VM_CDROM_FILES)])])

m4_dnl _VM_HARDWARE_CHECK: call from VM_OUTPUT before template emission.
m4_dnl Resolves the default machine for the chosen architecture and the QEMU
m4_dnl binary, then rejects combinations QEMU cannot start.
m4_define([_VM_HARDWARE_CHECK], [
    m4_ifelse(_VM_HW_MACHINE, [], [m4_ifelse(_VM_ARCH_IS_X86, [1], [m4_define([_VM_IDE_CAPACITY], [6])], [m4_define([_VM_IDE_CAPACITY], [0])])])
    m4_ifelse(_VM_HW_ACCEL, [tcg], [m4_ifelse(m4_defn([_VM_HW_CPU]), [host], [_VM_FAIL([CPU model host requires kvm; choose a CPU model for tcg])])])
    m4_ifelse(m4_eval(_VM_IDE_COUNT > _VM_IDE_CAPACITY), [1], [_VM_FAIL([too many IDE disks/CDROMs for this machine (maximum _VM_IDE_CAPACITY)])])
    m4_ifelse(_VM_ARCH_IS_X86, [1], [], [m4_ifelse(_VM_HW_MACHINE, [], [], [_VM_FAIL([VM_MACHINE is x86-only; _VM_HW_ARCH uses the QEMU default machine])])])
    m4_ifelse(_VM_ARCH_IS_X86, [1], [], [m4_ifelse(m4_eval(_VM_IDE_COUNT > 0), [1], [_VM_FAIL([non-x86 architectures have no IDE controller; use virtio])])])
    m4_divert(1)m4_dnl
machine_spec='m4_ifelse(_VM_HW_MACHINE, [], [m4_ifelse(_VM_ARCH_IS_X86, [1], [q35,smm=on], [])], [m4_defn([_VM_HW_MACHINE])])'
qemu_bin='m4_ifelse(_VM_HW_QEMU, [], [qemu-system-_VM_HW_ARCH], [m4_defn([_VM_HW_QEMU])])'
ide_capacity=_VM_IDE_CAPACITY
m4_divert(-1)
])

m4_dnl VM_AUDIO(pa|pipewire): one Intel HDA output; the audio backend is host-local.
m4_define([VM_AUDIO], [
    _VM_READY[]_VM_ONCE([VM_AUDIO])_VM_ARITY([$#], [1], [VM_AUDIO])
    m4_ifelse([$1], [pa], [], [$1], [pipewire], [], [_VM_FAIL([audio must be pa or pipewire])])
    m4_divert(1)m4_dnl
args+=(-audiodev '[$1],id=audio0' -device intel-hda -device hda-output,audiodev=audio0)
m4_divert(-1)
])
m4_dnl VM_UEFI(code,vars): unit 0 is read-only firmware, unit 1 writable variables.
m4_define([VM_UEFI], [
    _VM_READY[]_VM_ONCE([VM_UEFI])_VM_ARITY([$#], [2], [VM_UEFI])
    _VM_PATH([$1])_VM_PATH([$2])
    m4_divert(1)m4_dnl
args+=(-drive "if=pflash,format=raw,unit=0,file=$(vm_path '[$1]'),readonly=on"
       -drive "if=pflash,format=raw,unit=1,file=$(vm_path '[$2]')")
m4_divert(-1)
])
m4_dnl VM_TPM(dir): TPM 2.0 state directory is persistent across temporary boots.
m4_define([VM_TPM], [
    _VM_READY[]_VM_ONCE([VM_TPM])_VM_ARITY([$#], [1], [VM_TPM])_VM_PATH([$1])
    m4_divert(1)m4_dnl
tpm_dir=$(vm_path '[$1]')
args+=(-chardev "socket,id=chrtpm,path=$runtime_dir/tpm.sock"
       -tpmdev emulator,id=tpm0,chardev=chrtpm
       -device tpm-tis,tpmdev=tpm0)
m4_divert(-1)
])
m4_dnl VM_GUEST_AGENT: guest-side daemon is required; this only exposes the port.
m4_define([VM_GUEST_AGENT], [
    _VM_READY[]_VM_ONCE([VM_GUEST_AGENT])_VM_ARITY([$#], [0], [VM_GUEST_AGENT])
    m4_divert(1)m4_dnl
args+=(-device virtio-serial
       -chardev "socket,path=$runtime_dir/qga.sock,server=on,wait=off,id=agent"
       -device virtserialport,chardev=agent,name=org.qemu.guest_agent.0)
m4_divert(-1)
])
