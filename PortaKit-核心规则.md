---
name: portakit-rules
description: PortaKit 便携版核心规则——路径机制、启动流程、自包含依赖、跨机迁移
type: project
scope: global
priority: high
---

# PortaKit 便携版核心规则

Reasonix 便携版（PortaKit）支持 U 盘、同步盘、本地硬盘任意位置运行。`启动Reasonix.bat` 通过 `%~dp0` 自动检测当前路径，设置 `HOME` / `USERPROFILE` 指向 Reasonix 根目录，所有数据合并到 `.reasonix/` 下。

## 一、启动必须用 bat

**每次启动必须双击 `启动Reasonix.bat`**，不要直接双击 `reasonix-desktop.exe`。

直接双击 exe 的后果：
- 路径检测和修补不触发 → `config.json` 中旧路径不更新
- 本机数据不融合 → 记忆、对话、会话全空
- `USERPROFILE` 指向 `C:\Users\...` → Reasonix 从 C 盘读取，而非当前目录

### 禁止调整工作目录

**在 Reasonix 内部不要手动切换工作区目录。** PortaKit 通过 bat 将工作区锁定为当前路径，用户自行调整工作目录会导致路径双轨分裂：

| 机制 | 用的路径 | 后果 |
|------|---------|------|
| PortaKit（bat + ps1） | `RX_ROOT`（bat 所在目录） | 哈希计算、记忆目录、config 修补都基于此 |
| Reasonix 内部 | 用户选的新目录 | 记忆和对话历史的哈希不匹配 → 项目记忆清空、侧边栏空白 |

即使强行切换了，下次 bat 启动时 `_patch_config.ps1` 也会把工作目录改回来——修改白费，还可能造成新创建的会话元数据混乱。**PortaKit 用户的工作目录就是 bat 所在目录，不应更改。**

## 二、启动自动执行的动作

1. 自动检测当前路径（`%~dp0`），无需手动改任何配置
2. SHA1(路径) → 项目哈希 → 创建 `memory/<hash>/` 和 `conversations/<hash>/` 目录
3. 检测是否有旧哈希目录 → **自动重命名为当前哈希**（只有一个旧目录时）或**合并后删除**（多个旧目录时），确保旧项目记忆和对话历史无缝继承
4. 融合本机数据（robocopy `/XO` 只复制更新的，不覆盖已有新数据）
5. 修补 `config.json` 中硬编码的旧路径 → 当前路径
6. 修复会话元数据（清理 BOM + 修正 JSON 转义 + 对齐 workspace 字段）

## 三、各项数据位置

| 数据类型 | 路径 |
|---------|------|
| MCP 配置 | `<workspace>\.reasonix\config.json` |
| Skill 文件 | `<workspace>\.reasonix\skills\` |
| 对话会话 | `<workspace>\.reasonix\sessions\` |
| 项目记忆 | `<workspace>\.reasonix\memory\<hash>\`（hash = SHA1 前 16 位） |
| 全局记忆 | `<workspace>\.reasonix\memory\global\` |

其中 `<workspace>` = Reasonix 根目录，即 `启动Reasonix.bat` 所在目录。

## 四、自包含依赖规则

Reasonix 便携目录为完整自包含环境。所有 MCP Server、Skill 需要的工具运行时和安装包都预置在该目录内。换到新电脑时**不从网上下载，从本地安装**。

### 安装包位置

所有安装包在 `<workspace>\installers\`：

| 工具 | 路径 |
|------|------|
| Python 3.12+ | `<workspace>\python\python.exe`（已解压可用） |
| Node.js | `<workspace>\node.exe`（已包含） |
| Git Portable | `<workspace>\installers\PortableGit-64-bit.7z.exe`（待下载） |

### 依赖映射表

| MCP / Skill | 需要的运行时 | 便携目录内位置 |
|-------------|------------|--------------|
| `image-analyzer` MCP | Python 3.12+ | `<workspace>\python\python.exe` |
| `od-test` MCP | Python 3.12+ | 同上 |
| 所有 npx MCP（7个） | Node.js | `<workspace>\node.exe` |
| `commit` / `debug` skill | Git | `<workspace>\installers\` 中获取 |
| `feishu` skill | lark-cli | `<workspace>\node_modules\@larksuite\cli` |

### 安装规则

- **执行前检测**：当命令因"找不到"而失败时，先检查便携目录内的对应工具
- **Lazy install**：用到时才装，不一到新电脑就全量安装
- **禁止行为**：不要引导去官网下载（先查 `installers\`），不要用 winget/choco/apt，不要在 `C:\` 安装任何东西

## 五、跨机迁移

经历过一次 bat 启动后，整个 Reasonix 文件夹即可：
- 拷到 U 盘 → 插任何 Windows 电脑 → 双击 bat → 一切照旧
- 放进同步盘 → 新电脑同步 → 双击 bat → 本机旧数据自动融合
- 覆盖到已有 Reasonix 的旧电脑 → 双击 bat → 两边数据智能合并

无需重配 API Key，无需重装 Skill，无需重连 MCP。

## 六、路径哈希说明

项目记忆目录名 = SHA1(工作区绝对路径, UTF-8) 的前 16 位十六进制字符。路径变化 → 哈希变化 → 需要重新匹配记忆目录。`_patch_config.ps1` 在每次启动时自动计算正确哈希并确保目录存在。
