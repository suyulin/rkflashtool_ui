# RK Flash Tool UI

![Flutter](https://img.shields.io/badge/Flutter-macOS-blue.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)

一个基于 Flutter 开发的图形化固件烧录工具，支持瑞芯微（Rockchip）和全志（Allwinner）系列芯片的固件烧录。

*A Flutter-based GUI firmware flashing tool for Rockchip and Allwinner series chips.*

## 📋 目录 | Table of Contents

- [功能特性 | Features](#功能特性--features)
- [系统要求 | System Requirements](#系统要求--system-requirements)
- [安装说明 | Installation](#安装说明--installation)
- [使用方法 | Usage](#使用方法--usage)
- [开发指南 | Development](#开发指南--development)
- [故障排除 | Troubleshooting](#故障排除--troubleshooting)
- [贡献指南 | Contributing](#贡献指南--contributing)
- [许可证 | License](#许可证--license)

## 🚀 功能特性 | Features

### 支持的芯片系列 | Supported Chips
- **瑞芯微系列 | Rockchip Series**: RK3326, RK3566 等
- **全志系列 | Allwinner Series**: R818
- **处理器架构 | Architecture**: 支持 Apple Silicon (M系列) Mac

### 主要功能 | Main Features
- 🖥️ 直观的图形用户界面
- 📱 自动设备检测和切换
- ⚡ 快速固件烧录
- 🔄 设备模式切换（Loader 模式）
- 📊 实时烧录进度显示
- ⚠️ 智能错误处理和提示

## 💻 系统要求 | System Requirements

### 操作系统 | Operating System
- **macOS**: 10.14 或更高版本 (macOS 10.14 or later)
- **处理器**: Intel 或 Apple Silicon (M1/M2)

### 开发环境 | Development Environment
- **Flutter**: 3.0.0 或更高版本
- **Dart**: 3.0.0 或更高版本
- **Android SDK**: 用于 ADB 工具
- **Xcode**: 最新版本（macOS 开发）

### 硬件要求 | Hardware Requirements
- USB 数据线
- 支持的开发板或设备
- 稳定的电源供应（特别是 R818 设备）

## 📦 安装说明 | Installation

### 用户安装 | User Installation

1. **下载应用程序**
   ```bash
   # 从 Releases 页面下载最新版本的 rkflashtool.app
   ```

2. **首次运行**
   - 右键点击 `rkflashtool.app`
   - 选择"打开"
   - 在弹出的安全提示中点击"打开"
   - 允许来自未知开发者的应用程序运行

### 开发者安装 | Developer Installation

1. **克隆仓库**
   ```bash
   git clone https://github.com/suyulin/rkflashtool_ui.git
   cd rkflashtool_ui
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run -d macos
   ```

## 📱 使用方法 | Usage

### 前置条件 | Prerequisites

1. **确保设备连接**
   ```bash
   $ adb devices
   List of devices attached
   4ae29ab43ad0e7eb	device
   ```
   
   ⚠️ **重要**: 确保 Mac 只连接一个要烧录的设备

### 烧录步骤 | Flashing Steps

#### 1. 启动应用程序
- 双击 `rkflashtool.app` 启动应用
- 首次使用需要按照安装说明进行权限设置

#### 2. 选择固件文件
- 点击 **"固件"** 按钮
- 选择要烧录的固件文件
- 确认文件信息显示正确

<img src="https://github.com/suyulin/rkflashtool_ui/blob/main/assets/1.png" alt="固件选择界面" width="600"/>

#### 3. 切换设备模式
- 点击 **"切换"** 按钮
- 设备将自动切换到 Loader 模式
- 等待切换成功提示

<img width="851" alt="设备切换界面" src="https://github.com/suyulin/rkflashtool_ui/blob/main/assets/2.png">

#### 4. 开始烧录
- 点击 **"升级"** 按钮开始烧录
- 观察烧录进度
- 烧录成功后设备将自动重启

### ⚠️ 特殊注意事项

#### R818 设备烧录说明
- **必须**使用带底壳的供电方式
- 点击升级按钮后，需要重新插拔设备的 USB 连接
- 设备更新成功后会自动重启
- 如长时间未成功，请完全断电后重试

## 🛠️ 开发指南 | Development

### 项目结构 | Project Structure
```
rkflashtool_ui/
├── lib/
│   ├── main.dart           # 应用程序入口
│   ├── pages/              # 页面组件
│   │   ├── buttons_page.dart
│   │   └── logger.dart
│   ├── theme.dart          # 主题配置
│   └── cmd.dart           # 命令行工具
├── assets/                 # 资源文件
├── bin/                   # 二进制工具
└── pubspec.yaml           # 依赖配置
```

### 构建应用 | Building

```bash
# 开发模式运行
flutter run -d macos

# 构建发布版本
flutter build macos --release

# 生成应用包
flutter build macos --release --split-debug-info=debug_symbols
```

### 依赖管理 | Dependencies

主要依赖包：
- `macos_ui`: macOS 风格 UI 组件
- `provider`: 状态管理
- `file_picker`: 文件选择
- `flutter_easyloading`: 加载提示
- `path_provider`: 路径管理

## 🔧 故障排除 | Troubleshooting

### 常见问题 | Common Issues

**Q: 应用无法启动，提示安全限制**
- A: 请按照安装说明中的权限设置步骤操作

**Q: 设备无法被识别**
- A: 检查 USB 连接，确保 ADB 正常工作，运行 `adb devices` 确认

**Q: 烧录过程中断**
- A: 检查设备供电，确保 USB 连接稳定，重新尝试烧录

**Q: R818 设备烧录失败**
- A: 确保使用带底壳供电，烧录时重新插拔 USB 连接

### 日志调试 | Debug Logging

应用内置了详细的日志系统，可以帮助诊断问题：
- 查看应用控制台输出
- 检查设备连接状态
- 确认固件文件格式

## 🤝 贡献指南 | Contributing

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

### 代码规范 | Code Style
- 遵循 Dart/Flutter 官方代码规范
- 使用 `flutter analyze` 检查代码质量
- 确保所有测试通过

## 📄 许可证 | License

本项目基于 Apache License 2.0 许可证开源。详细信息请查看 [LICENSE](LICENSE) 文件。

## 📞 联系方式 | Contact

- **作者**: suyulin
- **项目主页**: [https://github.com/suyulin/rkflashtool_ui](https://github.com/suyulin/rkflashtool_ui)
- **问题反馈**: [Issues](https://github.com/suyulin/rkflashtool_ui/issues)

---

**免责声明**: 使用本工具烧录固件存在风险，请确保了解相关操作，作者不承担因使用本工具造成的设备损坏责任。

