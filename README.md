# Reasonix PortaKit

> 让 Reasonix 真正便携——0.5X 路径重定向，1.X NTFS Junction。U 盘/同步盘即插即用。

---

## 为什么有这个仓库

Reasonix 默认把数据存在 C 盘，换电脑之后记忆、对话、Skill、MCP 全部消失。PortaKit 在每次启动时自动把数据路径重定向到当前文件夹，实现真正的便携。

本仓库提供两个版本的 PortaKit，分别针对 0.5X 和 1.X：

| 版本 | 适用 | 原理 | 文件 |
|------|:---:|------|------|
| **PortaKit for 0.5X** | Reasonix 0.5X | `HOME` / `USERPROFILE` 重定向 | bat + ps1 + js |
| **PortaKit for 1.X** | Reasonix 1.X | NTFS Junction（`mklink /J`） | 仅一个 bat |

---

## PortaKit for 0.5X

### 解决了什么

0.5X 版 Reasonix 有四个路径硬伤，换电脑就全没了：

| 问题 | 根因 |
|------|------|
| 记忆消失 | 项目记忆按工作区路径哈希命名；路径变了 → 哈希变了 → 找不到 |
| 对话历史空白 | 会话元数据存了旧路径；路径不匹配 → 侧边栏全空 |
| Skill / MCP 失效 | config.json 里 MCP 路径硬编码了旧盘符（`E:\Reasonix`） |
| 数据读不到 | Reasonix 默认从 `C:\Users\...` 取数据，不读当前目录 |

### 做了什么

```
双击 启动Reasonix.bat
  │
  ├─ 1. 自动检测当前所在路径（不管在哪个盘、哪个文件夹）
  ├─ 2. 设置 HOME / USERPROFILE 指向当前目录
  ├─ 3. SHA1(路径) → 项目哈希 → 创建/合并记忆目录
  ├─ 4. 融合本机已有的 Reasonix 数据（只合并更新的，不覆盖）
  ├─ 5. 修补 config.json 里的旧路径 → 当前路径
  ├─ 6. 修复所有会话元数据（BOM 清理 + JSON 转义 + 路径对齐）
  └─ 7. 启动 Reasonix
```

### 使用方法

1. 将 `PortaKit for 0.5X/` 下的所有文件复制到 Reasonix 根目录（与 `reasonix-desktop.exe` 同级）
2. **双击 `启动Reasonix.bat`**（从此以后都用它启动）
3. 经历过一次 bat 启动后，整个文件夹即可拷贝到 U 盘/同步盘/新电脑

### 文件清单

| 文件 | 说明 |
|------|------|
| `启动Reasonix.bat` | 入口，双击启动 |
| `_patch_config.ps1` | 核心引擎：路径检测 + 配置修补 + 数据融合 |
| `_fix_sessions.js` | 会话修复：BOM 清理 + JSON 转义 + 路径对齐 |
| `PortaKit-核心规则.md` | 供 Reasonix 记忆的便携规则 |
| `autorun.inf` | U 盘 AutoRun（可选） |

---

## PortaKit for 1.X

### v1.7：一个 bat，一行 Junction，彻底便携

1.X 版 Reasonix 改用 `%APPDATA%\reasonix` 存储数据。当 APPDATA 不在系统盘时（如便携环境），Reasonix 无法正常显示会话。

PortaKit v1.7 的核心原理：**NTFS Junction**（目录符号链接），把 `%APPDATA%\reasonix` 重定向到便携目录下的 `portable-data\reasonix`。

```
便携目录/
├── portable-data/
│   └── reasonix/          ← 实际存储数据的地方
├── 启动Reasonix.bat       ← 创建 Junction 并启动
└── reasonix.exe
```

### 做了什么

```
双击 启动Reasonix.bat
  │
  ├─ 1. 检测便携目录路径
  ├─ 2. 创建 portable-data\reasonix（如不存在）
  ├─ 3. mklink /J "%APPDATA%\reasonix" → "portable-data\reasonix"
  │     （首次运行：先迁移原有数据，再创建 Junction）
  ├─ 4. 设置 HOME / USERPROFILE 指向当前目录
  └─ 5. 启动 Reasonix
```

### 使用方法

1. 将 `PortaKit for 1.X/启动Reasonix.bat` 复制到 Reasonix 根目录
2. **双击 `启动Reasonix.bat`**
3. 整个文件夹即可自由拷贝

### 与 0.5X 版本的区别

| | 0.5X | 1.X |
|------|------|------|
| 核心方法 | 修补 config.json + 重写会话元数据 | NTFS Junction（`mklink /J`） |
| 文件数量 | 6 个 | 1 个 bat |
| 数据位置 | Reasonix 根目录下 `.reasonix/` 等 | `portable-data/reasonix/` |
| 复杂度 | 高（需要处理路径哈希、会话修复） | 低（Windows 原生能力） |

---

## 0.5X → 1.X 升级迁移

