---
name: llm-wiki-pipeline
description: LLM WIKI 知识工厂 — 端到端知识库构建流水线：查重清理 → 获取与转换 → LLM理解融合 → Obsidian最佳范式输出 → 持续维护。整合 knowledge-cleanup + everything-markdown + defuddle + karpathy-llm-wiki + obsidian-*
---
# LLM WIKI Pipeline — 知识工厂

端到端知识库构建流水线。核心理念来自 Karpathy LLM WIKI：**LLM 负责编写和维护知识库，人类负责阅读和提问。**

```
杂乱原始材料（任意格式）
  │
  ├─ Phase 1: 查重清理 ──── 五轮递进：MD5→版本链→归一化→压缩包→目录重组
  ├─ Phase 2: 获取与转换 ── 本地文件(markitdown) + 网页(defuddle) → 统一 MD
  ├─ Phase 3: 理解融合 ──── LLM 阅读 MD → 理解 → 融合多源 → 结构化文章
  ├─ Phase 4: Obsidian 化 ── Frontmatter + Wikilinks + Callouts + Base + Canvas
  └─ Phase 5: 持续维护 ──── Query(查询) + Lint(质量检查) + 增量更新
```

---

## 配置

首次使用前和用户确认三个核心路径，其余按需：

| 配置项 | 说明 | 必须 |
|--------|------|------|
| `RAW_DIR` | 原始材料根目录（只读，永不修改） | ✅ |
| `WIKI_DIR` | 知识库输出根目录（LLM 完全所有权） | ✅ |
| `VAULT_DIR` | Obsidian Vault 路径（Phase 4 使用） | 按需 |

**规则**：所有路径使用绝对路径。敏感信息（Wiki 账号、API Key）从环境变量读取，禁止硬编码。

---

## Phase 1: 查重清理

> 完整方法论见 `knowledge-cleanup` Skill。

**原则**：多轮递进，逐轮确认。操作在副本中进行，源目录只读。先移后备（移入 `_backup/`），不直接删除。

### R1: MD5 完全重复

字节级相同的文件。排除工具生成的资源文件（`jquery*`、`*.woff2`、`*.dll` 等）。每组只保留一份。

### R2: 文件名版本链

按基名（去掉版本号/日期/修饰词后的文件名）分组，每组保留最新/最大的一个。识别模式：

1. 显式版本号：`V1.0` / `v2` / `_v3`
2. 日期后缀：`9.23` / `20230724`
3. 版本修饰词：`最终版` / `修正版` / `定稿版` / `最新版`
4. 副本标记：`副本` / `(1)` / `备份`
5. 方括号修饰：`【最新版】` / `【改后】`

### R3: 激进归一化

将文件名映射到"基名"后分组。核心正则思路：

```
去掉括号内容 → 去掉版本标签(V1.0, v2.3...) → 去掉日期 → 去掉修饰词(新/备份/副本/最终版...) → trim
```

大小相同的组跳过（R1 已处理）。

### R4: 压缩包清理

已解压的压缩包（同目录存在同名文件夹）→ 删除；软件安装包/工具类 → 移出知识库目录。

### R5: 目录结构重组

| 分类 | 判据 |
|------|------|
| **项目类** | 服务于特定交付物的完整工作集 |
| **管理类** | 跨项目的重复性产物（周报/考核/资质/竞品分析） |
| **其他** | 无法归入以上两类的零散文件 |

### 每轮输出

生成 `清理报告_R{N}_{名称}.md`，列出明细，等待用户确认后再进入下一轮。五轮完成后生成 `综合清理报告.md`。

---

## Phase 2: 获取与转换

> 本地文件用 `everything-markdown` Skill；网页用 `defuddle` Skill。

所有材料统一转为 Markdown，作为 Phase 3 的输入。

### 2A. 本地文件 → MD（markitdown）

**安装**：`pip install "markitdown[pdf,docx,xlsx,pptx]>=0.1.5"`

**支持格式**：

| 类别 | 格式 | 备注 |
|------|------|------|
| 文档 | PDF, DOCX, DOC, RTF, EPUB | 完全离线 |
| 表格 | XLSX, XLS, CSV | 完全离线 |
| 演示 | PPTX, PPT | 完全离线 |
| 网页/数据 | HTML, XML, JSON | 完全离线 |
| 图片 | JPG, PNG, GIF, BMP, TIFF, WEBP | 需 AI Vision API |
| 音频 | MP3, WAV, M4A, OGG, FLAC | 需 Whisper API |
| 压缩包/思维导图 | ZIP, XMind | XMind 本质是 ZIP，原生支持 |

**使用**：

```bash
# 单文件
markitdown file.pdf > file.md

# 批量转换（遍历目录中所有非 .md 文件，按扩展名调用 markitdown）
# 可通过脚本循环实现，或使用 everything-markdown 附带的批量转换脚本
```

