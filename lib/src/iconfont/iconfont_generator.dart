import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Flutter 图标字体生成器
///
/// 自动从 iconfont.json 文件生成 Flutter 可用的图标字体 Dart 代码
/// 支持多种 JSON 格式，生成小驼峰命名的常量
class FlutterIconFontGenerator {
  // 默认配置项

  /// 输入的 JSON 文件路径
  static String inputFile = 'assets/fonts/iconfont.json';

  /// 输出的 Dart 文件路径
  static String outputFile = 'lib/generated/iconfont.dart';

  /// 生成的类名
  static String className = 'IconFont';

  /// 字体家族名称
  static String fontFamily = 'ComIcon';

  /// 是否生成扩展方法
  static bool generateExtensions = false;

  /// 开始生成图标字体文件
  ///
  /// 读取 JSON 配置文件，解析图标数据，生成对应的 Dart 代码
  static Future<void> generate() async {
    print('开始生成Flutter图标字体文件...');

    try {
      // 获取项目根目录
      final currentDir = Directory.current;
      print('📁 当前工作目录: ${currentDir.path}');

      // 检查是否在Flutter项目根目录
      final pubspecFile = File('pubspec.yaml');
      if (!await pubspecFile.exists()) {
        print('⚠️  警告: 当前目录不是Flutter项目根目录');
        print('💡 请在包含pubspec.yaml的目录下运行此命令');
      }
    } catch (e) {
      print('⚠️  无法获取当前工作目录: $e');
      print('💡 请确保在有效的项目目录中运行此命令');
    }

    try {
      // 构建完整路径
      final inputFilePath = path.join(Directory.current.path, inputFile);
      final outputFilePath = path.join(Directory.current.path, outputFile);

      // 检查输入文件是否存在
      final inputFileObj = File(inputFilePath);
      if (!await inputFileObj.exists()) {
        print('❌ 错误: 输入文件不存在 - $inputFilePath');
        print('💡 请确保 iconfont.json 文件存在于指定路径');
        return;
      }

      // 读取并解析JSON文件
      print('📖 读取图标字体配置文件...');
      final jsonData = await _parseIconFontJson(inputFileObj);

      if (jsonData.isEmpty) {
        print('⚠️  警告: 未找到任何图标数据');
        return;
      }

      // 生成Dart代码
      print('🔨 生成图标常量代码...');
      final dartCode = _generateDartCode(jsonData);

      // 确保输出目录存在
      final outputFileObj = File(outputFilePath);
      await outputFileObj.parent.create(recursive: true);

      // 写入文件
      await outputFileObj.writeAsString(dartCode);

      print('✅ 图标字体文件生成完成！');
      print('📁 生成文件: $outputFilePath');
      print('📊 共处理 ${jsonData.length} 个图标');

      // 显示使用示例
      _printUsageExample();
    } catch (e, stackTrace) {
      print('❌ 生成失败: $e');
      if (Platform.environment['DEBUG'] == 'true') {
        print('堆栈跟踪: $stackTrace');
      }
      rethrow;
    }
  }

  /// 解析图标字体JSON文件
  ///
  /// 支持多种 JSON 格式：
  /// - iconfont.cn 标准格式（包含 glyphs 字段）
  /// - 自定义格式（包含 icons 字段）
  /// - 直接数组格式
  ///
  /// [file] JSON 文件对象
  /// 返回解析后的图标数据列表
  static Future<List<IconData>> _parseIconFontJson(File file) async {
    try {
      final fileContent = await file.readAsString();
      final jsonMap = json.decode(fileContent);

      // 支持多种JSON格式
      List<dynamic> glyphsData;

      if (jsonMap.containsKey('glyphs')) {
        // iconfont.cn 格式
        glyphsData = jsonMap['glyphs'] as List<dynamic>;
      } else if (jsonMap.containsKey('icons')) {
        // 其他格式
        glyphsData = jsonMap['icons'] as List<dynamic>;
      } else if (jsonMap is List) {
        // 直接数组格式
        glyphsData = jsonMap;
      } else {
        throw FormatException('不支持的JSON格式，请检查文件结构');
      }

      final icons = <IconData>[];

      for (final item in glyphsData) {
        try {
          final iconData = _parseIconItem(item);
          if (iconData != null) {
            icons.add(iconData);
          }
        } catch (e) {
          print('⚠️  跳过无效图标数据: $e');
        }
      }

      return icons;
    } catch (e) {
      throw FormatException('JSON解析失败: $e');
    }
  }

  /// 解析单个图标项
  ///
  /// 从 JSON 对象中提取图标名称和 Unicode 码点
  ///
  /// [item] 单个图标的 JSON 数据
  /// 返回解析后的图标数据，解析失败时返回 null
  static IconData? _parseIconItem(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return null;
    }

