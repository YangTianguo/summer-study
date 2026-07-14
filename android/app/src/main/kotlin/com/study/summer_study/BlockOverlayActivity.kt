package com.study.summer_study

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.text.InputType
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.*
import java.security.MessageDigest

/**
 * 应用拦截遮罩界面
 * 当被拦截的应用打开时显示此界面
 */
class BlockOverlayActivity : Activity() {

    companion object {
        private const val TAG = "BlockOverlayActivity"
        private const val PREFS_NAME = "parent_control_prefs"
        private const val KEY_PASSWORD_HASH = "parent_password_hash"
        private const val KEY_TEMP_UNLOCK = "temp_unlock"

        /** 清除临时解锁状态 */
        fun clearTempUnlock(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_TEMP_UNLOCK, false).apply()
        }
    }

    private lateinit var prefs: SharedPreferences
    private var blockedPackage: String = ""
    private var blockedAppName: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        blockedPackage = intent.getStringExtra("package_name") ?: ""
        blockedAppName = intent.getStringExtra("app_name") ?: "未知应用"

        // 设置窗口属性
        setupWindow()

        // 构建界面
        setContentView(createBlockingView())
    }

    private fun setupWindow() {
        window.apply {
            // 在锁屏上显示
            addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            // 全屏
            setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
            // 设置背景为半透明
            setBackgroundDrawableResource(android.R.color.transparent)
            statusBarColor = Color.TRANSPARENT
            navigationBarColor = Color.parseColor("#E0000000")
        }
    }

    private fun createBlockingView(): View {
        val rootLayout = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#E0000000"))
        }

        // 主卡片容器
        val cardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            // 圆角白色背景
            background = createCardBackground()
        }

        // 锁图标
        val lockIcon = TextView(this).apply {
            text = "🔒"
            textSize = 56f
            gravity = Gravity.CENTER
        }
        cardLayout.addView(lockIcon)

        // 间隔
        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 24)
        })

        // 标题
        val titleText = TextView(this).apply {
            text = "学习任务未完成"
            textSize = 22f
            setTextColor(Color.parseColor("#333333"))
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        cardLayout.addView(titleText)

        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 8)
        })

        // 副标题
        val subtitleText = TextView(this).apply {
            text = "「$blockedAppName」已被锁定\n请先完成今天的学习任务"
            textSize = 15f
            setTextColor(Color.parseColor("#666666"))
            gravity = Gravity.CENTER
            lineCount = 2
        }
        cardLayout.addView(subtitleText)

        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 28)
        })

        // 密码输入区域
        val passwordLabel = TextView(this).apply {
            text = "家长密码解锁："
            textSize = 13f
            setTextColor(Color.parseColor("#999999"))
            gravity = Gravity.CENTER
        }
        cardLayout.addView(passwordLabel)

        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 8)
        })

        val passwordInput = EditText(this).apply {
            hint = "请输入密码"
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_VARIATION_PASSWORD
            textSize = 18f
            gravity = Gravity.CENTER
            maxLines = 1
            setPadding(16, 12, 16, 12)
            background = createEditBackground()
            layoutParams = LinearLayout.LayoutParams(400, LinearLayout.LayoutParams.WRAP_CONTENT)
        }
        cardLayout.addView(passwordInput)

        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 16)
        })

        // 错误提示
        val errorText = TextView(this).apply {
            text = ""
            textSize = 13f
            setTextColor(Color.parseColor("#E53935"))
            gravity = Gravity.CENTER
        }
        cardLayout.addView(errorText)

        // 解锁按钮
        val unlockButton = Button(this).apply {
            text = "临时解锁（30分钟）"
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#4A90D9"))
            setPadding(48, 14, 48, 14)
            isAllCaps = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 4, 0, 0)
            }
            setOnClickListener {
                val password = passwordInput.text.toString()
                if (verifyPassword(password)) {
                    // 密码正确，临时解锁
                    tempUnlock()
                    Log.i(TAG, "家长密码验证通过，临时解锁30分钟")
                    Toast.makeText(
                        this@BlockOverlayActivity,
                        "已临时解锁30分钟",
                        Toast.LENGTH_SHORT
                    ).show()
                    finish()
                } else {
                    errorText.text = "密码错误，请重试"
                    passwordInput.text.clear()
                }
            }
        }
        cardLayout.addView(unlockButton)

        cardLayout.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, 16)
        })

        // 返回桌面按钮
        val backButton = TextView(this).apply {
            text = "返回桌面继续学习"
            textSize = 14f
            setTextColor(Color.parseColor("#4A90D9"))
            gravity = Gravity.CENTER
            setPadding(16, 12, 16, 12)
            setOnClickListener {
                goToHome()
            }
        }
        cardLayout.addView(backButton)

        // 将卡片放入FrameLayout居中
        val cardParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        rootLayout.addView(cardLayout, cardParams)

        return rootLayout
    }

    private fun verifyPassword(input: String): Boolean {
        val storedHash = prefs.getString(KEY_PASSWORD_HASH, null) ?: return false
        val inputHash = sha256(input)
        return inputHash == storedHash
    }

    private fun tempUnlock() {
        prefs.edit()
            .putBoolean(KEY_TEMP_UNLOCK, true)
            .apply()

        // 30分钟后自动取消临时解锁
        val handler = android.os.Handler(mainLooper)
        handler.postDelayed({
            prefs.edit().putBoolean(KEY_TEMP_UNLOCK, false).apply()
            Log.d(TAG, "临时解锁已过期")
        }, 30 * 60 * 1000) // 30分钟
    }

    private fun goToHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        finish()
    }

    override fun onBackPressed() {
        goToHome()
    }

    private fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(input.toByteArray())
        return hash.joinToString("") { "%02x".format(it) }
    }

    private fun createCardBackground(): android.graphics.drawable.Drawable {
        val drawable = android.graphics.drawable.GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = 24f
            setStroke(1, Color.parseColor("#E0E0E0"))
        }
        return drawable
    }

    private fun createEditBackground(): android.graphics.drawable.Drawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(Color.parseColor("#F5F5F5"))
            cornerRadius = 12f
            setStroke(1, Color.parseColor("#E0E0E0"))
        }
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