**规则**：
- 大文件（>50MB）先预览，确认有内容再写
- 转换件 frontmatter 标注 `extracted: YYYY-MM-DD`
- 图片/音频无 API key 时跳过，标注"需手动描述"
- 输出到 `<RAW_DIR>/_converted/`

### 2B. 网页 → MD（defuddle）

```bash
# 安装
npm install -g defuddle

# 抓取清洗
defuddle parse <URL> --md -o <RAW_DIR>/<主题>/YYYY-MM-DD-标题.md

# 提取元数据
defuddle parse <URL> -p title
```

defuddle 自动去除导航/广告/侧栏，输出干净 Markdown，比裸 curl 省 token。

> ⚠️ **转换 ≠ 完成**。转换件是原始 dump，必须经过 Phase 3 理解融合才能成为知识文章。转换件最终归档到 `<WIKI_DIR>/<主题>/_原始提取/`。

---

## Phase 3: 理解融合（核心）

> 完整方法论见 `karpathy-llm-wiki` Skill。

### 架构

```
<RAW_DIR>/                          ← 不可变的原始材料
    ├── 主题A/
    └── 主题B/

<WIKI_DIR>/                         ← LLM 编译的知识库
    ├── index.md                    ← 全局索引（每行一篇文章：链接 + 摘要 + 更新日期）
    ├── log.md                      ← 追加式操作日志
    ├── 01-主题A/
    │   ├── 文章1.md               ← 融合后的结构化文章
    │   └── _原始提取/              ← 转换件归档
    └── 02-主题B/
```

### Ingest：原始材料 → 知识文章

**1. 阅读与归类**：阅读 Phase 2 产出的所有 MD 文件，识别主题。与现有文章核心论点相同则合并，新概念则创建新文章，跨主题则在多个目录添加交叉引用。

**2. 融合标准**：
- 一个主题一个目录
- 每主题 1~N 篇融合文章，覆盖概述、细节、版本演进等
- **融合密度 ≥ 70% 原始材料**：深入内容，不列文件清单
- 原始材料溯源：每篇文章标注 sources（来源描述）和 raw（原始文件路径）

**3. 文章格式**（这是 Phase 3 产出的中间格式，尚未 Obsidian 化）：

```markdown
---
topic: <主题名>
sources: <来源描述，分号分隔>
raw: <RAW_DIR>/<主题>/<文件名> （绝对路径，分号分隔）
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# 文章标题

## 概述
...

## 详细内容
...

## 相关文章
- [其他文章](../02-其他主题/文章.md)
```

**4. 级联更新**：处理完主要文章后，扫描同主题和其他主题中受影响的文章，更新相关内容并刷新 `updated` 日期。

### 融合后处理

1. 将含 `extracted:` 标记的转换件移入 `<WIKI_DIR>/<主题>/_原始提取/`
2. 更新 `<WIKI_DIR>/index.md`
3. 追加 `<WIKI_DIR>/log.md`：`## [YYYY-MM-DD] ingest | <主要文章标题>`

### 理解融合流程

```
任意格式文件 → Phase 2(markitdown/defuddle) → MD原始文本
                                                  ↓
                  Phase 3: 阅读MD → 理解内容 → 融合多源 → 结构化文章
                                                  ↓
                        保存为 wiki 文章 + 更新 index.md + log.md
```

> Phase 2 负责所有格式→MD 转换。Phase 3 只处理 MD 文本的理解融合，不碰二进制。

---

## Phase 4: Obsidian 最佳范式输出

> 完整语法参考 `obsidian-markdown`、`obsidian-bases`、`json-canvas`、`obsidian-cli` Skill。以下只列关键转换规则，详细用法加载对应 Skill。

Phase 3 的中间格式文章需要经过以下转换，才能在 Obsidian 中发挥最大效用。

### 4A. 基础转换（obsidian-markdown）

| 转换项 | Phase 3 中间格式 | Phase 4 Obsidian 格式 |
|--------|-----------------|----------------------|
| 内部链接 | `[文章](../主题/文章.md)` | `[[文章]]` |
| 章节链接 | `[章节](../主题/文章.md#标题)` | `[[文章#标题]]` |
| 图片引用 | `![alt](path/image.png)` | `![[image.png\|300]]` |
| 关键信息 | `> **警告**: 内容` | `> [!warning] 警告\n> 内容` |
| 高亮 | `**重要**` | `==重要==` |
| 标签 | 仅 frontmatter | frontmatter + `#inline/tag` |
| 注释 | `<!-- 注释 -->` | `%%注释%%` |

**Frontmatter 增强**（在 Phase 3 frontmatter 基础上添加）：

```yaml
---
title: 文章标题
date: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - 领域/子领域
aliases:
  - 别名
status: active
---
```

### 4B. 数据库视图（obsidian-bases）

创建 `<WIKI_DIR>/index.base`，提供多视图浏览。核心公式：

```yaml
formulas:
  days_since_update: '(now() - date(updated)).days'
  status_icon: 'if(status == "active", "🟢", if(status == "draft", "📝", "📦"))'
```

