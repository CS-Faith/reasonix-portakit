#!/usr/bin/env python3
"""Create wiki pages for reasonix-portakit"""
import os

pages = {
    'Home.md': """# Reasonix PortaKit

让 Reasonix 变成真正的便携版——U盘/同步盘即插即用，记忆、对话、Skill、MCP 全继承。

## 快速导航

- 📊 [介绍PPT](介绍PPT)
- 🔧 [技术深潜](技术深潜)
- 📢 [推广物料](推广物料)
""",
    '介绍PPT.md': """# 介绍PPT

项目介绍幻灯片，7页，深色主题。PPT 文件在仓库 Releases 中下载。
""",
    '技术深潜.md': """# 技术深潜

核心原理：劫持 USERPROFILE 环境变量。
Reasonix 默认从 C:\\Users\\.reasonix\\ 读数据。PortaKit 在启动前劫持 USERPROFILE 指向当前目录。

四个技术问题：
1. 项目记忆哈希断裂 → 旧哈希目录自动重命名
2. 会话元数据 JSON 损坏 → Node.js 修复
3. config.json 硬编码路径 → 自动替换
4. 重启后连续性 → 每次启动重新计算
""",
    '推广物料.md': """# 推广物料

共7份物料：V2EX帖子、Product Hunt、掘金、知乎、Reddit、公众号、技术深潜。
""",
}

for filename, content in pages.items():
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Created: %s' % filename)

print('All pages created.')