    // 获取图标名称
    String? iconName = item['font_class'] ??
        item['name'] ??
        item['icon_name'] ??
        item['class'];

    if (iconName == null || iconName.isEmpty) {
      return null;
    }

    // 获取Unicode值
    dynamic unicodeValue = item['unicode_decimal'] ??
        item['unicode'] ??
        item['code'] ??
        item['codepoint'];

    int? codePoint;

    if (unicodeValue is int) {
      codePoint = unicodeValue;
    } else if (unicodeValue is String) {
      // 尝试解析十六进制或十进制字符串
      if (unicodeValue.startsWith('0x') || unicodeValue.startsWith('\\u')) {
        codePoint = int.tryParse(unicodeValue.replaceAll(RegExp(r'[\\ux]'), ''),
            radix: 16);
      } else {
        codePoint = int.tryParse(unicodeValue);
      }
    }

    if (codePoint == null) {
      return null;
    }

    return IconData(
      name: _toCamelCase(iconName),
      originalName: iconName,
      codePoint: codePoint,
    );
  }

  /// 生成Dart代码
  ///
  /// 根据图标数据生成包含常量定义的完整 Dart 文件内容
  ///
  /// [icons] 图标数据列表
  /// 返回生成的 Dart 代码字符串
  static String _generateDartCode(List<IconData> icons) {
    final buffer = StringBuffer();

    // 文件头注释
    buffer.writeln('/// 自动生成的图标字体文件，请勿手动修改');
    buffer.writeln('/// Generated by flutter_chen_iconfont_generator');
    buffer.writeln('/// Total icons: ${icons.length}');
    buffer.writeln();

    // 导入语句
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();

    // 主类定义
    buffer.writeln('/// $className 图标字体类');
    buffer.writeln('/// 字体家族: $fontFamily');
    buffer.writeln('class $className {');
    buffer.writeln('  ${className}._();');
    buffer.writeln();

    // 字体家族常量
    buffer.writeln("  /// 字体家族名称");
    buffer.writeln("  static const String fontFamily = '$fontFamily';");
    buffer.writeln();

    // 对图标进行排序
    icons.sort((a, b) => a.name.compareTo(b.name));

    // 按基础常量名分组（处理命名冲突）
    final nameGroups = <String, List<IconData>>{};

    // 第一遍：按基础常量名分组
    for (final icon in icons) {
      nameGroups.putIfAbsent(icon.name, () => []).add(icon);
    }

    // 第二遍：生成最终的常量名
    final finalConstants = <String, IconData>{}; // 最终常量名 -> 图标数据

    for (final entry in nameGroups.entries) {
      final baseName = entry.key;
      final iconList = entry.value;

      if (iconList.length == 1) {
        // 无冲突，使用基础名
        finalConstants[baseName] = iconList.first;
      } else {
        // 有冲突，第一个保持原名，其余添加索引后缀
        for (int i = 0; i < iconList.length; i++) {
          final icon = iconList[i];

          if (i == 0) {
            // 第一个图标保持原名
            finalConstants[baseName] = icon;
          } else {
            // 后续图标添加数字后缀
            final finalName = '${baseName}${i + 1}';
            finalConstants[finalName] = icon;
          }
        }
      }
    }

    // 按常量名排序并生成代码
    final sortedEntries = finalConstants.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 生成图标常量
    for (final entry in sortedEntries) {
      final constantName = entry.key;
      final icon = entry.value;
      final hexCode = '0x${icon.codePoint.toRadixString(16).padLeft(4, '0')}';

      buffer.writeln('  /// ${icon.originalName} 图标');
      buffer.writeln('  static const IconData $constantName = IconData(');
      buffer.writeln('    $hexCode,');
      buffer.writeln("    fontFamily: '$fontFamily',");
      buffer.writeln('  );');
      buffer.writeln();
    }

    // 生成扩展方法（可选）
    if (generateExtensions) {
      buffer.writeln('  /// 所有图标列表');
      buffer.writeln('  static const List<IconData> allIcons = [');
      for (final entry in sortedEntries) {
        buffer.writeln('    ${entry.key},');
      }
      buffer.writeln('  ];');
      buffer.writeln();

      buffer.writeln('  /// 根据名称获取图标');
      buffer.writeln('  static IconData? getByName(String name) {');
      buffer.writeln('    switch (name) {');
      for (final entry in sortedEntries) {
        buffer.writeln(
            "      case '${entry.value.originalName}': return ${entry.key};");
      }
      buffer.writeln('      default: return null;');
      buffer.writeln('    }');
      buffer.writeln('  }');
    }

    buffer.writeln('}');

    // 生成扩展类（可选）
    if (generateExtensions) {
      buffer.writeln();
      buffer.writeln('/// IconData 扩展方法');
      buffer.writeln('extension ${className}Extension on IconData {');
      buffer.writeln('  /// 创建 Icon 组件');
      buffer.writeln('  Icon icon({');
      buffer.writeln('    double? size,');
      buffer.writeln('    Color? color,');
      buffer.writeln('    String? semanticLabel,');
      buffer.writeln('    TextDirection? textDirection,');
      buffer.writeln('  }) {');
      buffer.writeln('    return Icon(');
      buffer.writeln('      this,');
      buffer.writeln('      size: size,');
      buffer.writeln('      color: color,');
      buffer.writeln('      semanticLabel: semanticLabel,');
      buffer.writeln('      textDirection: textDirection,');
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  /// 将字符串转换为小驼峰命名（camelCase）
  ///
  /// 处理各种分隔符和命名格式，生成符合 Dart 规范的变量名
  ///
  /// [input] 原始字符串
  /// 返回转换后的小驼峰命名字符串
  static String _toCamelCase(String input) {
    if (input.isEmpty) return 'icon';

    // 处理特殊字符，只保留字母、数字和连字符/下划线
    String cleaned = input.replaceAll(RegExp(r'[^\w\-]'), '_');

    // 按分隔符分割字符串
    final parts = cleaned.split(RegExp(r'[-_]+'));

    if (parts.isEmpty) return 'icon';

    final result = StringBuffer();
    bool isFirstPart = true;

    for (final part in parts) {
      if (part.isEmpty) continue;

      // 进一步处理每个部分，按驼峰边界分割
      final subParts = _splitByCamelCase(part);

      for (final subPart in subParts) {
        if (subPart.isEmpty) continue;

        final cleanPart = subPart.toLowerCase();
        if (isFirstPart) {
          // 第一个部分保持全小写
          result.write(cleanPart);
          isFirstPart = false;
        } else {
          // 后续部分首字母大写
          if (cleanPart.isNotEmpty) {
            result.write(cleanPart[0].toUpperCase());
            if (cleanPart.length > 1) {
              result.write(cleanPart.substring(1));
            }
          }
        }
      }
    }

    String finalResult = result.toString();

    // 确保不为空
    if (finalResult.isEmpty) {
      finalResult = 'icon';
    }

    // 确保不以数字开头
    if (RegExp(r'^\d').hasMatch(finalResult)) {
      finalResult = 'icon$finalResult';
    }

    // 确保是有效的Dart标识符
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(finalResult)) {
      finalResult = 'icon${DateTime.now().millisecondsSinceEpoch}';
    }

    return finalResult;
  }

  /// 按驼峰命名边界分割字符串
  ///
  /// 将 camelCase 或 PascalCase 字符串按大小写边界分割
  /// 例如：'AttentionLine' -> ['Attention', 'Line']
  ///
  /// [input] 待分割的字符串
  /// 返回分割后的字符串列表
  static List<String> _splitByCamelCase(String input) {
    if (input.isEmpty) return [];

    final parts = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      // 检查是否是大写字母
      if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
        // 当前字符是大写字母
        final prevChar = input[i - 1];
        final isPrevLower = prevChar.toLowerCase() == prevChar &&
            prevChar.toUpperCase() != prevChar;

        if (isPrevLower) {
          // 前一个字符是小写，当前是大写，这是一个分割点
          if (buffer.isNotEmpty) {
            parts.add(buffer.toString());
            buffer.clear();
          }
        }
      }

      buffer.write(char);
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts.isEmpty ? [input] : parts;
  }

  /// 打印使用示例
  ///
  /// 在控制台输出生成的代码使用方法和配置说明
  static void _printUsageExample() {
    print('''
📚 使用示例:

import 'package:flutter/material.dart';
import 'generated/iconfont.dart';

// 基本使用
Icon($className.iconName)

// 自定义样式
Icon(
  $className.iconName,
  size: 24,
  color: Colors.blue,
)

${generateExtensions ? '''
// 使用扩展方法
$className.iconName.icon(
  size: 24,
  color: Colors.red,
)

// 根据名称获取图标
final icon = $className.getByName('icon-name');
''' : ''}
💡 记得在 pubspec.yaml 中添加字体配置:

flutter:
  fonts:
    - family: $fontFamily
      fonts:
        - asset: assets/fonts/iconfont.ttf
''');
  }
}

