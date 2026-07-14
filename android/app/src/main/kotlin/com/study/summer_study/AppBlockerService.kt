package com.study.summer_study

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.view.accessibility.AccessibilityEvent
import android.util.Log

/**
 * 无障碍服务：监听前台App切换，拦截娱乐应用
 */
class AppBlockerService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"
        private const val PREFS_NAME = "parent_control_prefs"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_BLOCKING_ENABLED = "blocking_enabled"
        private const val KEY_TEMP_UNLOCK = "temp_unlock"

        private var instance: AppBlockerService? = null

        /** 检查无障碍服务是否在运行 */
        fun isRunning(): Boolean = instance != null
    }

    private lateinit var prefs: SharedPreferences
    private var blockedApps: Set<String> = emptySet()
    private var blockingEnabled: Boolean = false
    private var tempUnlock: Boolean = false
    private var lastBlockedPackage: String = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "无障碍服务已连接")

        // 配置监听类型
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            flags = AccessibilityServiceInfo.DEFAULT
        }
        serviceInfo = info

        // 加载设置
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        reloadSettings()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        // 只在设置了拦截开关时工作
        if (!blockingEnabled) return
        if (tempUnlock) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName.isEmpty() || packageName == packageName) return

        // 跳过自身应用
        if (packageName == "com.study.summer_study") return
        // 跳过系统应用
        if (packageName.startsWith("com.android.") ||
            packageName == "android") return

        // 检查是否在拦截列表中
        if (packageName !in blockedApps) return

        // 防止重复拦截同一个应用（短时间内）
        if (packageName == lastBlockedPackage) return
        lastBlockedPackage = packageName

        Log.i(TAG, "拦截应用: $packageName")

        // 获取应用名称
        val appName = getAppName(packageName)

        // 启动拦截界面
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("package_name", packageName)
            putExtra("app_name", appName)
        }
        startActivity(intent)

        // 延迟返回桌面
        android.os.Handler(mainLooper).postDelayed({
            performGlobalAction(GLOBAL_ACTION_HOME)
        }, 300)
    }

    override fun onInterrupt() {
        Log.d(TAG, "无障碍服务中断")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "无障碍服务已销毁")
    }

    /** 重新加载设置 */
    fun reloadSettings() {
        val json = prefs.getString(KEY_BLOCKED_APPS, "[]") ?: "[]"
        blockedApps = parseJsonArray(json)
        blockingEnabled = prefs.getBoolean(KEY_BLOCKING_ENABLED, false)
        tempUnlock = prefs.getBoolean(KEY_TEMP_UNLOCK, false)
        Log.d(TAG, "设置已更新: blocked=${blockedApps.size}个, enabled=$blockingEnabled, temp=$tempUnlock")
    }

    /** 获取应用名称 */
    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    /** 简单的JSON数组解析（[a,b,c] -> Set<String>） */
    private fun parseJsonArray(json: String): Set<String> {
        return try {
            json.trim('[', ']', ' ', '"')
                .split("\",\"", "\", \"", ",")
                .map { it.trim('"', ' ') }
                .filter { it.isNotEmpty() }
                .toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }
}
