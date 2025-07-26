#!/usr/bin/env dart

import 'dart:io';

import '../lib/src/assets/assets_generator.dart' as assets_generator;

void main(List<String> arguments) async {
  print('🚀 Flutter Chen Generator v1.0.0');
  print('═' * 50);

  if (arguments.isEmpty) {
    _printHelp();
    return;
  }

  final command = arguments.first;
  final subArgs = arguments.skip(1).toList();

  try {
    switch (command) {
      case 'assets':
        await assets_generator.main(subArgs);
        break;

      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        break;

      case 'version':
      case '--version':
      case '-v':
        print('Flutter Chen Generator v1.0.0');
        break;

      default:
        print('❌ 未知命令: $command');
        print('使用 flutter_chen_generator help 查看可用命令');
        _printUsage();
        exit(1);
    }
  } catch (e, stackTrace) {
    print('❌ 执行失败: $e');
    if (Platform.environment['DEBUG'] == 'true') {
      print('堆栈跟踪: $stackTrace');
    }
    exit(1);
  }
}

void _printHelp() {
  print('''
Flutter Chen Generator - 综合代码生成工具包

用法: flutter_chen_generator <command> [options]

可用命令:
  assets    生成Flutter资源文件索引
  iconfont  生成图标字体Dart文件
  
选项:
  -h, --help      显示帮助信息
  -v, --version   显示版本信息

示例:
  # 生成资源文件
  flutter_chen_generator assets --output lib/assets.dart
  
  # 生成图标字体
  flutter_chen_generator iconfont --input assets/fonts/icons.json
  
  # 查看具体命令帮助
  flutter_chen_generator assets --help
  flutter_chen_generator iconfont --help
  
  # 直接使用特定工具
  flutter_chen_assets --help
  flutter_chen_iconfont --help

更多信息: https://pub.dev/packages/flutter_chen_generator
''');
}

void _printUsage() {
  print('使用 flutter_chen_generator --help 查看可用命令');
}
