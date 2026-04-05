package com.bizwho.callerid

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bizwho.callerid/role_manager" // v1.0: 정규화된 주소
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    private val PERMISSION_REQUEST_CODE = 999

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i("CallerIDDEBUG", "MainActivity onCreate (v1.0) START")
        
        checkAndRequestPermissions()
        requestIgnoreBatteryOptimization()
    }

    override fun onResume() {
        super.onResume()
        Log.i("CallerIDDEBUG", "MainActivity onResume")
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            Log.i("CallerIDDEBUG", "MethodChannel received: ${call.method}") // v2.16: 모든 요청을 Info 로그로 기록
            
            when (call.method) {
                "requestRole" -> result.success(true) // v1.0.3: 서비스 제거로 항상 통과
                "checkOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else true
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "testOverlay" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        Toast.makeText(this@MainActivity, "권한 차단됨: 설정 -> 앱 정보 -> [⋮] -> [제한된 설정 허용] 후 다시 시도해 주세요.", Toast.LENGTH_LONG).show()
                        requestOverlayPermission()
                        result.success(false)
                    } else {
                        val args = call.arguments as? Map<*, *>
                        val info = args?.get("info") as? String ?: "소속부서|성함 직책님"
                        val position = args?.get("position") as? String ?: "top"
                        val fontSize = args?.get("fontSize") as? Int ?: 22
                        
                        Toast.makeText(this@MainActivity, "미리보기 실행 중: ${position.uppercase()}", Toast.LENGTH_SHORT).show()
                        Log.i("CallerIDDEBUG", "Starting BizWhoUIBridge: $info (Pos: $position, Size: $fontSize)")
                        
                        val intent = Intent(this, BizWhoUIBridge::class.java)
                        intent.putExtra("employeeInfo", info)
                        intent.putExtra("position", position)
                        intent.putExtra("fontSize", fontSize)
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                }
                "clearOverlay" -> {
                    Toast.makeText(this@MainActivity, "알림 데이터를 초기화합니다.", Toast.LENGTH_SHORT).show()
                    val intent = Intent(this, BizWhoUIBridge::class.java)
                    intent.action = "ACTION_CLEAR"
                    startService(intent)
                    result.success(true)
                }
                "setDatabasePath" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String
                    if (path != null) {
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        prefs.edit().putString("flutter.db_path", path).apply()
                        Log.i("CallerIDDetect", "DB Path Synced: $path")
                        Toast.makeText(this@MainActivity, "DB 주소 동기화 완료!", Toast.LENGTH_SHORT).show()
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndRequestPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        val essential = arrayOf(Manifest.permission.READ_PHONE_STATE, Manifest.permission.READ_CALL_LOG)
        for (p in essential) {
            if (ContextCompat.checkSelfPermission(this, p) != PackageManager.PERMISSION_GRANTED) permissions.add(p)
        }
        if (permissions.isNotEmpty()) ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    private fun checkOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.w("CallerIDDEBUG", "Overlay Permission NOT GRANTED - prompting user")
                requestOverlayPermission()
            }
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
            startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
        }
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))
                startActivity(intent)
            }
        }
    }
}
