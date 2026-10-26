# VM 宏参考（2026）

配置是受信任的 GNU m4 程序，不是安全沙箱。运行 `bash vmc-generate-boot machine.m4 output/boot.sh` 生成独立 Bash 脚本；不会创建磁盘、下载镜像、绑定驱动或启动客户机。

## 语法和路径

```m4
dnl 注释。所有参数用方括号引用，无参数宏不写 ()。
VM_INIT([example])
VM_MEMORY([4096])
VM_CPU([1], [4], [1])
VM_DISK([system.qcow2], [qcow2], [virtio])
VM_OUTPUT
```

`VM_INIT` 最先、`VM_OUTPUT` 最后。机器、加速器、CPU型号/特性、启动顺序、内核、日志、QMP、显示和共享等单例宏最多声明一次；内存、CPU拓扑、monitor以后一次为准。所有相对资源路径相对于生成的 `boot.sh` 目录，不相对于配置或当前工作目录。路径里的 `$HOME`、`~`、命令替换均是字面量。值不支持单引号、换行、m4 引用定界符；QEMU 子选项中的路径还不能含逗号。不要将配置用于接收不可信输入。

下面 `[,参数]` 表示可选参数，不是要输入的 m4 文本。显式写空参数只在特别说明的地方有效。

## 基础硬件与启动

| 宏 | 说明 |
|---|---|
| `VM_INIT([名称])` | 基础设置：16384 MiB、4 vCPU、q35、KVM、host CPU、stdio monitor；不自动添加磁盘、网卡或固件 |
| `VM_MEMORY([MiB])` | 正整数；后一次覆盖前一次 |
| `VM_CPU([插槽], [核/插槽], [线程/核])` | 正整数，vCPU 总数为乘积；后一次覆盖前一次 |
| `VM_ARCH([架构])` | 模拟架构，默认 `x86_64`；决定默认命令 `qemu-system-<架构>`。非 x86 架构不传 `-machine`，交给 QEMU 默认值，且不能再写 `VM_MACHINE` |
| `VM_QEMU([命令])` | QEMU 可执行文件名或绝对路径，默认空表示按架构推导。只接受单个词，带参数请写包装脚本 |
| `VM_MACHINE([规格])` | PC/q35 系列机器型号及受支持的属性；加速器由独立宏管理 |
| `VM_ACCEL([kvm或tcg])` | 选择硬件加速或软件模拟；TCG 不能配 host CPU，需要 `VM_CPU_MODEL` |
| `VM_CPU_MODEL([型号])` | 例如 `host`、`max`、`qemu32`；可用性取决于本机 QEMU |
| `VM_CPU_FLAGS([特性列表])` | 逗号分隔，例如 `+aes,hv_relaxed=on`；与型号合成一个 `-cpu` 参数 |
| `VM_BOOT([顺序][,一次性顺序[,菜单]])` | 顺序使用不重复的 `a` 软盘、`c` 硬盘、`d` 光盘、`n` 网络；菜单 `on/off`；一次性顺序可空 |
| `VM_UEFI([CODE], [VARS])` | 一次；只读 raw 固件代码及可写 raw 变量文件。省略则使用机器默认 BIOS |
| `VM_KERNEL([内核][,initrd[,命令行]])` | 直接内核启动；后两个可空，命令行作为单个字面 argv，不执行 Shell |

例如，换一个架构并用自带的 QEMU：

```m4
VM_INIT([arm64])
VM_ARCH([aarch64])
VM_ACCEL([tcg])
VM_CPU_MODEL([cortex-a72])
VM_QEMU([/opt/qemu/bin/qemu-system-aarch64])
```

非 x86 架构不生成 `-machine`；需要指定机器时用 QEMU 自带默认值，或在生成后手工补参数。

例如，软件模拟旧 x86 系统：

```m4
VM_MACHINE([pc])
VM_ACCEL([tcg])
VM_CPU_MODEL([qemu32])
VM_BOOT([cad], [a], [on])
```

这里只声明参数，不能保证所选 CPU、机器、客户机和设备组合兼容。用 `qemu-system-x86_64 -machine help`、`-cpu help` 查看本机型号。

## 存储与临时写入

| 宏 | 说明 |
|---|---|
| `VM_DISK([文件], [raw或qcow2], [ide或ahci或virtio][,模式])` | 可重复；模式默认 `rw`，可选 `ro`、`snapshot`、`rw-discard`、`snapshot-discard`。`ro` 与 `*discard` 都要求 virtio：IDE/AHCI 不宣告 unmap，强行设置会被拒绝 |
| `VM_CDROM([ISO])` | 可重复，raw 只读光盘；与 IDE 硬盘共享索引，避免冲突 |
| `VM_FLOPPY([镜像][,单元[,模式]])` | raw 软盘，单元 0/1 不可重复；省略时为0；模式 rw/ro/snapshot |
| `VM_SNAPSHOT` | QEMU 全局临时磁盘写入模式；退出丢弃临时层，不是保存/恢复快照的管理器 |

AHCI 后端和控制器使用自动生成 ID，每控制器六个端口。传统 IDE 使用机器内置控制器，pc 最多四个槽，q35 最多六个；混合 CD 和 IDE 硬盘占用同一计数。

**临时写入不等于隔离环境：**不保证 VARS、TPM 状态、VirtIOFS 共享、日志和外设不发生持久修改。`ro` 与 `snapshot` 语义不同：前者拒绝写入，后者允许向临时层写入。`rw-discard` 让客机删除的簇回传给 qcow2（`discard=unmap`），宿主才会真正释放空间；`snapshot-discard` 是临时写入加丢弃回传，适合测试但退出即丢弃。

## 网络

