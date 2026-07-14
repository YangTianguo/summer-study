import 'package:flutter/foundation.dart';
import '../models/app_info.dart';
import '../services/app_control_service.dart';

class ParentControlProvider extends ChangeNotifier {
  List<AppInfo> _installedApps = [];
  Set<String> _blockedPackages = {};
  bool _isBlockingEnabled = false;
  bool _isTempUnlocked = false;
  bool _hasPassword = false;
  bool _isLoading = false;

  // 权限状态
  bool _accessibilityEnabled = false;
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;

  // 搜索过滤
  String _searchQuery = '';

  List<AppInfo> get installedApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps
        .where((a) =>
            a.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            a.packageName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<AppInfo> get blockedApps =>
      _installedApps.where((a) => _blockedPackages.contains(a.packageName)).toList();

  List<AppInfo> get availableApps =>
      _installedApps.where((a) => !_blockedPackages.contains(a.packageName)).toList();

  Set<String> get blockedPackages => _blockedPackages;
  bool get isBlockingEnabled => _isBlockingEnabled;
  bool get isTempUnlocked => _isTempUnlocked;
  bool get hasPassword => _hasPassword;
  bool get isLoading => _isLoading;
  bool get accessibilityEnabled => _accessibilityEnabled;
  bool get usageStatsGranted => _usageStatsGranted;
  bool get overlayGranted => _overlayGranted;
  bool get allPermissionsReady =>
      _accessibilityEnabled && _overlayGranted && _hasPassword;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 加载全部状态
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        AppControlService.getInstalledApps(),
        AppControlService.getBlockedApps(),
        AppControlService.isBlockingEnabled(),
        AppControlService.isTempUnlocked(),
        AppControlService.hasParentPassword(),
        AppControlService.isAccessibilityServiceEnabled(),
        AppControlService.isUsageStatsPermissionGranted(),
        AppControlService.isOverlayPermissionGranted(),
      ]);

      _installedApps = results[0] as List<AppInfo>;
      _blockedPackages = (results[1] as List<String>).toSet();
      _isBlockingEnabled = results[2] as bool;
      _isTempUnlocked = results[3] as bool;
      _hasPassword = results[4] as bool;
      _accessibilityEnabled = results[5] as bool;
      _usageStatsGranted = results[6] as bool;
      _overlayGranted = results[7] as bool;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换应用拦截状态
  Future<void> toggleAppBlocked(String packageName) async {
    if (_blockedPackages.contains(packageName)) {
      _blockedPackages.remove(packageName);
      await AppControlService.removeBlockedApp(packageName);
    } else {
      _blockedPackages.add(packageName);
      await AppControlService.addBlockedApp(packageName);
    }
    notifyListeners();
  }

  /// 设置拦截开关（由学习计划完成状态驱动）
  Future<void> setBlockingEnabled(bool enabled) async {
    _isBlockingEnabled = enabled;
    await AppControlService.setBlockingEnabled(enabled);
    notifyListeners();
  }

  /// 设置家长密码
  Future<bool> setPassword(String password) async {
    final success = await AppControlService.setParentPassword(password);
    if (success) {
      _hasPassword = password.isNotEmpty;
      notifyListeners();
    }
    return success;
  }

  /// 验证密码
  Future<bool> verifyPassword(String password) async {
    return await AppControlService.verifyParentPassword(password);
  }

  /// 刷新权限状态
  Future<void> refreshPermissions() async {
    final results = await Future.wait([
      AppControlService.isAccessibilityServiceEnabled(),
      AppControlService.isUsageStatsPermissionGranted(),
      AppControlService.isOverlayPermissionGranted(),
    ]);
    _accessibilityEnabled = results[0];
    _usageStatsGranted = results[1];
    _overlayGranted = results[2];
    notifyListeners();
  }

  // 打开系统设置
  Future<void> openAccessibilitySettings() =>
      AppControlService.openAccessibilitySettings();

  Future<void> openUsageAccessSettings() =>
      AppControlService.openUsageAccessSettings();

  Future<void> openOverlaySettings() =>
      AppControlService.openOverlaySettings();

  /// 根据学习完成状态自动切换拦截
  Future<void> updateBlockingByCompletion(bool allTasksCompleted) async {
    if (!_hasPassword) return; // 没设置密码则不启用

    if (allTasksCompleted) {
      // 全部完成 → 关闭拦截
      if (_isBlockingEnabled) {
        await setBlockingEnabled(false);
      }
    } else {
      // 未完成 → 开启拦截
      if (!_isBlockingEnabled && _blockedPackages.isNotEmpty) {
        await setBlockingEnabled(true);
      }
    }
  }
}
