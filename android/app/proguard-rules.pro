# Flutter 및 네이티브 서비스 클래스 유지 규칙 (v1.0.9)

# 1. 수신 감지 및 UI 가교 서비스 클래스 보호
-keep class com.bizwho.callerid.PhoneStateReceiver { *; }
-keep class com.bizwho.callerid.BizWhoUIBridge { *; }

# 2. 리소스 및 레이아웃 관련 경고 무시 (필요 시)
-dontwarn com.bizwho.callerid.**

# 3. 기본 안드로이드 컴포넌트 유지
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.view.View

# 4. 레이아웃 리소스 접근 보호
-keepclassmembers class **.R$* {
    public static <fields>;
}
