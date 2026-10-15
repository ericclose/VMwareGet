<div align="center">

# VMwareGet

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/ericclose/VMwareGet?style=flat-square)](https://github.com/ericclose/VMwareGet/releases)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Android-blue?style=flat-square)](https://github.com/ericclose/VMwareGet/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/github/license/ericclose/VMwareGet?style=flat-square)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/ericclose/VMwareGet?style=flat-square)](https://github.com/ericclose/VMwareGet/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ericclose/VMwareGet?style=flat-square)](https://github.com/ericclose/VMwareGet/network/members)

`VMwareGet` 是 [Broadcom 支持门户](https://support.broadcom.com) 的第三方开源客户端，专为高效检索、高速下载及安全校验 **VMware Workstation Pro** 与 **VMware Fusion** 官方安装包而设计，支持 macOS、Windows 及 Android。

</div>

<p align="center">
<a href="#概述">概述</a> &nbsp;&bull;&nbsp;
<a href="#特性">特性</a> &nbsp;&bull;&nbsp;
<a href="#下载安装">下载安装</a> &nbsp;&bull;&nbsp;
<a href="#使用说明">使用说明</a> &nbsp;&bull;&nbsp;
<a href="#构建与开发">构建开发</a> &nbsp;&bull;&nbsp;
<a href="#免责声明">免责声明</a>
</p>

---

## 概述

在 Broadcom 调整 VMware 产品授权策略并开放个人免费使用后，用户在网页端常面临访问繁琐、历史版本查找困难、下载速度受限以及会话频繁过期等痛点。

**VMwareGet** 旨在提供现代化、轻量且纯净的原生桌面与移动客户端。客户端直连 Broadcom 官方 API 与官方 CDN，无需复杂配置，即可一键索引全版本官方发行包、多线程并发高速下载，并在下载完成后自动完成 SHA-256 / MD5 防篡改校验。

---

## 特性

- 🌐 **官方源直连**：直连 Broadcom 官方支持门户与官方 CDN 节点，不设中间服务，保证安装包 100% 官方原版。
- 📦 **全版本索引**：全面支持 **VMware Workstation Pro**（Windows/Linux）与 **VMware Fusion**（macOS Universal）各历史版本与最新版本的元数据查询。
- ⚡ **原生分片下载**：内置原生多线程 Range 分块传输引擎，支持 1 ~ 64 线程自定义并发连接、断点续传与直链提取。
- 🔐 **智能身份认证**：内置开箱即用的内嵌浏览器快捷登录（支持 AuthHub 单点登录桥接与动态 CSRF Token 嗅探），亦支持手动 cURL / Cookie 导入。
- 🛡️ **流式哈希校验**：安装包落盘后自动进行 SHA-256 与 MD5 真实哈希比对，杜绝网络损坏或镜像篡改。
- 📱 **多端原生适配**：针对 macOS（提供可直接拖拽至 Applications 的 DMG）、Windows 10/11 与 Android 手机界面进行了深度自适应布局优化。
- 🎨 **现代多语言 UI**：遵循 Material Design 3 规范，支持深色/浅色自适应模式，内置简体中文（信达雅）、English 与 Esperanto 多语言切换。

---

## 下载安装

从 [Releases](https://github.com/ericclose/VMwareGet/releases) 页面下载适合您平台的安装包：

### macOS
1. 下载适合您 Mac 芯片的安装包：`VMwareGet-macos-arm64.dmg`（Apple Silicon）或 `VMwareGet-macos-x64.dmg`（Intel）。
2. 双击打开 DMG，将 **VMwareGet** 拖拽至 **Applications**（应用程序）文件夹即可。

### Windows
1. 下载 `VMwareGet-windows-x64-setup.exe`。
2. 双击安装向导即可完成安装。

### Linux
1. **Debian / Ubuntu**：下载 `VMwareGet-linux-x64.deb` 或 `VMwareGet-linux-arm64.deb`，通过 `sudo dpkg -i VMwareGet-linux-*.deb` 安装。
2. **Fedora / RHEL**：下载 `VMwareGet-linux-x64.rpm` 或 `VMwareGet-linux-arm64.rpm`，通过 `sudo rpm -ivh VMwareGet-linux-*.rpm` 安装。

### Android
1. 下载 `VMwareGet-android-arm64-v8a.apk`（主流现代手机）或 `VMwareGet-android-x86_64.apk`（模拟器/x86 设备）。
2. 传输至 Android 设备或直接在手机浏览器中安装。

---

## 使用说明

1. **登录验证**：启动应用后，在认证页面点击“登录 Broadcom 账户”，在内嵌窗口中完成登录，应用将自动捕获会话与动态 Token。
2. **浏览目录**：在“软件目录”页面选择所需的产品线（Workstation Pro / Fusion），可按版本号、构建号或文件名即时筛选。
3. **高速下载**：点击对应版本卡片上的“下载”按钮，任务将加入“传输管理”，支持实时查看速率、进度、暂停/继续，或一键“复制直链”。
4. **验证与定位**：下载完成后，引擎会自动进行 SHA-256 完整性校验，确认无误后点击“打开文件”或“在访达/资源管理器中显示”即可开始安装。

---

## 构建与开发

### 环境要求

- [Flutter SDK](https://flutter.dev) `3.47.7`
- Dart SDK `3.7+`
- macOS (Xcode 15+) / Windows (Visual Studio 2022) / Android (JDK 17 + Android SDK)

### 获取代码与安装依赖

```bash
git clone https://github.com/ericclose/VMwareGet.git
cd VMwareGet
flutter pub get
```

### 运行与验证

```bash
# 启动本地调试
flutter run

# 运行全量单元测试与质量门禁 (39 项全通过)
./test.sh
```

### 本地构建 Release 包

```bash
# 自动检测当前宿主操作系统与当前架构进行本地打包
./build.sh
```

---

## 免责声明

- 本项目为个人开源学习与技术交流项目，与 Broadcom Inc. 或 VMware 无官方关联。
- 软件版权及商标归原权利人所有。本工具仅提供官方公开下载地址的索引与连接辅助，不提供任何破解、激活或未授权访问功能。
- 请自觉遵守 Broadcom 官方服务条款及相关软件许可协议（EULA）。
