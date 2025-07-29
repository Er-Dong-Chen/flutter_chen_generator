# Flutter Chen Generator

🚀 一个强大的Flutter代码生成工具包，包含多个实用的代码生成器。

## ✨ 功能特性

### 📁 [资源生成器 (Assets Generator)](doc/assets-generator.md)
- 🔄 自动扫描assets目录并生成Dart常量
- 🧠 智能驼峰命名转换，保持原有驼峰格式
- 🔧 处理文件命名冲突（同名不同扩展名）
- 📝 自动更新pubspec.yaml配置

### 🎨 [图标字体生成器 (IconFont Generator)](doc/iconfont-generator.md)
- 📄 解析iconfont.json文件自动生成Dart图标常量
- 🏷️ 智能命名转换（支持横线转驼峰）
- 🔧 支持多种JSON格式（iconfont.cn、自定义格式等）
- 🎯 类型安全的IconData常量

## 🚀 快速开始

### 安装

```bash
dart pub global activate flutter_chen_generator
```

### 基本使用

```bash
# 生成资源文件
flutter_chen_generator assets

# 生成图标字体
flutter_chen_generator iconfont

# 查看帮助
flutter_chen_generator --help
```

### 直接使用特定生成器

```bash
# 资源生成器
flutter_chen_assets --output lib/assets.dart

# 图标字体生成器  
flutter_chen_iconfont --input assets/fonts/icons.json
```

## 📖 详细文档

- 📁 [资源生成器使用指南](doc/assets-generator.md)
- 🎨 [图标字体生成器使用指南](doc/iconfont-generator.md)

## 🔮 未来计划

- 🌐 **国际化自动化脚本**: 自动把项目国际化、导入导出excel
- 📱 **ScreenUtil自动化脚本**: 自动智能添加ScreenUtil后缀

## 🛠️ 开发

```bash
# 克隆仓库
git clone https://github.com/Er-Dong-Chen/flutter_chen_generator.git

# 安装依赖
dart pub get

# 运行测试
dart test

# 本地运行
dart bin/flutter_chen_generator.dart --help
```

## 🤝 贡献

欢迎提交Issue和Pull Request！

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开Pull Request

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情

---

**⭐ 如果这个工具对你有帮助，请给个星标支持一下！**