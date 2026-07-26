package com.applyengine

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.content.Context
import androidx.core.content.FileProvider
import java.io.File
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.applyengine/whatsapp_automator"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled(this))
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "setAutoSendActive" -> {
                    val active = call.argument<Boolean>("active") ?: false
                    AutomationAccessibilityService.isAutoSendActive = active
                    result.success(true)
                }
                "setCampaignType" -> {
                    val type = call.argument<String>("type") ?: "WhatsApp"
                    AutomationAccessibilityService.campaignType = type
                    result.success(true)
                }
                "setLinkedInMessage" -> {
                    val message = call.argument<String>("message") ?: ""
                    AutomationAccessibilityService.linkedinMessage = message
                    result.success(true)
                }
                "openLinkedInProfile" -> {
                    val url = call.argument<String>("url") ?: ""
                    val launched = openLinkedInProfile(url)
                    result.success(launched)
                }
                "getLinkedInLastStatus" -> {
                    result.success(AutomationAccessibilityService.lastSentSuccess)
                }
                "shareFileAndTextToWhatsApp" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    val filePath = call.argument<String>("filePath") ?: ""
                    val success = shareFileAndTextToWhatsApp(phone, text, filePath)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun shareFileAndTextToWhatsApp(phone: String, text: String, filePath: String): Boolean {
        Log.d("MainActivity", "shareFileAndTextToWhatsApp called: phone=$phone, filePath=$filePath")
        val file = File(filePath)
        if (!file.exists()) {
            Log.e("MainActivity", "File does not exist at path: $filePath")
            return false
        }
        return try {
            val authority = "${packageName}.fileprovider"
            val fileUri = FileProvider.getUriForFile(this, authority, file)
            Log.d("MainActivity", "Generated FileProvider URI: $fileUri")

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra("jid", "$phone@s.whatsapp.net")
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            Log.d("MainActivity", "Launching WhatsApp intent for PDF sharing...")
            startActivity(intent)
            Log.d("MainActivity", "WhatsApp share intent launched successfully!")
            true
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to share file to WhatsApp: ${e.message}", e)
            false
        }
    }

    private fun openLinkedInProfile(url: String): Boolean {
        Log.d("MainActivity", "openLinkedInProfile called: url=$url")
        AutomationAccessibilityService.profileOpenTime = System.currentTimeMillis()
        AutomationAccessibilityService.lastSentSuccess = false
        AutomationAccessibilityService.bottomSheetOpened = false
        AutomationAccessibilityService.textFilledTime = 0L
        return try {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                setPackage("com.linkedin.android")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            Log.d("MainActivity", "Failed with package com.linkedin.android, trying fallback: ${e.message}")
            try {
                val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                true
            } catch (ex: Exception) {
                Log.e("MainActivity", "Failed fallback browser launch: ${ex.message}", ex)
                false
            }
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val service = context.packageName + "/" + AutomationAccessibilityService::class.java.name
        var accessibilityEnabled = 0
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            // Ignore
        }
        val mStringColonSplitter = TextUtils.SimpleStringSplitter(':')
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    val accessibilityService = mStringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true) || 
                        accessibilityService.contains(AutomationAccessibilityService::class.java.simpleName)) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
}
