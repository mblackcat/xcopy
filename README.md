# ClipVault

macOS 菜单栏剪贴板管理工具。自动监控系统剪贴板，保存复制历史（文本、图片、富文本、文件/文件夹），通过全局快捷键或菜单栏图标快速访问并粘贴任意历史记录。

> GitHub 仓库：<https://github.com/mblackcat/xcopy>

## 功能特性

- **剪贴板历史** — 自动记录所有复制内容，支持文本、富文本、图片、文件和文件夹
- **全局快捷键** — 默认 `⌥V` 唤起历史面板，可自定义
- **快速粘贴** — 选中历史记录后自动粘贴到当前应用
- **来源追踪** — 显示每条记录的来源应用名称
- **菜单栏常驻** — 不占用 Dock 栏，仅在菜单栏显示图标
- **本地存储** — 数据保存在 `~/Library/Application Support/ClipVault/`，不上传云端
- **可配置** — 支持设置最大历史条数（10–500）、自定义快捷键

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- 需要辅助功能（Accessibility）权限以实现自动粘贴

## 安装

### 下载预编译版本

前往 [GitHub Releases](https://github.com/mblackcat/xcopy/releases) 下载最新版 zip，解压后将 `ClipVault.app` 拖入 `/Applications` 即可。

### 从源码构建

```bash
git clone https://github.com/mblackcat/xcopy.git
cd xcopy
./scripts/bundle.sh
open build/ClipVault.app
```

## 使用方法

1. 启动 ClipVault，菜单栏会出现剪贴板图标
2. 正常使用 `⌘C` 复制内容，ClipVault 自动记录
3. 按 `⌥V`（Option+V）打开历史面板
4. 点击任意记录即可粘贴到当前应用

> 首次使用时 macOS 会提示授予辅助功能权限：系统设置 → 隐私与安全性 → 辅助功能 → 启用 ClipVault。

## 构建与开发

```bash
swift build              # Debug 构建
swift run                # 直接运行
./scripts/bundle.sh      # Release 构建 → build/ClipVault.app
```

### 发布

使用 `release.sh` 一键打包，并可选择直接发布到 GitHub Releases：

```bash
./release.sh                        # 打包（使用当前版本号）
./release.sh -v 1.2                 # 指定版本号打包
./release.sh --upload               # 打包 + 发布到 GitHub Releases
./release.sh -v 1.2 --upload        # 指定版本号 + 发布
```

上传需要本机已安装并登录 GitHub CLI：

```bash
gh auth login
```

## 项目结构

```
Sources/ClipVault/
  main.swift                  # NSApplication 启动入口
  App/                        # AppDelegate、常量定义
  Models/                     # ClipboardItem 数据模型
  Services/                   # 剪贴板监控、存储、快捷键、粘贴、设置
  UI/                         # 菜单栏、历史面板、设置窗口
Resources/
  Info.plist                  # 应用配置
  AppIcon.icns                # 应用图标
scripts/bundle.sh             # Release 构建脚本
release.sh                    # 本地打包 / GitHub Release 发布脚本
```

## 技术栈

- **语言**: Swift 5.9
- **UI**: SwiftUI + AppKit（NSPanel、NSStatusItem）
- **构建**: Swift Package Manager
- **全局快捷键**: Carbon RegisterEventHotKey
- **剪贴板监控**: NSPasteboard changeCount 轮询（0.5s）
- **粘贴模拟**: CGEvent Cmd+V
- **存储**: JSON 索引 + 二进制文件

## 开发者

Joey <275980464@qq.com>

## 许可证

本项目采用 **PolyForm Noncommercial 1.0.0** 许可证。

你可以下载、使用、学习和修改本项目，但**不得将其用于商业用途**。详细条款请查看 [LICENSE](LICENSE)。
