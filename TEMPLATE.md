# 启动脚本模板（2026）

生成出来的 `boot.sh` 由三部分拼成：`boot.sh.in` 的静态骨架、`VM_INIT` 注入的头部变量、各设备宏注入的 `args+=` 片段。理解这三者的拼接顺序，就能安全地改造模板或新增宏。

## 组装顺序

`VM_OUTPUT` 先切到 diversion 0，再 `m4_include` 模板。因此模板里只有一处插入点：

```bash
# Insert validated device settings before resolving final memory/CPU values.
m4_undivert(1)
```

diversion 1 按声明顺序累积：`VM_INIT` 的变量块在最前，其后是各设备宏的片段；`_VM_HARDWARE_CHECK` 在 `VM_OUTPUT` 时最后追加解析结果。所以模板中这段之后的代码，看到的一定是最终值。

## 运行时变量

`VM_INIT` 建立，后续宏覆盖；模板只读取，不重新赋值。

| 变量 | 初始值 | 写入者 |
|---|---|---|
| `vm_name` | `VM_INIT` 参数 | `VM_INIT` |
| `memory_mib` | `16384` | `VM_MEMORY` |
| `cpu_topology` | `4` | `VM_CPU`（写完整 `-smp` 串） |
| `machine_spec` | 空 | `VM_MACHINE`；未指定时由架构检查填 `q35,smm=on` 或留空 |
| `qemu_bin` | 空 | `_VM_HARDWARE_CHECK`：`VM_QEMU` 优先，否则 `qemu-system-<arch>` |
| `accel` / `cpu_model` / `cpu_flags` | `kvm` / `host` / 空 | `VM_ACCEL`、`VM_CPU_MODEL`、`VM_CPU_FLAGS` |
| `monitor_mode` / `serial_mode` / `serial_path` | `stdio` / `none` / 空 | `VM_MONITOR`、`VM_SERIAL`、`VM_HEADLESS` |
| `net_backends` | 空数组 | `VM_NET_*` 追加 `-netdev` 串 |
| `virtiofs_args` | 空数组 | `VM_SHARE`（`ro` 时追加 `--readonly`） |
| `tpm_dir` / `share_dir` | 空 | `VM_TPM` / `VM_SHARE` |
| `args` | `-name`、`-rtc` | 各设备宏 `args+=` |
| `runtime_dir` | `mktemp -d` | 模板自身 |

模板另行定义 `vm_dir`、`pids`、`vm_path()`、`wait_socket()`、`cleanup()`。

## 执行阶段

1. **路径基准**：`vm_dir` 取脚本自身目录，之后所有相对资源都相对它解析，与调用者的 cwd 无关。
2. **早期校验**：脚本目录和 `TMPDIR` 含逗号时直接退出，因为 QEMU 用逗号分隔选项。
3. **临时目录**：`mktemp -d` 生成 `/tmp/vmcreate.<随机串>`，每次启动独立；`cleanup` 只删自己那个。
4. **收尾参数**：统一追加 `-m`、`-smp`、`-accel`、`-cpu`、`-monitor`，再按需补 `-machine`、`-netdev`、`-serial`。放在这里而不是各宏里，是因为 `VM_MEMORY`、`VM_CPU` 允许后声明覆盖先声明。
5. **后台服务**：启用 TPM 或共享时才启动 `swtpm`、`virtiofsd`，用 `wait_socket` 等待 socket 就绪，进程号进 `pids`。
6. **QEMU**：`"$qemu_bin" "${args[@]}" <&0 &` 保留 monitor stdin，`wait` 最后一个 pid。

信号（INT/TERM）与正常退出都走 `cleanup`：先 `kill` 再 `wait`，最后删 `runtime_dir`。

## 新增宏时要遵守的约定

- 片段写进 `m4_divert(1)`，首行用 `m4_dnl` 吞掉换行，避免空行进入生成结果。
- 路径一律经 `vm_path '...'` 包裹，保证相对路径相对脚本目录。
- 设备 id 使用 `vmcreate_` 前缀，由宏自动编号，避免重复。
- 先 `_VM_READY`，再 `_VM_ARITY` / `_VM_ONCE`，最后校验字段；非法值走 `_VM_FAIL`。
- 需要在 `VM_OUTPUT` 时才能判定的跨宏约束，写进 `_VM_HARDWARE_CHECK` 或同类检查宏。
- 值里不能出现单引号、换行；路径另外不能有逗号。

## 已知限制

- 同一实例并发启动两次会争用 `runtime_dir` 之外的同名 socket 与磁盘，模板没有实例锁。
- 模板不创建磁盘、不下载 ISO、不复制 VARS；这些必须预先存在。
- `cleanup` 依赖 `trap` 生效；被 `SIGKILL` 或整机断电时会留下 `/tmp/vmcreate.*`。
- `ide`、`ahci` 设备与 `q35`/`pc` 机器是 x86 约定；非 x86 架构只用 `virtio`。