| 宏 | 说明 |
|---|---|
| `VM_NETWORK_USER([宿主端口], [客户机端口])` | 旧接口：net0、VirtIO 网卡、回环 TCP 转发；最多一次 |
| `VM_NET_USER([ID], [型号][,MAC])` | 新建 user 网络，可重复；接受任意 QEMU 网卡设备型号名 |
| `VM_NET_FORWARD([ID], [tcp或udp], [宿主端口], [客户机端口][,宿主IPv4])` | 添加到已声明的 user 网络；默认127.0.0.1；端口1–65535；拒绝重复占用 |
| `VM_NET_TAP([ID], [接口], [型号][,MAC])` | 使用已有 TAP，`script=no,downscript=no`；不创建接口、不提权 |
| `VM_NET_BRIDGE([ID], [桥], [型号][,MAC])` | 由 QEMU bridge helper 接入已有桥；权限和 allowlist 由宿主管理 |

三种后端的型号参数均直接传给 QEMU `-device`，不维护型号白名单，例如 `e1000e`、`igb`、`vmxnet3`、`pcnet`、`virtio-net-pci-transitional`。型号名只允许字母、数字、下划线、点、加号、连字符，且不能以点、加号或连字符开头；不能混入逗号或设备属性。用目标 QEMU 的 `-device help` 查看设备名，或用 `-nic model=help` 查看当前配置的网卡列表（不要使用仅限 `-nic` 的别名，如 `virtio`）。生成器不要求安装 QEMU；型号是否存在、是否为网卡，以及总线和机器是否兼容，由实际运行的 QEMU 检查。向导的 `NIC model → Custom` 可输入这些设备名。

ID 唯一，`vmcreate_` 前缀保留给内部设备。转发必须在对应 user 网络声明之后；不能给 TAP/bridge 添加 user 转发。多网卡的路由由客户机设置。

```m4
VM_NET_USER([management], [e1000])
VM_NET_FORWARD([management], [tcp], [2225], [22])
VM_NET_FORWARD([management], [tcp], [8080], [80])
VM_NET_FORWARD([management], [udp], [5353], [53])
```

将监听地址改成 `0.0.0.0` 会对外开放端口；默认不这样做。MAC 需要有效六段十六进制格式，并由使用者保证局域网唯一。

## 显示、控制台与日志

| 宏 | 说明 |
|---|---|
| `VM_DISPLAY([gtk或none], [virtio-gpu-pci或VGA])` | 一次；显卡和共享 USB 平板控制器 |
| `VM_AUDIO([pa或pipewire])` | 一次；Intel HDA 音频输出 |
| `VM_MONITOR([stdio或none])` | 默认 stdio；后一次生效 |
| `VM_SERIAL([none或stdio])` | 一个串口；stdio 时必须禁用 monitor |
| `VM_SERIAL([file], [路径])` | 客户机串口输出到文件，不等于 QEMU debug 日志 |
| `VM_HEADLESS` | 无图形窗口、monitor none、serial stdio；不能与其他显示声明或串口声明混用 |
| `VM_VNC([显示编号])` | 仅127.0.0.1；实际 TCP 端口为5900+编号 |
| `VM_SPICE([端口])` | 仅127.0.0.1，明确禁用 ticket 验证；通过 SSH 隧道远程使用 |
| `VM_LOG([文件], [类别列表])` | QEMU `-D/-d`，例如 guest_errors,unimp；类别由本机 QEMU 解释 |
| `VM_QMP([socket路径])` | Unix QMP listener，server=on,wait=off；父目录需存在 |

一个 stdio 只能由 monitor 或串口之一占用。VNC、SPICE 互斥，不能与 gtk/headless 混用；可以用 `VM_DISPLAY([none], [VGA])` 配置远程显示显卡。不设置本地图形显示并不会自动让客户机输出串口，Linux 仍需配置 `console=ttyS0` 等。

VNC/SPICE 不默认提供远程鉴权或加密；回环限制不阻止其他本机用户连接。QMP 可控制虚拟机，需保护 socket 所在目录权限。这里只创建控制入口，不提供热插拔、关机等 QMP 客户端。

## 共享与直通

| 宏 | 说明 |
|---|---|
| `VM_SHARE([目录], [标签][,rw或ro])` | 一次，默认rw；ro通过virtiofsd `--readonly` 强制实施。共享内存使用最终内存值 |
| `VM_TPM([状态目录])` | 一次，swtpm TPM2.0；启动时创建缺失状态目录，内容持久化 |
| `VM_GUEST_AGENT` | 一次，virtio串口；客户机需运行代理 |
| `VM_USB_HOST([宿主总线], [宿主地址])` | 可重复，复用显示设备的USB控制器；拒绝重复设备 |
| `VM_VFIO([域:总线:槽.功能])` | 可重复，规范小写BDF如0000:01:00.0；拒绝重复 |

USB 总线/地址可能在重新插拔后变化；需自行配置访问权限。VFIO 需要宿主 IOMMU、设备隔离组和驱动绑定；生成器不会执行这些高风险操作。直通与只读磁盘/临时写入互不替代。

VirtIOFS 需要本机 virtiofsd（默认 `/usr/lib/virtiofsd`，环境变量 `VIRTIOFSD` 可覆盖）及客户机驱动。共享rw目录允许客户机修改宿主文件，优先共享专用目录或ro目录。

## 验证边界

示例：`examples/freedos.m4` 展示 PC/TCG/IDE/软盘，`examples/server.m4` 展示多盘、多转发、只读共享及内核直启。

使用 DejaGnu `make check` 验证真实 m4 展开、错误拒绝、Shell 参数与服务替身；`make examples` 生成示例。验证不包含客户机开机、固件兼容性、真实网桥权限或VFIO设备访问。TUI保持基础创建流程，高级参数编辑 `.m4` 使用。
