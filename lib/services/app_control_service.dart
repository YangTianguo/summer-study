import 'package:flutter/services.dart';
import '../models/app_info.dart';

/// Android 家长控制服务（通过 MethodChannel 调用原生代码）
class AppControlService {
  static const _channel = MethodChannel('com.study.summer_study/parent_control');

  // ==================== 已安装应用 ====================

  /// 获取已安装的启动类应用列表
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final json = await _channel.invokeMethod<String>('getInstalledApps');
      if (json == null || json.isEmpty) return [];
      return AppInfo.fromJsonList(json);
    } catch (e) {
      return [];
    }
  }

  // ==================== 拦截应用管理 ====================

  /// 获取被拦截的应用包名列表
  static Future<List<String>> getBlockedApps() async {
    try {
      final json = await _channel.invokeMethod<String>('getBlockedApps');
      if (json == null || json.isEmpty) return [];
      return AppInfo.parsePackageList(json);
    } catch (e) {
      return [];
    }
  }

  /// 设置拦截应用列表（替换整个列表）
  static Future<bool> setBlockedApps(List<String> packages) async {
    try {
      return await _channel.invokeMethod<bool>('setBlockedApps', packages) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 添加单个应用到拦截列表
  static Future<bool> addBlockedApp(String packageName) async {
    try {
      return await _channel.invokeMethod<bool>('addBlockedApp', packageName) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 从拦截列表移除单个应用
  static Future<bool> removeBlockedApp(String packageName) async {
    try {
      return await _channel.invokeMethod<bool>('removeBlockedApp', packageName) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== 拦截开关 ====================

  /// 拦截是否启用
  static Future<bool> isBlockingEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isBlockingEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 设置拦截开关
  static Future<bool> setBlockingEnabled(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('setBlockingEnabled', enabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== 临时解锁 ====================

  /// 是否处于临时解锁状态
  static Future<bool> isTempUnlocked() async {
    try {
      return await _channel.invokeMethod<bool>('isTempUnlocked') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 清除临时解锁状态
  static Future<void> clearTempUnlock() async {
    try {
      await _channel.invokeMethod('clearTempUnlock');
    } catch (_) {}
  }

  // ==================== 密码管理 ====================

  /// 设置家长密码
  static Future<bool> setParentPassword(String password) async {
    try {
      return await _channel.invokeMethod<bool>('setParentPassword', password) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 验证家长密码
  static Future<bool> verifyParentPassword(String password) async {
    try {
      return await _channel.invokeMethod<bool>('verifyParentPassword', password) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 是否已设置家长密码
  static Future<bool> hasParentPassword() async {
    try {
      return await _channel.invokeMethod<bool>('hasParentPassword') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== 权限检查 ====================

  /// 无障碍服务是否启用
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 使用统计权限是否已授权
  static Future<bool> isUsageStatsPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isUsageStatsPermissionGranted') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 悬浮窗权限是否已授权
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isOverlayPermissionGranted') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== 打开系统设置 ====================

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {}
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  // ==================== 使用统计 ====================

  /// 获取应用使用统计（days: 查询最近几天的数据）
  static Future<List<Map<String, dynamic>>> getAppUsageStats({int days = 1}) async {
    try {
      final json = await _channel.invokeMethod<String>('getAppUsageStats', days);
      if (json == null || json.isEmpty) return [];
      return AppInfo.parseUsageStats(json);
    } catch (e) {
      return [];
    }
  }
}
