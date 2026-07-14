import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parent_control_provider.dart';
import '../providers/plan_provider.dart';
import '../services/app_control_service.dart';

class ParentControlScreen extends StatefulWidget {
  const ParentControlScreen({super.key});

  @override
  State<ParentControlScreen> createState() => _ParentControlScreenState();
}

class _ParentControlScreenState extends State<ParentControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParentControlProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ 家长控制',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ParentControlProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === 设置向导提示 ===
              if (!provider.allPermissionsReady)
                _buildSetupGuide(context, provider),

              // === 密码设置 ===
              _buildPasswordSection(context, provider),

              const SizedBox(height: 12),

              // === 权限状态 ===
              _buildPermissionSection(context, provider),

              const SizedBox(height: 12),

              // === 拦截开关（手动） ===
              _buildBlockingSwitch(context, provider),

              const SizedBox(height: 12),

              // === 已拦截应用列表 ===
              _buildBlockedAppsSection(context, provider),

              const SizedBox(height: 12),

              // === 应用选择区 ===
              _buildAppSelector(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSetupGuide(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '设置向导',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              context,
              icon: Icons.lock,
              title: '设置家长密码',
              subtitle: '用于临时解锁和修改设置',
              isDone: provider.hasPassword,
              onTap: () => _showPasswordDialog(context, provider),
            ),
            const SizedBox(height: 8),
            _buildGuideStep(
              context,
              icon: Icons.accessibility,
              title: '开启无障碍服务',
              subtitle: '打开系统设置 → 找到"暑期提分" → 开启',
              isDone: provider.accessibilityEnabled,
              onTap: () => provider.openAccessibilitySettings(),
            ),
            const SizedBox(height: 8),
            _buildGuideStep(
              context,
              icon: Icons.layers,
              title: '允许悬浮窗权限',
              subtitle: '允许在其他应用上层显示',
              isDone: provider.overlayGranted,
              onTap: () => provider.openOverlaySettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDone ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : icon,
              size: 20,
              color: isDone ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.green : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (provider.hasPassword ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                provider.hasPassword ? Icons.lock : Icons.lock_open,
                color: provider.hasPassword ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家长密码',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    provider.hasPassword ? '已设置' : '未设置（必须设置）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: provider.hasPassword ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showPasswordDialog(context, provider),
              child: Text(provider.hasPassword ? '修改' : '设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '权限状态',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildPermissionRow(
              context,
              label: '无障碍服务',
              isGranted: provider.accessibilityEnabled,
              onTap: () => provider.openAccessibilitySettings(),
            ),
            const SizedBox(height: 6),
            _buildPermissionRow(
              context,
              label: '悬浮窗权限',
              isGranted: provider.overlayGranted,
              onTap: () => provider.openOverlaySettings(),
            ),
            const SizedBox(height: 6),
            _buildPermissionRow(
              context,
              label: '使用统计（可选）',
              isGranted: provider.usageStatsGranted,
              onTap: () => provider.openUsageAccessSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(
    BuildContext context, {
    required String label,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isGranted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  color: isGranted ? Colors.green : Colors.grey.shade700,
                )),
            const Spacer(),
            if (!isGranted)
              Text(
                '去开启 →',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingSwitch(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);

    // 检查学习完成状态
    final planProvider = context.watch<PlanProvider>();
    final allDone = planProvider.todayTotalTasks > 0 &&
        planProvider.todayCompletedTasks >= planProvider.todayTotalTasks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '应用拦截',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        allDone ? '✅ 今日任务已完成，已自动解锁' : '根据学习完成状态自动控制',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: allDone ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: provider.isBlockingEnabled,
                  onChanged: provider.hasPassword
                      ? (v) => provider.setBlockingEnabled(v)
                      : null,
                ),
              ],
            ),
            if (provider.isTempUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '已临时解锁（30分钟后自动恢复）',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        AppControlService.clearTempUnlock();
                        provider.loadAll();
                      },
                      child: const Text('取消解锁', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedAppsSection(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);
    final blocked = provider.blockedApps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已拦截应用 (${blocked.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (blocked.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('清除全部？'),
                          content: const Text('确定要取消所有应用的拦截吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () {
                                AppControlService.setBlockedApps([]);
                                provider.loadAll();
                                Navigator.pop(ctx);
                              },
                              child: const Text('清除全部'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('清除全部', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            if (blocked.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '还没有拦截任何应用\n从下方应用列表中选择',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ...blocked.map((app) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: app.iconBase64.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(app.iconBase64),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.android,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.android, size: 36, color: Colors.grey),
                  title: Text(app.appName, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(app.packageName,
                      style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.lock_open, size: 20),
                    onPressed: () => provider.toggleAppBlocked(app.packageName),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSelector(
      BuildContext context, ParentControlProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '可拦截应用',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: '搜索应用...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => provider.setSearchQuery(v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: provider.availableApps.length,
                itemBuilder: (context, index) {
                  final app = provider.availableApps[index];
                  final isBlocked =
                      provider.blockedPackages.contains(app.packageName);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: app.iconBase64.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(app.iconBase64),
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.android,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(Icons.android,
                            size: 36, color: Colors.grey),
                    title: Text(app.appName,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(app.packageName,
                        style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: Icon(
                        isBlocked ? Icons.lock : Icons.lock_open,
                        size: 20,
                        color: isBlocked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () =>
                          provider.toggleAppBlocked(app.packageName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(
      BuildContext context, ParentControlProvider provider) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final currentPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(provider.hasPassword ? '修改密码' : '设置家长密码'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.hasPassword)
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: '当前密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入当前密码';
                      return null;
                    },
                  ),
                if (provider.hasPassword) const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: '新密码（6位数字）',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.length < 4) return '至少4位数字';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '确认密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v != newPasswordController.text) return '两次密码不一致';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // 验证当前密码（修改时）
                if (provider.hasPassword) {
                  final valid = await provider.verifyPassword(
                    currentPasswordController.text,
                  );
                  if (!valid && ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('当前密码错误')),
                    );
                    return;
                  }
                }

                await provider.setPassword(newPasswordController.text);
                if (ctx.mounted) Navigator.pop(ctx);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码设置成功 ✅')),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }
}