/// 图标数据模型
///
/// 存储单个图标的相关信息，包括名称、原始名称和 Unicode 码点
class IconData {
  /// 小驼峰命名的图标名称
  final String name;

  /// 原始的图标名称
  final String originalName;

  /// Unicode 码点
  final int codePoint;

  /// 创建图标数据实例
  ///
  /// [name] 驼峰命名的图标名称
  /// [originalName] 原始图标名称
  /// [codePoint] Unicode 码点
  const IconData({
    required this.name,
    required this.originalName,
    required this.codePoint,
  });

  @override
  String toString() =>
      'IconData(name: $name, codePoint: 0x${codePoint.toRadixString(16)})';
}

/// 主函数 - 供外部调用
///
/// 解析命令行参数并执行图标字体生成任务
///
/// [arguments] 命令行参数列表
Future<void> main(List<String> arguments) async {
  print('🚀 Flutter Chen IconFont Generator');
  print('═' * 50);

  // 解析命令行参数
  if (_parseArguments(arguments)) {
    return;
  }

  try {
    await FlutterIconFontGenerator.generate();
    print('═' * 50);
    print('🎉 任务完成！');
  } catch (e, stackTrace) {
    print('❌ 生成失败: $e');
    print('堆栈跟踪: $stackTrace');
    exit(1);
  }
}

