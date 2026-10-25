m4_dnl Console, remote display and host-device declarations.
m4_dnl Included with square quotes active and diversion -1 selected.

m4_define([_VM_ENUM], [m4_ifelse(m4_regexp([$1], [$2]), [0], [], [_VM_FAIL([$3])])])
m4_define([_VM_PORT], [
    _VM_ENUM([$1], [^[1-9][0-9]*$], [invalid port])
    m4_ifelse(m4_eval(m4_len([$1]) > 5), [1], [_VM_FAIL([invalid port])])
    m4_ifelse(m4_eval($1 > 65535), [1], [_VM_FAIL([invalid port])])
])

m4_dnl VM_MONITOR(stdio|none): one interactive stdio owner across all consoles.
m4_define([VM_MONITOR], [
    _VM_READY[]_VM_ARITY([$#], [1], [VM_MONITOR])
    _VM_ENUM([$1], [^\(stdio\|none\)$], [monitor must be stdio or none])
    m4_define([_VM_MONITOR_MODE], [$1])
    m4_divert(1)m4_dnl
monitor_mode='[$1]'
m4_divert(-1)
])

m4_dnl VM_SERIAL(none|stdio|file[,path]): file is guest serial output, not QEMU debug.
m4_define([VM_SERIAL], [
    _VM_READY[]_VM_ONCE([VM_SERIAL])
    m4_ifdef([_VM_SEEN_VM_HEADLESS], [_VM_FAIL([serial conflicts with headless])])
    m4_ifelse([$#], [1], [], [$#], [2], [], [_VM_FAIL([VM_SERIAL expects 1 or 2 arguments])])
    _VM_ENUM([$1], [^\(none\|stdio\|file\)$], [invalid serial mode])
    m4_ifelse([$1], [file], [_VM_ARITY([$#], [2], [VM_SERIAL])_VM_PATH([$2])], [_VM_ARITY([$#], [1], [VM_SERIAL])])
    m4_define([_VM_SERIAL_MODE], [$1])
    m4_divert(1)m4_dnl
serial_mode='[$1]'
m4_ifelse([$1], [file], [serial_path=$(vm_path '[$2]')])
m4_divert(-1)
])

m4_dnl VM_HEADLESS: no local display, monitor disabled, guest serial on stdio.
m4_dnl Guest must still enable its own serial console (e.g. console=ttyS0).
m4_define([VM_HEADLESS], [
    _VM_READY[]_VM_ARITY([$#], [0], [VM_HEADLESS])_VM_ONCE([VM_HEADLESS])
    m4_ifdef([_VM_REMOTE], [_VM_FAIL([headless conflicts with remote display])])
    m4_ifdef([_VM_SEEN_VM_DISPLAY], [_VM_FAIL([headless conflicts with VM_DISPLAY])])
    m4_ifdef([_VM_SERIAL_MODE], [_VM_FAIL([headless conflicts with VM_SERIAL])])
    m4_define([_VM_SERIAL_MODE], [stdio])m4_define([_VM_MONITOR_MODE], [none])
    m4_divert(1)m4_dnl
monitor_mode=none
serial_mode=stdio
args+=(-display none)
m4_divert(-1)
])

m4_dnl VM_DISPLAY retains existing device selection and USB tablet defaults.
m4_define([_VM_ENSURE_USB], [
    m4_ifdef([_VM_USB], [], [
        m4_define([_VM_USB], [1])
        m4_define([_VM_SEEN_VM_HW_USB], [1])
        m4_divert(1)m4_dnl
args+=(-device usb-ehci,id=usb)
m4_divert(-1)
    ])
])
m4_define([VM_DISPLAY], [
    _VM_READY[]_VM_ONCE([VM_DISPLAY])_VM_ARITY([$#], [2], [VM_DISPLAY])
    _VM_ENUM([$1], [^\(gtk\|none\)$], [display must be gtk or none])
    _VM_ENUM([$2], [^\(virtio-gpu-pci\|VGA\)$], [unsupported graphics device])
    m4_ifdef([_VM_SEEN_VM_HEADLESS], [_VM_FAIL([display conflicts with headless])])
    m4_ifelse([$1], [gtk], [m4_ifdef([_VM_REMOTE], [_VM_FAIL([gtk conflicts with remote display])])])
    m4_define([_VM_DISPLAY_MODE], [$1])
    _VM_ENSURE_USB
    m4_divert(1)m4_dnl
args+=(-vga none -device '[$2]' -display '[$1]' -device usb-tablet,bus=usb.0)
m4_divert(-1)
])

m4_define([_VM_REMOTE_CHECK], [
    _VM_READY
    m4_ifdef([_VM_REMOTE], [_VM_FAIL([only one remote display is supported])])
    m4_ifdef([_VM_SEEN_VM_HEADLESS], [_VM_FAIL([remote display conflicts with headless])])
    m4_ifelse(m4_defn([_VM_DISPLAY_MODE]), [gtk], [_VM_FAIL([remote display conflicts with gtk])])
    m4_define([_VM_REMOTE], [1])
])
m4_dnl VM_VNC(display): loopback TCP port 5900+display; use an SSH tunnel remotely.
m4_define([VM_VNC], [
    _VM_REMOTE_CHECK[]_VM_ARITY([$#], [1], [VM_VNC])
    _VM_ENUM([$1], [^\(0\|[1-9][0-9]*\)$], [invalid VNC display])
    m4_ifelse(m4_eval(m4_len([$1]) > 4), [1], [_VM_FAIL([invalid VNC display])])
    m4_divert(1)m4_dnl
args+=(-display none -vnc '127.0.0.1:[$1]')
m4_divert(-1)
])
m4_dnl VM_SPICE(port): loopback only, unauthenticated local connection, tunnel externally.
m4_define([VM_SPICE], [
    _VM_REMOTE_CHECK[]_VM_ARITY([$#], [1], [VM_SPICE])_VM_PORT([$1])
    m4_divert(1)m4_dnl
args+=(-display none -spice 'addr=127.0.0.1,port=[$1],disable-ticketing=on')
m4_divert(-1)
])

m4_dnl VM_LOG(path,items): QEMU -d debug categories; not stderr capture.
m4_define([VM_LOG], [
    _VM_READY[]_VM_ONCE([VM_LOG])_VM_ARITY([$#], [2], [VM_LOG])_VM_PATH([$1])
    _VM_ENUM([$2], [^[a-zA-Z0-9_,]+$], [invalid log items])
    m4_divert(1)m4_dnl
args+=(-D "$(vm_path '[$1]')" -d '[$2]')
m4_divert(-1)
])
m4_dnl VM_QMP(path): Unix control socket; parent directory must already exist.
m4_define([VM_QMP], [
    _VM_READY[]_VM_ONCE([VM_QMP])_VM_ARITY([$#], [1], [VM_QMP])_VM_PATH([$1])
    m4_divert(1)m4_dnl
args+=(-qmp "unix:$(vm_path '[$1]'),server=on,wait=off")
m4_divert(-1)
])

m4_dnl VM_USB_HOST(bus,address): explicit USB controller shared with VM_DISPLAY.
m4_dnl Permissions and host enumeration are the caller's responsibility.
m4_define([VM_USB_HOST], [
    _VM_READY[]_VM_ARITY([$#], [2], [VM_USB_HOST])
    _VM_ENUM([$1], [^[1-9][0-9]*$], [invalid USB bus])
    _VM_ENUM([$2], [^[1-9][0-9]*$], [invalid USB address])
    m4_ifelse(m4_eval(m4_len([$1]) > 3 || m4_len([$2]) > 3), [1], [_VM_FAIL([USB bus/address out of range])])
    m4_ifelse(m4_eval($1 > 255 || $2 > 127), [1], [_VM_FAIL([USB bus/address out of range])])
    m4_ifdef([_VM_USB_$1_$2], [_VM_FAIL([duplicate USB host device])])
    m4_define([_VM_USB_$1_$2], [1])_VM_ENSURE_USB
    m4_divert(1)m4_dnl
args+=(-device 'usb-host,bus=usb.0,hostbus=[$1],hostaddr=[$2]')
m4_divert(-1)
])
m4_dnl VM_VFIO(domain:bus:slot.function): no automatic driver binding/IOMMU changes.
m4_define([VM_VFIO], [
    _VM_READY[]_VM_ARITY([$#], [1], [VM_VFIO])
    _VM_ENUM([$1], [^[0-9a-f][0-9a-f][0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[01][0-9a-f]\.[0-7]$], [invalid canonical VFIO address])
    m4_ifdef([_VM_VFIO_$1], [_VM_FAIL([duplicate VFIO host device])])m4_define([_VM_VFIO_$1], [1])
    m4_divert(1)m4_dnl
args+=(-device 'vfio-pci,host=[$1]')
m4_divert(-1)
])

m4_dnl VM_SHARE(path,tag[,rw|ro]): enforce readonly at daemon, not guest mount.
m4_define([VM_SHARE], [
    _VM_READY[]_VM_ONCE([VM_SHARE])
    m4_ifelse([$#], [2], [], [$#], [3], [], [_VM_FAIL([VM_SHARE expects 2 or 3 arguments])])
    _VM_PATH([$1])_VM_ENUM([$2], [^[a-zA-Z0-9_-]+$], [invalid share tag])
    m4_ifelse([$#], [3], [_VM_ENUM([$3], [^\(rw\|ro\)$], [share mode must be rw or ro])])
    m4_divert(1)m4_dnl
share_dir=$(vm_path '[$1]')
m4_ifelse([$3], [ro], [virtiofs_args+=(--readonly)])
args+=(-chardev "socket,id=charfs,path=$runtime_dir/virtiofs.sock"
       -device 'vhost-user-fs-pci,chardev=charfs,tag=[$2]')
m4_divert(-1)
])

m4_dnl Final checks are order independent; defaults match the legacy template.
m4_define([_VM_CONTROL_CHECK], [
    m4_ifdef([_VM_MONITOR_MODE], [], [m4_define([_VM_MONITOR_MODE], [stdio])])
    m4_ifelse(m4_defn([_VM_SERIAL_MODE]), [stdio], [
        m4_ifelse(m4_defn([_VM_MONITOR_MODE]), [stdio], [_VM_FAIL([serial and monitor cannot both use stdio])])
    ])
])
