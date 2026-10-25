# vmcreate

- `m4/vm.m4` 是宏定义的事实源；`boot.sh.in` 是独立启动脚本模板，其拼接顺序、运行时变量与扩展约定记录在 `TEMPLATE.md`。`generate-boot.sh` 使用 `m4 -P` 展开并做 Bash 语法检查，再原子写入结果。
- 配置采用 `VM_*([参数])` 和 `dnl`，无参宏使用裸宏名。不要引入完整 Autotools 依赖。
- 输入是受信任的可执行 m4；路径是字面量，相对于生成脚本目录。不要用 eval 解析参数。
- 用户要求使用 DejaGnu 测试：执行 `make check`；测试只验证正确生成，禁止启动真实虚拟机。`make examples` 生成两份示例到 `build/`。
- `testsuite/vmcreate.test/generate.exp` 真实调用 m4，并使用临时 QEMU 参数记录器；不运行 swtpm/virtiofsd。
- `testsuite/vmcreate.test/wizard.exp` 用临时 `gum` 替身驱动 `wizard.sh`（TUI 基于 gum），并用 `VM_DIR` 隔离输出；向导测试不要依赖真实终端。
- `wizard.sh` 是交互式 TUI 向导：逐项问答、预览后写 `vm.m4` 并调用生成器；默认输出目录为 `${VM_DIR:-$HOME/vm}/<名称>`，不覆盖已有文件。
- 不改动原 `../ubuntu/boot.sh`、`../windows/boot.sh`，不创建或覆盖客户机磁盘、固件变量或 TPM 数据。
- README 面向用户记录用法和边界。新增宏同时维护生成器的已知宏检查、README 和 DejaGnu 用例。
- 当前目录不属于 Git/Jujutsu 仓库。验证日期为 2026-10-23；变更无需自动初始化 VCS。

- m4 排版约束：第一行安装方括号引用，库内注释使用 `m4_dnl`；在包含 Bash 模板期间临时切换到 `<<< >>>`，之后恢复方括号供 EOF 校验使用。禁止把未定义的 `dnl` 放到初始化之前；模板数组引用和首行 shebang 由 DejaGnu 回归测试保护。

- 高级宏按职责分为 `m4/hardware.m4`、`network.m4`、`control.m4`，由 `vm.m4` 在配置之前加载；扩展测试位于 `extensions.exp`，实际argv使用QEMU替身，VirtIOFS替身用Python Unix socket检查就绪、只读和清理。独立接口事实文档为 `MACROS.md`，TUI保持基础项。
