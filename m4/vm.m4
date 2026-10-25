m4_changequote([,])m4_dnl
m4_divert(-1)m4_dnl

m4_dnl GNU m4 library (-P): keep definitions in discard diversion -1.
m4_dnl Device macros emit Bash statements into diversion 1.
m4_dnl Keep emitted Shell left-aligned; m4_dnl suppresses the switch newline.
m4_dnl VM_OUTPUT includes the template, which inserts diversion 1 verbatim.
m4_dnl Values are trusted m4 input; brackets quote arguments, not Shell.

m4_dnl Configuration files may write the bare word dnl as a comment start.
m4_define([dnl], [m4_dnl])

m4_dnl _VM_FAIL(message)
m4_dnl Print a diagnostic to stderr and abort the m4 run with status 1.
m4_define([_VM_FAIL], [
    m4_errprint([vmcreate: $1
])
    m4_m4exit(1)
])

m4_dnl _VM_ARITY(actual, expected, macro_name)
m4_dnl Reject calls whose argument count differs from the documented one.
m4_define([_VM_ARITY], [
    m4_ifelse([$1], [$2], [], [
        _VM_FAIL([$3: expected $2 arguments, got $1])
    ])
])

m4_dnl _VM_VALUE(value)
m4_dnl Reject empty values and characters that would break the generated
m4_dnl single-quoted Bash literal.
m4_define([_VM_VALUE], [
    m4_ifelse([$1], [], [_VM_FAIL([empty value])])
    m4_ifelse(m4_index([$1], [']), [-1], [], [_VM_FAIL([single quotes are not supported in values])])
    m4_ifelse(m4_index([$1], [
]), [-1], [], [_VM_FAIL([newlines are not supported in values])])
])

m4_dnl _VM_PATH(value)
m4_dnl A path is a value that additionally cannot contain a comma (QEMU uses
m4_dnl commas as option separators).
m4_define([_VM_PATH], [
    _VM_VALUE([$1])
    m4_ifelse(m4_index([$1], [,]), [-1], [], [_VM_FAIL([commas are not supported in paths])])
])

m4_dnl _VM_NUMBER(value)
m4_dnl Accept only positive decimal integers.
m4_define([_VM_NUMBER], [
    m4_ifelse(m4_regexp([$1], [^[1-9][0-9]*$]), [0], [], [
        _VM_FAIL([expected a positive integer: $1])
    ])
])

m4_dnl _VM_READY
m4_dnl Shared precondition: VM_INIT must already have run and VM_OUTPUT must
m4_dnl not have been seen yet (it terminates the configuration).
m4_define([_VM_READY], [
    m4_ifdef([_VM_STARTED], [], [_VM_FAIL([call VM_INIT first])])
    m4_ifdef([_VM_FINISHED], [_VM_FAIL([VM_OUTPUT must be last])])
])

m4_dnl _VM_ONCE(macro_name)
m4_dnl Reject a second call of a macro that maps to a single device.
m4_define([_VM_ONCE], [
    m4_ifdef([_VM_SEEN_$1], [_VM_FAIL([duplicate $1])])
    m4_define([_VM_SEEN_$1], [1])
])

m4_dnl VM_INIT(vm_name)
m4_dnl Start a configuration.  Emits the shared bootstrap settings; VM_MEMORY
m4_dnl and VM_CPU override their placeholder values later.
m4_define([VM_INIT], [
    _VM_ARITY([$#], [1], [VM_INIT])
    m4_ifdef([_VM_STARTED], [_VM_FAIL([duplicate VM_INIT])])
    _VM_VALUE([$1])
    m4_define([_VM_STARTED], [1])
    m4_divert(1)m4_dnl
vm_name='[$1]'
memory_mib=16384
cpu_topology=4
machine_spec=
qemu_bin=
accel=kvm
cpu_model=host
cpu_flags=
monitor_mode=stdio
serial_mode=none
serial_path=
net_backends=()
virtiofs_args=()
args=(
    -name "$vm_name"
    -rtc base=localtime,clock=host
)
m4_divert(-1)
])

m4_dnl VM_MEMORY(mebibytes)
m4_dnl Last call wins; boot.sh.in appends -m after the attributes are known.
m4_define([VM_MEMORY], [
    _VM_READY
    _VM_ARITY([$#], [1], [VM_MEMORY])
    _VM_NUMBER([$1])
    m4_divert(1)m4_dnl
memory_mib='[$1]'
m4_divert(-1)
])

m4_dnl VM_CPU(sockets, cores_per_socket, threads_per_core)
m4_dnl Last call wins.  QEMU's -smp accepts the total followed by the topology.
m4_define([VM_CPU], [
    _VM_READY
    _VM_ARITY([$#], [3], [VM_CPU])
    _VM_NUMBER([$1])
    _VM_NUMBER([$2])
    _VM_NUMBER([$3])
    m4_divert(1)m4_dnl
cpu_topology='m4_eval($1 * $2 * $3),sockets=$1,cores=$2,threads=$3'
m4_divert(-1)
])
m4_divert(-1)
])

m4_dnl VM_OUTPUT: no whitespace may precede the template shebang.
m4_dnl Widen quotes only while reading Bash, preserving its array brackets.
m4_dnl Restore square quotes explicitly for subsequent validation and m4wrap.
m4_define([VM_OUTPUT], [
    _VM_READY
    _VM_ARITY([$#], [0], [VM_OUTPUT])
    _VM_HARDWARE_CHECK
    _VM_CONTROL_CHECK
    m4_define([_VM_FINISHED], [1])
    m4_divert(0)m4_dnl
m4_changequote([<<<], [>>>])m4_dnl
m4_include(<<<boot.sh.in>>>)m4_dnl
m4_changequote(<<<[>>>, <<<]>>>)m4_dnl
m4_divert(-1)
])

m4_dnl EOF validation also rejects configurations that never emitted a script.
m4_m4wrap([
    m4_ifdef([_VM_FINISHED], [], [_VM_FAIL([missing VM_OUTPUT])])
])

m4_dnl Extensions are loaded before the user configuration, sharing validators.
m4_include([hardware.m4])
m4_include([network.m4])
m4_include([control.m4])
