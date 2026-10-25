m4_divert(-1)m4_dnl

m4_dnl Included after vm.m4; statements join diversion 1.
m4_define([_VM_NET_NEXT], [0])

m4_define([_VM_NET_ID], [
    _VM_VALUE([$1])
    m4_ifelse(m4_regexp([$1], [^[a-zA-Z_][a-zA-Z0-9_]*$]), [0], [], [_VM_FAIL([invalid network identifier: $1])])
    m4_ifelse(m4_regexp([$1], [^vmcreate_]), [0], [_VM_FAIL([network identifier prefix vmcreate_ is reserved])])
])

m4_define([_VM_NET_MODEL], [
    m4_ifelse([$1], [virtio-net-pci], [], [$1], [e1000], [], [$1], [rtl8139], [], [_VM_FAIL([unsupported network model: $1])])
])

m4_define([_VM_NET_MAC], [
    m4_ifelse([$1], [], [], [
        _VM_VALUE([$1])
        m4_ifelse(m4_regexp([$1], [^[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]$]), [0], [], [_VM_FAIL([invalid network MAC: $1])])
    ])
])

m4_dnl Limit decimal width before evaluating; canonical decimal avoids octal aliases.
m4_define([_VM_NET_PORT], [
    _VM_VALUE([$1])
    m4_ifelse(m4_regexp([$1], [^[1-9][0-9]*$]), [0], [], [_VM_FAIL([invalid network port: $1])])
    m4_ifelse(m4_eval(m4_len([$1]) > 5), [1], [_VM_FAIL([network port exceeds 65535])])
    m4_ifelse(m4_eval([$1 > 65535]), [1], [_VM_FAIL([network port exceeds 65535])])
])

m4_define([_VM_NET_OCTET], [
    m4_ifelse(m4_regexp([$1], [^\(0\|[1-9][0-9]?\|[1-9][0-9][0-9]\)$]), [0], [], [_VM_FAIL([invalid host IPv4 octet: $1])])
    m4_ifelse(m4_eval([$1 > 255]), [1], [_VM_FAIL([host IPv4 octet exceeds 255])])
])

m4_define([_VM_NET_IPV4], [
    _VM_VALUE([$1])
    m4_ifelse(m4_regexp([$1], [^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$]), [0], [], [_VM_FAIL([invalid host IPv4: $1])])
    _VM_NET_OCTET(m4_regexp([$1], [^\([0-9]+\)\.], [\1]))
    _VM_NET_OCTET(m4_regexp([$1], [^[0-9]+\.\([0-9]+\)\.], [\1]))
    _VM_NET_OCTET(m4_regexp([$1], [^[0-9]+\.[0-9]+\.\([0-9]+\)\.], [\1]))
    _VM_NET_OCTET(m4_regexp([$1], [\.\([0-9]+\)$], [\1]))
])

m4_define([_VM_NET_INTERFACE], [
    _VM_PATH([$1])
    m4_ifelse(m4_regexp([$1], [^[a-zA-Z0-9_.-]+$]), [0], [], [_VM_FAIL([invalid network interface: $1])])
])

m4_dnl _VM_NET_BACKEND(id, type, options, model, mac, numeric_index)
m4_dnl Double brackets preserve Bash subscripts; quoted data survives m4 rescans.
m4_define([_VM_NET_BACKEND], [
    m4_ifdef([_VM_NET_TYPE_$1], [_VM_FAIL([duplicate network identifier: $1])])
    m4_define([_VM_NET_TYPE_$1], [$2])
    m4_define([_VM_NET_INDEX_$1], [$6])
    m4_divert(1)m4_dnl
net_backends[[$6]]='[$2],id=[$1][$3]'
args+=(-device '[$4],netdev=[$1]m4_ifelse([$5], [], [], [[,mac=$5]])')
m4_divert(-1)
    m4_define([_VM_NET_NEXT], m4_incr(_VM_NET_NEXT))
])