如果你的 Reasonix 从 0.5X 升级到 1.X，可以使用 [Reasonix 迁移升级助手](https://github.com/CS-Faith/reasonix-migration-assistant) 把旧版对话记录、MCP 配置、记忆、Skill 完整迁移过来。

搭配流程：
1. 用 **PortaKit for 0.5X** 保持 0.5X 版便携可用
2. 安装 1.X 版 Reasonix，用 **PortaKit for 1.X** 实现便携
3. 用 [迁移升级助手](https://github.com/CS-Faith/reasonix-migration-assistant) 把 0.5X 数据迁移过来

---

## 依赖

- Windows PowerShell 5.1+
- 1.X 版本依赖 NTFS（不支持 exFAT/FAT32 U 盘）
- 无需管理员权限
- 无需网络连接

---

## 许可

MIT License

---

# Reasonix PortaKit (English)

> True portability for Reasonix — path redirection for 0.5X, NTFS Junction for 1.X. USB/sync disk plug-and-play.

## Why This Repo

Reasonix stores data on the C: drive by default. Switch computers and your memories, conversations, skills, and MCP config all vanish. PortaKit redirects data paths to the current folder on every launch.

Two versions for two generations:

| Version | Target | Method | Files |
|------|:---:|------|------|
| **PortaKit for 0.5X** | Reasonix 0.5X | `HOME` / `USERPROFILE` redirection | bat + ps1 + js |
| **PortaKit for 1.X** | Reasonix 1.X | NTFS Junction (`mklink /J`) | single bat |

---

## PortaKit for 0.5X

### The Problem

Reasonix 0.5X has four hardcoded path assumptions:

| Symptom | Root Cause |
|---------|-----------|
| Memories vanish | Memory dir hashed by workspace path; path changes → hash mismatch |
| History empty | Session metadata stores old path; mismatch → blank sidebar |
| Skills / MCP broken | config.json hardcodes paths with old drive letter |
| Nothing reads | Reasonix defaults to `C:\Users\...`, ignores current dir |

### What It Does

```
Launch 启动Reasonix.bat
  │
  ├─ 1. Detect current path (any drive, any folder)
  ├─ 2. Set HOME / USERPROFILE to current directory
  ├─ 3. SHA1(path) → project hash → create/merge memory dirs
  ├─ 4. Merge existing local Reasonix data (newer only, no overwrites)
  ├─ 5. Patch config.json old paths → current path
  ├─ 6. Repair all session metadata (BOM strip + JSON fix + path align)
  └─ 7. Launch Reasonix
```

### Usage

1. Copy all files from `PortaKit for 0.5X/` to your Reasonix root (next to `reasonix-desktop.exe`)
2. **Always launch via `启动Reasonix.bat`**
3. After one bat launch, copy the entire folder to USB/sync disk/new PC

---

## PortaKit for 1.X

### v1.7: One Bat, One Junction, Totally Portable

Reasonix 1.X stores data at `%APPDATA%\reasonix`. When APPDATA is not on the system drive (portable setup), Reasonix won't show sessions.

PortaKit v1.7 solves this with **NTFS Junction** — a directory symlink that redirects `%APPDATA%\reasonix` to `portable-data\reasonix` inside your portable folder.

```
Portable folder/
├── portable-data/
│   └── reasonix/          ← actual data location
├── 启动Reasonix.bat       ← creates Junction and launches
└── reasonix.exe
```

### What It Does

```
Launch 启动Reasonix.bat
  │
  ├─ 1. Detect portable folder path
  ├─ 2. Create portable-data\reasonix if needed
  ├─ 3. mklink /J "%APPDATA%\reasonix" → "portable-data\reasonix"
  │     (first run: migrate existing data, then create Junction)
  ├─ 4. Set HOME / USERPROFILE to current directory
  └─ 5. Launch Reasonix
```

### Usage

1. Copy `PortaKit for 1.X/启动Reasonix.bat` to your Reasonix root
2. **Double-click `启动Reasonix.bat`**
3. The entire folder is now portable

### 0.5X vs 1.X Comparison

| | 0.5X | 1.X |
|------|------|------|
| Method | Patch config.json + rewrite session metadata | NTFS Junction (`mklink /J`) |
| File count | 6 | 1 bat |
| Data location | `.reasonix/` in Reasonix root | `portable-data/reasonix/` |
| Complexity | High (path hashes, session repair) | Low (native Windows) |

---

## Migration: 0.5X → 1.X

Upgrading from 0.5X to 1.X? Use the [Reasonix Migration Assistant](https://github.com/CS-Faith/reasonix-migration-assistant) to migrate legacy conversations, MCP config, memories, and skills.

Workflow:
1. Keep 0.5X portable with **PortaKit for 0.5X**
2. Install 1.X and make it portable with **PortaKit for 1.X**
3. Migrate 0.5X data with the [Migration Assistant](https://github.com/CS-Faith/reasonix-migration-assistant)

---

## Requirements

- Windows PowerShell 5.1+
- 1.X version requires NTFS (not compatible with exFAT/FAT32 USB drives)
- No admin privileges required
- No network connection required

---

## License

MIT License
