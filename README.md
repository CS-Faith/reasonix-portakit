# Reasonix 便携工具箱

> 一套完整的 Reasonix 配置管理方案：0.5X 时代实现便携即插即用，1.X 时代实现无缝升级迁移。

---

## 能做什么

本仓库提供两个工具，覆盖 Reasonix 从 0.5X 到 1.X 的完整生命周期：

| 工具 | 适用版本 | 用途 |
|------|:---:|------|
| **PortaKit** | 0.5X | 让 Reasonix 变成真正的便携版——U盘/同步盘即插即用 |
| **迁移升级助手** | 0.5X → 1.X | 将旧版对话记录、MCP、记忆、Skill 完整迁移到新版 |

---

## 工具一：PortaKit（0.5X 便携版）

### 解决了什么问题？

辛辛苦苦调教好的 Reasonix——配了一堆 Skill、挂了 MCP 服务器、攒了几十轮对话、沉淀了项目记忆——换个电脑就全没了。哪怕把整个文件夹原封不动复制过去，打开依然是空白。

**不是数据丢了，是 Reasonix 有几个硬伤：**

| 问题 | 根因 |
|------|------|
| 记忆消失 | 项目记忆按工作区路径哈希命名；路径变了 → 哈希变了 → 找不到了 |
| 对话历史空白 | 会话元数据里存了旧路径；路径不匹配 → 侧边栏全空 |
| Skill / MCP 失效 | config.json 里 MCP 路径硬编码了旧盘符 |
| 所有数据读不到 | Reasonix 默认从 C:\Users\... 取数据，不会主动读当前目录 |

### PortaKit 做了什么

```
双击 启动Reasonix.bat
  │
  ├─ 1. 自动检测当前所在路径（不管在哪个盘、哪个文件夹）
  ├─ 2. 告诉 Reasonix：「你的数据就在这里，别去 C 盘找了」
  ├─ 3. SHA1(路径) → 项目哈希 → 创建目录；旧哈希目录自动重命名/合并
  ├─ 4. 把本机已有的 Reasonix 数据融合进来（只合并更新的，不覆盖）
  ├─ 5. 修补 config.json 里的旧路径 → 当前路径
  ├─ 6. 修复所有会话元数据（清理 BOM + 修正 JSON + 对齐路径）
  └─ 7. 启动 Reasonix
```

### 使用方法

1. 确保已安装 0.5X 版 Reasonix 并配置好 API Key
2. 将 PortaKit 文件放入 Reasonix 目录（与 `reasonix-desktop.exe` 同级）
3. **双击 `启动Reasonix.bat`**（之后都用这个启动）
4. 经历过一次 bat 启动后，整个文件夹即可自由拷贝到 U 盘、同步盘、新电脑

### 文件清单

| 文件 | 说明 |
|------|------|
| `启动Reasonix.bat` | 入口，双击启动 |
| `_patch_config.ps1` | 核心引擎：路径检测 + 配置修补 + 数据融合 |
| `_fix_sessions.js` | 会话修复：BOM 清理 + JSON 转义 + 路径对齐 |
| `node.exe` | Node.js 运行时（自包含） |
| `npx.cmd` | npm 包执行器 |
| `PortaKit-核心规则.md` | 供 Reasonix 记忆的便携版规则 |

---

## 工具二：迁移升级助手（0.5X → 1.X）

### 作用

将 Reasonix 从 0.5X 升级到 1.X 时，自动迁移以下数据：

| 数据类型 | 说明 |
|---------|------|
| MCP 配置 | JSON → TOML `[[plugins]]` 格式 |
| 对话记录 | 重命名 + 四件套（jsonl/meta/telemetry/ckpt） |
| 运行指标 | token 用量、缓存命中率、费用、依赖文件 |
| 记忆 | memory/ → projects/<slug>/memory/ |
| Skill | 新版原生支持 |

### 两种升级场景

**场景 [1]：标准安装版升级（C 盘）**
1. 双击 `0.53配置迁移到1.X.bat` → 选择 `[1]`
2. 启动新版 Reasonix，点击【历史对话】查看迁移的会话

**场景 [2]：PortaKit 便携版升级**
1. 将 bat 和 ps1 复制到便携版 Reasonix 根目录
2. 在便携版目录内双击 bat → 选择 `[2]`
3. 启动新版 Reasonix