m4_dnl VM_NET_USER(id, model[, mac])
m4_define([VM_NET_USER], [
    _VM_READY
    m4_ifelse([$#], [3], [], [_VM_ARITY([$#], [2], [VM_NET_USER])])
    _VM_NET_ID([$1])
    _VM_NET_MODEL([$2])
    _VM_NET_MAC([$3])
    _VM_NET_BACKEND([$1], [user], [], [$2], [$3], _VM_NET_NEXT)
])

m4_dnl VM_NET_TAP(id, ifname, model[, mac]); never runs host scripts.
m4_define([VM_NET_TAP], [
    _VM_READY
    m4_ifelse([$#], [4], [], [_VM_ARITY([$#], [3], [VM_NET_TAP])])
    _VM_NET_ID([$1])
    _VM_NET_INTERFACE([$2])
    _VM_NET_MODEL([$3])
    _VM_NET_MAC([$4])
    _VM_NET_BACKEND([$1], [tap], [,ifname=$2,script=no,downscript=no], [$3], [$4], _VM_NET_NEXT)
])

m4_dnl VM_NET_BRIDGE(id, bridge, model[, mac]); uses QEMU's bridge helper.
m4_define([VM_NET_BRIDGE], [
    _VM_READY
    m4_ifelse([$#], [4], [], [_VM_ARITY([$#], [3], [VM_NET_BRIDGE])])
    _VM_NET_ID([$1])
    _VM_NET_INTERFACE([$2])
    _VM_NET_MODEL([$3])
    _VM_NET_MAC([$4])
    _VM_NET_BACKEND([$1], [bridge], [,br=$2], [$3], [$4], _VM_NET_NEXT)
])

m4_dnl _VM_NET_BIND(protocol, hostport, IPv4): reject exact and wildcard overlaps.
m4_define([_VM_NET_BIND], [
    m4_ifdef([_VM_NET_BIND_$1_$2_$3], [_VM_FAIL([duplicate network forward bind])])
    m4_ifdef([_VM_NET_BIND_$1_$2_0.0.0.0], [_VM_FAIL([network forward overlaps wildcard bind])])
    m4_ifelse([$3], [0.0.0.0], [
        m4_ifdef([_VM_NET_BOUND_$1_$2], [_VM_FAIL([wildcard network forward overlaps existing bind])])
    ])
    m4_define([_VM_NET_BIND_$1_$2_$3], [1])
    m4_define([_VM_NET_BOUND_$1_$2], [1])
])

m4_define([_VM_NET_FORWARD_EMIT], [
    m4_divert(1)m4_dnl
net_backends[[$1]]+=',hostfwd=[$2]:[$5]:[$3]-:[$4]'
m4_divert(-1)
])

m4_dnl VM_NET_FORWARD(id, tcp|udp, hostport, guestport[, hostIPv4=127.0.0.1])
m4_dnl An explicit fifth argument must be a nonempty canonical IPv4 address.
m4_define([VM_NET_FORWARD], [
    _VM_READY
    m4_ifelse([$#], [5], [], [_VM_ARITY([$#], [4], [VM_NET_FORWARD])])
    _VM_NET_ID([$1])
    m4_ifdef([_VM_NET_TYPE_$1], [], [_VM_FAIL([network forward requires a previously declared user backend: $1])])
    m4_ifelse(m4_indir([_VM_NET_TYPE_$1]), [user], [], [_VM_FAIL([network forward requires a user backend: $1])])
    m4_ifelse([$2], [tcp], [], [$2], [udp], [], [_VM_FAIL([network forward protocol must be tcp or udp])])
    _VM_NET_PORT([$3])
    _VM_NET_PORT([$4])
    m4_ifelse([$#], [4], [VM_NET_FORWARD([$1], [$2], [$3], [$4], [127.0.0.1])], [
        _VM_NET_IPV4([$5])
        _VM_NET_BIND([$2], [$3], [$5])
        _VM_NET_FORWARD_EMIT(m4_indir([_VM_NET_INDEX_$1]), [$2], [$3], [$4], [$5])
    ])
])

m4_dnl VM_NETWORK_USER(host_port, guest_port): legacy net0 TCP loopback wrapper.
m4_define([VM_NETWORK_USER], [
    _VM_READY
    _VM_ARITY([$#], [2], [VM_NETWORK_USER])
    m4_ifdef([_VM_NET], [_VM_FAIL([only one user network is supported])])
    VM_NET_USER([net0], [virtio-net-pci])
    VM_NET_FORWARD([net0], [tcp], [$1], [$2], [127.0.0.1])
    m4_define([_VM_NET], [1])
])
