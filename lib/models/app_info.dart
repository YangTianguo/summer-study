import 'dart:convert';

/// 已安装应用信息
class AppInfo {
  final String packageName;
  final String appName;
  final String iconBase64; // PNG图标的Base64编码

  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64 = '',
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['packageName'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      iconBase64: json['iconBase64'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'iconBase64': iconBase64,
      };

  /// 从JSON数组字符串解析
  static List<AppInfo> fromJsonList(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => AppInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 解析包名JSON数组字符串 → List<String>
  static List<String> parsePackageList(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// 解析使用统计数据
  static List<Map<String, dynamic>> parseUsageStats(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }
}