### 文件清单

| 文件 | 说明 |
|------|------|
| `0.53配置迁移到1.X.bat` | 入口，双击运行 |
| `Migrate-053to1X.ps1` | 核心迁移脚本 |
| `技术实现.md` | 技术细节 |
| `研发纪实.md` | 踩坑记录 |

### 迁移效果

- ✅ 侧边栏不受影响
- ✅ 历史对话列表显示全部迁移会话
- ✅ 每条会话保留原始对话标题
- ✅ "打开会话"可继续未完成的对话
- ✅ 迁移前自动备份，可安全回滚
- ✅ 重复运行不会重复迁移已有文件（幂等）

---

## 依赖

- Windows PowerShell 5.1+
- 无需管理员权限
- 无需网络连接

---

## 许可

MIT License

---

# Reasonix PortaKit (English)

> A complete Reasonix configuration toolkit: portable plug-and-play for 0.5X, seamless migration to 1.X.

## What It Does

This repository provides two tools covering the full Reasonix lifecycle from 0.5X to 1.X:

| Tool | Version | Purpose |
|------|:---:|------|
| **PortaKit** | 0.5X | Make Reasonix truly portable — USB/sync disk plug-and-play |
| **Migration Assistant** | 0.5X → 1.X | Migrate legacy conversations, MCP, memories, and skills to the latest version |

---

## Tool 1: PortaKit (0.5X Portable)

### The Problem

You've tuned Reasonix to perfection — skills installed, MCP servers running, dozens of conversations, project memories built up. Switch computers and **everything is gone**. Copy the entire folder over, still blank.

It's not lost. It's locked behind four hardcoded assumptions:

| Symptom | Root Cause |
|---------|-----------|
| Memories vanish | Project memory directory hashed by workspace path; path changes → hash mismatch |
| Conversation history empty | Session metadata stores old workspace path; mismatch → all filtered out |
| Skills / MCP broken | config.json hardcodes MCP paths with old drive letter |
| Nothing reads from here | Reasonix defaults to C:\Users\..., never looks at your current directory |

### What PortaKit Does

```
Launch StartReasonix.bat
  |
  +-- 1. Detect current path (works on any drive, any folder)
  +-- 2. Redirect Reasonix to read data from here (not C:\Users\...)
  +-- 3. SHA1(path) --> project hash --> auto-merge/rename old hash dirs
  +-- 4. Merge local machine's Reasonix data into this folder
  +-- 5. Patch config.json -- old paths --> current path
  +-- 6. Repair all session metadata (strip BOM + fix JSON + align workspace)
  +-- 7. Launch Reasonix
```

### How to Use

1. Ensure Reasonix 0.5X is installed with API Key configured
2. Copy PortaKit files to the Reasonix directory (same folder as `reasonix-desktop.exe`)
3. **Always launch via `StartReasonix.bat`**
4. After one bat launch, the entire folder becomes portable — copy to USB, sync disk, or new PC

---

## Tool 2: Migration Assistant (0.5X --> 1.X)

### Purpose

Automatically migrate the following data when upgrading Reasonix from 0.5X to 1.X:

| Data Type | Description |
|-----------|------------|
| MCP Config | JSON --> TOML `[[plugins]]` format |
| Conversations | Rename + four-file bundle (jsonl/meta/telemetry/ckpt) |
| Metrics | Token usage, cache hit rate, cost, dependency files |
| Memories | memory/ --> projects/<slug>/memory/ |
| Skills | Natively supported in 1.X |

### Two Scenarios

**Scenario [1]: Standard C-drive upgrade**
1. Launch `0.53to1X.bat` --> choose `[1]`
2. Launch Reasonix 1.X, check History panel

**Scenario [2]: PortaKit portable upgrade**
1. Copy bat + ps1 to the portable Reasonix root
2. Run bat from portable directory --> choose `[2]`
3. Launch Reasonix 1.X

### Result

- ✅ Sidebar unaffected
- ✅ Full session list in History panel
- ✅ Original conversation titles preserved
- ✅ Resume unfinished conversations
- ✅ Auto-backup before migration
- ✅ Idempotent — safe to run multiple times

---

## Requirements

- Windows PowerShell 5.1+
- No admin privileges required
- No network connection required

---

## License

MIT License