/// 解析命令行参数
///
/// 处理用户提供的命令行选项，设置相应的配置参数
///
/// [arguments] 命令行参数列表
/// 返回 true 表示应该退出程序（如显示帮助信息），false 表示继续执行
bool _parseArguments(List<String> arguments) {
  for (int i = 0; i < arguments.length; i++) {
    final arg = arguments[i];

    switch (arg) {
      case '--help':
      case '-h':
        _printHelp();
        return true;

      case '--input':
      case '-i':
        if (i + 1 < arguments.length) {
          FlutterIconFontGenerator.inputFile = arguments[++i];
        } else {
          print('❌ --input 需要指定输入文件路径');
          return true;
        }
        break;

      case '--output':
      case '-o':
        if (i + 1 < arguments.length) {
          FlutterIconFontGenerator.outputFile = arguments[++i];
        } else {
          print('❌ --output 需要指定输出文件路径');
          return true;
        }
        break;

      case '--class-name':
      case '-c':
        if (i + 1 < arguments.length) {
          FlutterIconFontGenerator.className = arguments[++i];
        } else {
          print('❌ --class-name 需要指定类名');
          return true;
        }
        break;

      case '--font-family':
      case '-f':
        if (i + 1 < arguments.length) {
          FlutterIconFontGenerator.fontFamily = arguments[++i];
        } else {
          print('❌ --font-family 需要指定字体家族名称');
          return true;
        }
        break;

      case '--extensions':
        FlutterIconFontGenerator.generateExtensions = true;
        break;

      case '--no-extensions':
        FlutterIconFontGenerator.generateExtensions = false;
        break;

      case '--version':
      case '-v':
        print('Flutter Chen IconFont Generator');
        return true;

      default:
        if (arg.startsWith('-')) {
          print('❌ 未知参数: $arg');
          print('使用 --help 查看可用参数');
          return true;
        }
    }
  }

  return false;
}

/// 打印帮助信息
///
/// 在控制台输出详细的使用说明和参数说明
void _printHelp() {
  print('''
Flutter Chen IconFont Generator - 自动生成图标字体Dart文件

用法: flutter_chen_iconfont [选项]

选项:
  -h, --help                    显示此帮助信息
  -v, --version                 显示版本信息
  
  -i, --input <file>            指定输入JSON文件 (默认: assets/fonts/iconfont.json)
  -o, --output <file>           指定输出Dart文件 (默认: lib/generated/iconfont.dart)
  -c, --class-name <n>       指定生成的类名 (默认: IconFont)
  -f, --font-family <n>      指定字体家族名称 (默认: ComIcon)
  
  --extensions                 生成扩展方法和工具函数
  --no-extensions              不生成扩展方法 [默认]

支持的JSON格式:
  1. iconfont.cn 标准格式 (包含 glyphs 字段)
  2. 自定义格式 (包含 icons 字段)  
  3. 直接数组格式

示例:
  # 使用默认配置
  flutter_chen_iconfont
  
  # 指定输入和输出文件
  flutter_chen_iconfont -i assets/icons.json -o lib/icons.dart
  
  # 自定义类名和字体家族
  flutter_chen_iconfont -c MyIcons -f MyFont
  
  # 生成扩展方法
  flutter_chen_iconfont --extensions

JSON文件示例:
{
  "glyphs": [
    {
      "font_class": "home",
      "unicode_decimal": 58880
    },
    {
      "font_class": "user-circle",
      "unicode_decimal": 58881
    }
  ]
}

更多信息: https://pub.dev/packages/flutter_chen_generator
''');
}
