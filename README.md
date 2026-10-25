# vmcreate

使用 GNU m4 把声明式虚拟机配置展开为独立的 QEMU Bash 启动脚本。采用类似 Autoconf 的 `VM_*([参数])` 语法、方括号引用和 `dnl` 注释，但不依赖 Autoconf/Automake，也不使用它们的 `AC_*` 宏。

## 生成与验证

生成需要 Bash、GNU m4，以及 GNU/Linux 常用工具。测试另外需要 GNU make、Python 3（Unix socket服务替身）和 DejaGnu（`runtest`、Expect、Tcl）。

```bash
cd /home/ictye/vm/vmcreate
make check
make examples
```

生成结果为 `build/{ubuntu,windows,freedos,server}/boot.sh`；测试记录位于 `build/test-results/vmcreate.sum`、`vmcreate.log`。测试真实调用 m4，并用参数记录器代替 QEMU 核验生成脚本的实参；不会启动虚拟机、TPM 或 VirtIOFS 服务。

生成到指定位置：

```bash
bash ./generate-boot.sh ./examples/windows.m4 ./build/my-windows/boot.sh
```

生成器只写启动脚本，不创建磁盘、不复制 UEFI 变量文件、不检查 ISO 是否存在，也不自动运行结果。成功生成时原子替换已有输出文件；展开或 Bash 语法检查失败时保留原文件。配置文件本身不允许作为输出。

## 向导

`wizard.sh` 在终端里逐项提问并生成 `vm.m4` 和 `boot.sh`，需要 [gum](https://github.com/charmbracelet/gum)：

```bash
bash ./wizard.sh
```

基础流程依次询问名称、内存、CPU 插槽/核/线程、系统盘文件名、磁盘格式、磁盘总线和是否使用 UEFI，随后打印配置并询问输出目录。其余设备（额外磁盘、软盘、ISO、快照与只读、多网卡与端口转发、TAP/桥接、显示/音频/VNC/SPICE/headless、串口/日志/QMP、TPM/共享/Guest Agent/USB/VFIO、内核直启、机器型号与加速器、启动顺序）都在最后的“高级配置”菜单里按需选择，可以反复进入，选 `Done` 结束；全部跳过则只生成基础配置。回车采用默认值，取消（Ctrl-C）以退出码 130 退出。确认后直接打印配置并写入 `VM_DIR`（默认 `$HOME/vm`）下的 `<名称>/` 目录；已有 `vm.m4` 或 `boot.sh` 时拒绝覆盖。写入配置后调用 `generate-boot.sh`，生成失败会删除刚写的配置。向导不会创建磁盘、下载 ISO 或启动客户机。

## 配置

```m4
VM_INIT([my-vm])
VM_MEMORY([4096])
VM_CPU([1], [4], [1])
VM_UEFI([/usr/share/OVMF/x64/OVMF_CODE.secboot.4m.fd], [my_vars.fd])
VM_DISK([hdd.img], [qcow2], [ahci])
VM_CDROM([install.iso])
VM_NETWORK_USER([2223], [22])
VM_DISPLAY([gtk], [virtio-gpu-pci])
VM_OUTPUT
```

`VM_INIT` 必须最先调用，`VM_OUTPUT` 必须最后调用。无参宏写作裸宏名，不添加 `()`。建议每行写一个宏调用。m4 配置是受信任的程序，不是可以安全接收外部输入的配置沙箱。

完整参数、默认值、设备冲突、安全限制见独立的 [宏参考 MACROS.md](MACROS.md)。
生成脚本的内部结构、运行时变量、插入点与扩展约定见 [模板说明 TEMPLATE.md](TEMPLATE.md)。

支持机器/CPU/加速器、启动顺序、多磁盘与软盘、多网卡及转发、只读与临时写入、串口日志、远程显示、共享、USB/VFIO、QMP和内核直启。高级功能直接编辑 `.m4`，TUI只保留基础流程。

所有相对资源路径均相对于**生成的 boot.sh 所在目录**，不是 `.m4` 所在目录或启动时的工作目录。不展开路径中的 `$HOME`、`~` 或命令替换；要使用主目录，请填完整绝对路径。值可以包含空格，但不支持单引号、换行；路径还不支持逗号（QEMU 选项分隔符）和 m4 引用定界符 `[`、`]`。

## 启动边界

实际启动需要 QEMU（KVM 或显式选择 TCG）、可用固件、预先存在的磁盘与配置中声明的 ISO。按需还需要 `swtpm`、`virtiofsd`、显示和音频后端。默认 VirtIOFS 程序为 `/usr/lib/virtiofsd`，可用环境变量 `VIRTIOFSD` 指定本机路径。

启动脚本为 socket 创建独立临时目录，只启动配置启用的后台服务，等待 socket 就绪，退出时清理本次启动的进程和临时目录。启用 TPM 时会创建缺失的状态目录，并由 swtpm 持久化 TPM 状态。磁盘、VARS 和 TPM 状态不可由多个实例同时写入。

两份示例参考原启动脚本，但不是逐项兼容迁移：去除了空光盘路径、共用 socket 和未使用服务；Windows SSH 宿主端口使用 2224，Ubuntu 使用 2223；CPU 明确为 1 插槽 × 4 核 × 1 线程。没有复制原 Windows 的 ivshmem 和 Hyper-V CPU flags，显示后端也未默认启用 GL。

示例输出放在 `build/` 下，因此不能直接使用原目录的相对磁盘和 VARS；需要先编辑配置使用实际路径，或将生成脚本放在对应资源目录中。现有 `../ubuntu/boot.sh` 和 `../windows/boot.sh` 保持不动。

验证范围（2026-10-24）：m4 展开、错误配置、输出原子性、Bash 语法、参数传递和可重复生成。未验证客户机开机、固件兼容性及 TPM/VirtIOFS 的真实运行。
