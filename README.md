# Reasonix PortaKit · 便携工具箱

> **带走你的 Reasonix。** 把整个 Reasonix 文件夹拷进 U 盘或同步盘，插哪台电脑都能直接用——记忆、对话、Skill、MCP，全部跟着你走。

[English](#english) · [简体中文](#chinese)

---

<a name="chinese"></a>
## 🇨🇳 简体中文

### 你遇到过吗？

辛辛苦苦调教好的 Reasonix——配了一堆 Skill、挂了 MCP 服务器、攒了几十轮对话、沉淀了项目记忆——换个电脑就**全没了**。哪怕你把整个文件夹原封不动复制过去，打开依然是空白。

不是数据丢了，是 Reasonix 有几个"硬伤"：

| 问题 | 根因 |
|---|---|
| 记忆消失 | 项目记忆按**工作区路径**哈希命名；路径变了→哈希变了→找不到了 |
| 对话历史空白 | 会话元数据里存了**旧路径**；路径不匹配→侧边栏全空 |
| Skill / MCP 失效 | `config.json` 里 MCP 路径**硬编码了旧盘符**（`E:\Reasonix`） |
| 所有数据读不到 | Reasonix 默认从 `C:\Users\...` 取数据，不会主动读当前目录 |

**本质都是路径问题。** PortaKit 在每次启动时自动修好这一切。

### 做了什么

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

#### 第一步：确认 Reasonix 已就绪

确保你已经**至少启动过一次 Reasonix**，并且 **API Key 已配置好**。PortaKit 不帮你配 Key，它只负责让你的配置能跟着你走。

#### 第二步：放入文件

把这几个文件复制到 Reasonix 目录（和 `reasonix-desktop.exe` 放一起）：

```
Your-Reasonix/
  reasonix-desktop.exe     ← 原有的
  .reasonix/               ← 原有的配置/技能/会话
  node.exe                 ← PortaKit 带
  启动Reasonix.bat         ← PortaKit 带（从今以后双击这个）
  _patch_config.ps1        ← PortaKit 带
  _fix_sessions.js         ← PortaKit 带
  autorun.inf              ← PortaKit 带（可选，放 U 盘根目录）
```

#### 第三步：用 bat 启动

**双击 `启动Reasonix.bat`。** 首次启动会自动完成融合，之后每次启动也都是秒开。

> ⚠️ **必须用 bat 启动。** 直接双击 `reasonix-desktop.exe` 不会触发路径修正和数据融合——你会看到一片空白，就像全新安装一样。

> 🚫 **不要手动调整工作目录。** PortaKit 将工作区锁定为当前路径，在 Reasonix 内部切换工作目录会导致记忆和对话历史全部消失。即使强行切换，下次 bat 启动也会改回来。

#### 第四步：导入核心规则（推荐）

首次启动成功后，把 `PortaKit-核心规则.md` 的内容告诉 Reasonix（直接拖入或粘贴），让它记住便携版的运作机制。之后安装依赖、软件时，Reasonix 会自动从便携目录内的 `installers\` 走，不会去联网下载或往 C 盘装东西。

#### 第五步：自由迁移

经历过一次 bat 启动后，**整个 Reasonix 文件夹**就变成了完全便携的——

- **拷到 U 盘** → 插任何 Windows 电脑 → 双击 `启动Reasonix.bat` → 一切照旧
- **放进同步盘**（百度同步盘 / OneDrive / 坚果云）→ 新电脑同步下来 → 双击 bat → 连本机旧数据也自动融合进来
- **覆盖到已有 Reasonix 的旧电脑** → 双击 bat → 两边数据智能合并，不丢不重

不用重配 API Key，不用重装 Skill，不用重连 MCP。**一次配置，终生随行。**

---

<a name="english"></a>
## 🇬🇧 English

### The Problem

You've tuned Reasonix to perfection — skills installed, MCP servers running, dozens of conversations, project memories built up. Then you move to a new computer and **everything is gone**. Even if you copy the entire folder over, it still opens blank.

It's not lost. It's locked behind four hardcoded assumptions:

| Symptom | Root Cause |
|---|---|
| Memories vanish | Project memory directory hashed by **workspace path**; path changes → hash mismatch |
| Conversation history empty | Session metadata stores the **old workspace path**; mismatch → all filtered out |
| Skills / MCP broken | `config.json` hardcodes MCP paths with the **old drive letter** (`E:\Reasonix`) |
| Nothing reads from here | Reasonix defaults to `C:\Users\...`, never looks at your current directory |

**All path problems. PortaKit fixes them automatically on every launch.**

### What It Does

```
Double-click 启动Reasonix.bat
  │
  ├─ 1. Detect current path (works on any drive, any folder)
  ├─ 2. Redirect Reasonix to read data from here (not C:\Users\...)
  ├─ 3. SHA1(path) → project hash → create dirs; auto-rename/merge old hash dirs
  ├─ 4. Merge local machine's Reasonix data into this folder (newer-only, no overwrites)
  ├─ 5. Patch config.json — old paths → current path
  ├─ 6. Repair all session metadata (strip BOM + fix JSON escaping + align workspace)
  └─ 7. Launch Reasonix
```

### How to Use

#### Step 1: Make sure Reasonix is ready

You must have **launched Reasonix at least once** and **configured your API Key**. PortaKit doesn't set up your key — it makes your setup portable.

#### Step 2: Drop the files in

Copy these files into your Reasonix directory (next to `reasonix-desktop.exe`):

```
Your-Reasonix/
  reasonix-desktop.exe     ← yours
  .reasonix/               ← your config/skills/sessions
  node.exe                 ← from PortaKit
  启动Reasonix.bat         ← from PortaKit (use this from now on)
  _patch_config.ps1        ← from PortaKit
  _fix_sessions.js         ← from PortaKit
  autorun.inf              ← from PortaKit (optional, goes on USB root)
```

#### Step 3: Launch via bat

**Double-click `启动Reasonix.bat`.** The first launch merges everything; subsequent launches are instant.

> ⚠️ **Always use the bat file.** Launching `reasonix-desktop.exe` directly skips all path fixing and data merging — you'll see a blank slate, as if Reasonix was freshly installed.

> 🚫 **Do not change the workspace directory.** PortaKit locks the workspace to the current path. Switching the workspace inside Reasonix will wipe your project memory and conversation history. Even if you force it, the next bat launch will revert it.

#### Step 4: Import core rules (recommended)

After the first successful launch, feed `PortaKit-核心规则.md` to Reasonix (drag in or paste). This teaches it about the portable setup — from then on, installing dependencies or tools will automatically use the portable `installers\` directory instead of downloading from the internet or installing to `C:\`.

#### Step 5: Take it anywhere

After one bat launch, the **entire Reasonix folder** becomes fully portable:

- **Copy to USB** → plug into any Windows machine → double-click bat → everything intact
- **Put in a sync folder** (Baidu Sync, OneDrive, Dropbox) → sync to new PC → double-click bat → local data auto-merged in
- **Overwrite an existing Reasonix install** → double-click bat → both datasets merged intelligently

No re-configuring API keys. No re-installing skills. No re-connecting MCP servers. **Set up once, take it everywhere.**

---

## Requirements

- Windows (PowerShell 5.1+)
- Node.js runtime (`node.exe` included, or system-installed)
- Reasonix desktop (0.x or 1.x)

## Files

| File | Size | What |
|---|---|---|
| `启动Reasonix.bat` | 0.6 KB | Entry point |
| `_patch_config.ps1` | 6 KB | Core engine |
| `_fix_sessions.js` | 2.7 KB | Session repair |
| `PortaKit-核心规则.md` | 2.4 KB | Core rules for Reasonix to remember the portable setup |
| `node.exe` | ~80 MB | Node.js runtime |
| `autorun.inf` | 0.1 KB | USB AutoRun (optional) |

## License

MIT
