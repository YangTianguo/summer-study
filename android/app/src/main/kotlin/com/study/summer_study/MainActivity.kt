package com.study.summer_study

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.security.MessageDigest

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.study.summer_study/parent_control"
        private const val PREFS_NAME = "parent_control_prefs"
        private const val TAG = "MainActivity"
    }

    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // ========== 已安装应用 ==========
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }

                    // ========== 拦截应用管理 ==========
                    "getBlockedApps" -> {
                        val apps = getBlockedApps()
                        result.success(apps)
                    }

                    "setBlockedApps" -> {
                        val apps = call.arguments as? List<*> ?: emptyList<String>()
                        setBlockedApps(apps.filterIsInstance<String>())
                        result.success(true)
                    }

                    "addBlockedApp" -> {
                        val packageName = call.arguments as? String ?: ""
                        addBlockedApp(packageName)
                        result.success(true)
                    }

                    "removeBlockedApp" -> {
                        val packageName = call.arguments as? String ?: ""
                        removeBlockedApp(packageName)
                        result.success(true)
                    }

                    // ========== 拦截开关 ==========
                    "isBlockingEnabled" -> {
                        result.success(isBlockingEnabled())
                    }

                    "setBlockingEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        setBlockingEnabled(enabled)
                        result.success(true)
                    }

                    // ========== 临时解锁 ==========
                    "isTempUnlocked" -> {
                        result.success(isTempUnlocked())
                    }

                    "clearTempUnlock" -> {
                        BlockOverlayActivity.clearTempUnlock(this)
                        result.success(true)
                    }

                    // ========== 密码管理 ==========
                    "setParentPassword" -> {
                        val password = call.arguments as? String ?: ""
                        setParentPassword(password)
                        result.success(true)
                    }

                    "verifyParentPassword" -> {
                        val password = call.arguments as? String ?: ""
                        result.success(verifyParentPassword(password))
                    }

                    "hasParentPassword" -> {
                        result.success(hasParentPassword())
                    }

                    // ========== 权限检查 ==========
                    "isAccessibilityServiceEnabled" -> {
                        result.success(AppBlockerService.isRunning())
                    }

                    "isUsageStatsPermissionGranted" -> {
                        result.success(isUsageStatsPermissionGranted())
                    }

                    "isOverlayPermissionGranted" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                                Settings.canDrawOverlays(this)
                            else true
                        )
                    }

                    // ========== 打开系统设置 ==========
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }

                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(true)
                    }

                    "openOverlaySettings" -> {
                        openOverlaySettings()
                        result.success(true)
                    }

                    // ========== 即时检查 ==========
                    "checkAndBlockCurrentApp" -> {
                        // 检查当前前台应用是否需要拦截（用于定时检查）
                        result.success(false)
                    }

                    // ========== 应用使用统计 ==========
                    "getAppUsageStats" -> {
                        val days = (call.arguments as? Int) ?: 1
                        result.success(getAppUsageStats(days))
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    // ==================== 已安装应用列表 ====================

    private fun getInstalledApps(): String {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(mainIntent, 0)
        }

        val jsonArray = JSONArray()
        val selfPackage = packageName

        for (ri in activities) {
            val pkg = ri.activityInfo.packageName
            if (pkg == selfPackage) continue

            val appName = ri.loadLabel(pm).toString()
            val iconBase64 = getAppIconBase64(pkg)

            val obj = JSONObject().apply {
                put("packageName", pkg)
                put("appName", appName)
                put("iconBase64", iconBase64 ?: "")
            }
            jsonArray.put(obj)
        }

        return jsonArray.toString()
    }

    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable)
            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
            val byteArray = outputStream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    // ==================== 拦截应用管理 ====================

    private fun getBlockedApps(): String {
        return prefs.getString("blocked_apps", "[]") ?: "[]"
    }

    private fun setBlockedApps(packages: List<String>) {
        val jsonArray = JSONArray(packages)
        prefs.edit().putString("blocked_apps", jsonArray.toString()).apply()
        notifyBlockerService()
    }

    private fun addBlockedApp(packageName: String) {
        val current = getBlockedAppsList()
        if (packageName !in current) {
            current.add(packageName)
            setBlockedApps(current)
        }
    }

    private fun removeBlockedApp(packageName: String) {
        val current = getBlockedAppsList()
        current.remove(packageName)
        setBlockedApps(current)
    }

    private fun getBlockedAppsList(): MutableList<String> {
        val json = prefs.getString("blocked_apps", "[]") ?: "[]"
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { arr.getString(it) }.toMutableList()
        } catch (e: Exception) {
            mutableListOf()
        }
    }

    // ==================== 拦截开关 ====================

    private fun isBlockingEnabled(): Boolean {
        return prefs.getBoolean("blocking_enabled", false)
    }

    private fun setBlockingEnabled(enabled: Boolean) {
        prefs.edit().putBoolean("blocking_enabled", enabled).apply()
        notifyBlockerService()
    }

    // ==================== 临时解锁 ====================

    private fun isTempUnlocked(): Boolean {
        return prefs.getBoolean("temp_unlock", false)
    }

    // ==================== 密码管理 ====================

    private fun setParentPassword(password: String) {
        if (password.isEmpty()) {
            prefs.edit().remove("parent_password_hash").apply()
        } else {
            val hash = sha256(password)
            prefs.edit().putString("parent_password_hash", hash).apply()
        }
    }

    private fun verifyParentPassword(password: String): Boolean {
        val storedHash = prefs.getString("parent_password_hash", null) ?: return false
        return sha256(password) == storedHash
    }

    private fun hasParentPassword(): Boolean {
        return prefs.getString("parent_password_hash", null) != null
    }

    // ==================== 权限检查 ====================

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // ==================== 打开设置 ====================

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    // ==================== 使用统计 ====================

    private fun getAppUsageStats(days: Int): String {
        if (!isUsageStatsPermissionGranted()) return "[]"

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (days * 24L * 60 * 60 * 1000)

        val usageStatsList = usageStatsManager.queryUsageStats(
            android.app.usage.UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (usageStatsList.isNullOrEmpty()) return "[]"

        // 按应用聚合使用时间
        val appUsageMap = mutableMapOf<String, Long>()
        for (stats in usageStatsList) {
            val time = stats.totalTimeInForeground
            if (time > 0) {
                appUsageMap[stats.packageName] =
                    (appUsageMap[stats.packageName] ?: 0) + time
            }
        }

        val jsonArray = JSONArray()
        val pm = packageManager
        for ((pkg, time) in appUsageMap) {
            val appName = try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                pkg
            }
            val obj = JSONObject().apply {
                put("packageName", pkg)
                put("appName", appName)
                put("usageTimeMs", time)
                put("usageTimeMinutes", time / (60 * 1000))
            }
            jsonArray.put(obj)
        }

        return jsonArray.toString()
    }

    // ==================== 辅助方法 ====================

    private fun notifyBlockerService() {
        AppBlockerService.instance?.reloadSettings()
    }

    private fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(input.toByteArray())
        return hash.joinToString("") { "%02x".format(it) }
    }
}
