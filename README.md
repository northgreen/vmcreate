# vmcreate

用一份可读的配置文件描述虚拟机，生成一个独立、可重复运行的 QEMU 启动脚本。

```bash
bash ./vmc-wizard
```

向导会问你机器名、内存、CPU、硬盘和安装光盘，然后写出 `${VM_DIR:-$HOME/vm}/<名字>/vm.m4` 和 `boot.sh`。想立刻看看结果：

```bash
cd ~/vm/my-vm
./boot.sh --dry-run      # 只打印 QEMU 命令，不启动
./boot.sh                # 真正启动
```

生成的 `boot.sh` 是纯 Bash，不依赖这个项目，可以直接拷贝到别的机器上用。

## 快速开始

需要一个可用的 QEMU，以及 Bash 和 GNU m4。

```bash
make install prefix=$HOME/.local    # 或者直接在本目录用
export PATH=$HOME/.local/bin:$PATH

vmc-wizard                          # 交互生成配置与脚本
vmc-generate-boot vm.m4 boot.sh     # 或者从现成的 .m4 生成
```

此项目会为你生成一份启动qemu的脚本，剩下的全部交给你

## 运行时的临时覆盖

配置写死的值可以按次覆盖，不必改文件：

```bash
./boot.sh --help                     # 全部选项
./boot.sh --dry-run                  # 打印最终命令，调试首选
./boot.sh --snapshot                 # 本次改动不落盘
./boot.sh --boot cad                 # 临时改启动顺序
./boot.sh --cdrom live.iso           # 换掉配置里的所有光盘
./boot.sh --disk data.qcow2:qcow2:virtio:ro   # 追加一块只读盘
./boot.sh --qemu /path/to/qemu       # 换二进制
./boot.sh -- -no-reboot              # `--` 之后原样交给 QEMU
```

命令行给的值会替换配置里的同名项，不是叠加。`--keep-runtime` / `--print-runtime` 在排查后台服务（TPM、virtiofsd）起不来时有用：临时目录和 socket 会被保留并打印路径。

## 支持哪些设备

机器型号与加速器、启动顺序、多硬盘、软盘、多网卡与端口转发、TAP/桥接、只读与临时写入、串口与日志、VNC/SPICE/headless、目录共享、TPM、USB 与 PCI 直通、QMP、内核直启。

每个宏的参数、默认值、互斥关系和安全边界见 [MACROS.md](MACROS.md)，那是完整参考，不需要一次读完。想看生成脚本内部怎么拼接，见 [TEMPLATE.md](TEMPLATE.md)。

## 示例

`examples/` 下有四份可直接参考的配置：

| 文件 | 场景 |
|---|---|
| `ubuntu.m4` | UEFI + AHCI 盘 + SSH 转发到宿主 2223 |
| `windows.m4` | 与 ubuntu 同构，SSH 转发到宿主 2224 |
| `freedos.m4` | 老式 PC 机器、TCG 软件模拟、软盘启动 |
| `server.m4` | 无图形窗口、串口接到当前终端 |

```bash
make examples      # 输出到 build/{ubuntu,windows,freedos,server}/boot.sh
```

示例中有几处写死的绝对路径（如 `ubuntu.m4` 的 ISO、`windows.m4` 的共享目录），生成后需要按自己的实际情况修改。

## 安装布局

```text
$(prefix)/bin/vmc-generate-boot    生成器
$(prefix)/bin/vmc-wizard           交互式向导
$(prefix)/share/vmc/m4/*.m4        宏库
$(prefix)/share/vmc/boot.sh.in     启动模板
$(prefix)/share/vmc/examples/      示例配置
$(prefix)/share/vmc/*.md           文档
```

模板目录默认 `$(datadir)/vmc`，可用 `make install vmcreatedir=/opt/vmc` 改变。生成器找模板的顺序：`--share DIR` → 环境变量 `VMCREATE_SHARE` → 安装时写入的目录 → 生成器自身所在目录。

`make uninstall` 会移除安装的脚本和模板目录。

## 开发与测试

```bash
make check         # DejaGnu 测试：真实调用 m4，用参数记录器代替 QEMU
make examples
```

测试不会启动虚拟机，只验证 m4 展开、错误配置被拒绝、输出原子替换、Bash 语法和最终传给 QEMU 的参数。运行脚本本身也需要 `swtpm`、`virtiofsd` 或图形后端时，由测试替身模拟。测试记录在 `build/test-results/`。

向导测试用临时 `gum` 替身驱动，不需要真实终端。

## 许可证

本项目以 GNU General Public License v3.0（GPLv3）发布，全文见 [LICENSE](LICENSE)。