视图类型：`table`（表格）、`cards`（卡片）、`list`（列表）。按 `topic` 分组，按 `status` 筛选。

### 4C. 知识图谱（json-canvas）

创建 `<WIKI_DIR>/knowledge-graph.canvas`，节点用 `type: file` 指向 wiki 文章，边标注关系。遵循 JSON Canvas Spec 1.0。

### 4D. 批量操作（obsidian-cli）

需要 Obsidian 运行中：

```bash
obsidian create name="新笔记" content="..." vault="MyVault" silent
obsidian search query="关键词" vault="MyVault"
obsidian property:set name="status" value="active" file="笔记名"
```

### 4E. 检查清单

- [ ] 所有文章包含完整 frontmatter（title, date, tags, status）
- [ ] 内部引用全部替换为 `[[wikilinks]]`
- [ ] 关键信息使用 callouts（`> [!type]`）
- [ ] 图片使用 `![[embed]]` 嵌入
- [ ] 创建 `index.base` 提供多视图浏览
- [ ] 创建 `knowledge-graph.canvas` 展示知识结构
- [ ] Tags 层级化（`领域/子领域`）
- [ ] 数学公式用 LaTeX，流程图用 Mermaid

---

## Phase 5: 持续维护

> 完整方法论见 `karpathy-llm-wiki` Skill 的 Query 和 Lint 部分。

### Query（查询）

1. 读取 `<WIKI_DIR>/index.md` 定位相关文章
2. 读取文章，综合答案
3. 优先使用知识库内容而非训练知识
4. 在对话中输出答案。除非用户要求，否则不写文件。

### Lint（质量检查）

**自动修复**：索引一致性（index.md ↔ 实际文件）、内部链接有效性、Raw 引用路径、缺失的交叉引用。

**仅报告**：事实矛盾、过时声明、孤儿页、缺失跨主题引用、经常提及但无专用页面的概念。

### 增量更新

新材料到来时，回到 Phase 1（如果是全新一批）或直接从 Phase 2 开始（如果是少量文件），走完整流水线。已经 Obsidian 化的文章在 Phase 4 更新时保留已有格式。

---

## 完整流水线示例

```
用户："帮我把 <SOURCE_DIR> 整理成知识库"

Phase 1: 查重清理
  <SOURCE_DIR> → 副本 → 五轮清理 → <RAW_DIR>

Phase 2: 获取与转换
  扫描 <RAW_DIR> → markitdown 批量转换 → MD 文件 → 归档到 <RAW_DIR>/_converted/
  如有网页源 → defuddle 抓取 → 注入 <RAW_DIR>

Phase 3: LLM 理解融合
  阅读所有 MD → 识别主题 → 创建目录 → 融合撰写文章
  → 更新 index.md + log.md → 转换件移入 _原始提取/

Phase 4: Obsidian 化
  frontmatter 增强 → [[wikilinks]] 替换路径 → callouts 标注关键信息
  → 创建 index.base → 创建 knowledge-graph.canvas

Phase 5: 维护就绪
  知识库可查询、可 Lint、可增量更新

最终产出：
  <WIKI_DIR>/
    ├── index.md                   ← 全局索引
    ├── log.md                     ← 操作日志
    ├── index.base                 ← Obsidian 多视图
    ├── knowledge-graph.canvas     ← 知识图谱
    ├── 01-主题A/
    │   ├── 文章1.md              ← 融合文章（Obsidian 格式）
    │   ├── 文章2.md
    │   └── _原始提取/             ← 转换件归档
    └── 02-主题B/
        └── ...
```

---

## 工具速查

| 阶段 | 工具 | 用途 |
|------|------|------|
| Phase 1 | Python 脚本 | 五轮递进去重 |
| Phase 2 | `markitdown` | 本地文件→MD（15+ 格式） |
| Phase 2 | `defuddle` | 网页→干净 MD |
| Phase 3 | LLM（本 Agent） | 阅读、理解、融合、撰写 |
| Phase 4 | 直接写文件 | .md / .base / .canvas |
| Phase 4 | `obsidian` CLI | 批量操作（需 Obsidian 运行） |
| Phase 5 | LLM（本 Agent） | Query + Lint |

---

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| 跳过 Phase 1 直接转换 | 先查重去版本，避免融合时混淆新旧版本 |
| 转换件直接当 wiki 文章 | 必须经过 Phase 3 理解融合 |
| 融合文章只列文件名不写内容 | 融合密度 ≥ 70%，深入内容实质 |
| Phase 3 用 wikilinks 写文章 | Phase 3 用标准 Markdown 链接；Phase 4 再转 wikilinks |
| 用 Python 库逐个格式手动提取 | Phase 2 统一用 markitdown，内置所有解析器 |
| 在代码/Skill 中硬编码密码 | 从环境变量读取 |
| 一次性跑完全流程不等确认 | 每轮结束生成报告，等待用户确认 |
| 直接删除原始文件 | 移入 `_backup/`，确认后再清 |
| 图片/音频无 API key 时卡住 | 跳过，标注"需手动描述" |
