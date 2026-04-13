package com.bizwho.callerid;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.app.NotificationCompat;

public class BizWhoUIBridge extends Service {
    private static final String CHANNEL_ID = "BizWhoUIV2";
    private static final int NOTIFICATION_ID = 1002;
    
    // v1.5.0: 제어 액션 추가
    public static final String ACTION_STOP_TIMER = "ACTION_STOP_TIMER";
    public static final String ACTION_CLEAR = "ACTION_CLEAR";

    private WindowManager windowManager;
    private View overlayView;
    private Handler timerHandler = new Handler(Looper.getMainLooper());
    private Runnable hideRunnable;

    // v1.7.9: 폴더블 대응을 위한 현재 상태 저장
    private String lastInfo;
    private String lastPosition;
    private int lastFontSize;
    private int lastDuration;
    private boolean isShowingActive = false; // v1.7.9-hotfix: 오버레이 활성 상태 추적

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, getServiceNotification());
        Log.i("CallerIDDEBUG", "BizWhoUIBridge onStartCommand (v1.5.0-STATE-AWARE)");

        if (intent != null) {
            String action = intent.getAction();
            if (ACTION_STOP_TIMER.equals(action)) {
                // v1.5.0: 통화 시작 시 자동 소멸 타이머 취소
                if (hideRunnable != null) {
                    timerHandler.removeCallbacks(hideRunnable);
                    Log.i("CallerIDDEBUG", "SUCCESS: Info Timer CANCELLED (Call Started)");
                }
            } else if (ACTION_CLEAR.equals(action)) {
                // v1.5.0: 통화 종료 시 즉시 제거
                stopSelf();
            } else if (intent.hasExtra("employeeInfo")) {
                // 새 오버레이 요청
                String info = intent.getStringExtra("employeeInfo");
                String position = intent.getStringExtra("position");
                int fontSize = intent.getIntExtra("fontSize", 22);
                int duration = intent.getIntExtra("duration", 30);
                showOverlay(info, position, fontSize, duration);
            }
        }

        return START_NOT_STICKY;
    }

    private void showOverlay(String info, String position, int fontSize, int duration) {
        // v1.7.9: 상태 저장 (폴더블 화면 전환 대비)
        this.lastInfo = info;
        this.lastPosition = position;
        this.lastFontSize = fontSize;
        this.lastDuration = duration;
        this.isShowingActive = true; // v1.7.9-hotfix: 요청 수신됨

        removeExistingOverlay();
        windowManager = (WindowManager) getSystemService(Context.WINDOW_SERVICE);
        overlayView = createProgrammaticLayout(info, fontSize, duration);

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL |
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON |
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
        );

        // v1.1.2: 위치(Gravity) 설정 반영
        // v1.7.9: "middle" 문자열로 통일
        if ("middle".equals(position)) {
            params.gravity = Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL;
            params.y = 0;
        } else if ("bottom".equals(position)) {
            params.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
            params.y = 150;
        } else {
            params.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
            params.y = 100;
        }

        try {
            windowManager.addView(overlayView, params);
            // v1.2.0: 심플한 페이드인 효과
            overlayView.setAlpha(0f);
            overlayView.animate().alpha(1.0f).setDuration(400).start();
            Log.i("CallerIDDEBUG", "SUCCESS: Premium Overlay added (" + position + ")");
        } catch (Exception e) {
            Log.e("CallerIDDEBUG", "FAIL: Unable to add window - " + e.getMessage());
        }
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        // v1.7.9: 폴더블 폰(Z Flip) 화면 전환 감지
        Log.i("CallerIDDEBUG", "onConfigurationChanged: Screen layout/Folding changed");
        
        // 500ms 지연 후 재렌더링 (OS의 디스플레이 전환 완료 대기)
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (isShowingActive && lastInfo != null) {
                Log.i("CallerIDDEBUG", "RE-RENDERING overlay for new display configuration");
                showOverlay(lastInfo, lastPosition, lastFontSize, lastDuration);
            }
        }, 500);
    }

    private View createProgrammaticLayout(String info, int fontSize, int duration) {
        // v1.3.0: Colorful Premium Card 디자인
        
        // 외곽 래퍼 (마진용)
        LinearLayout wrapper = new LinearLayout(this);
        wrapper.setOrientation(LinearLayout.VERTICAL);
        int marginH = TypedValueToPx(12);
        wrapper.setPadding(marginH, 0, marginH, 0);

        // 메인 카드 컨테이너
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        
        // 그라데이션 배경 (Deep Blue → Teal)
        GradientDrawable shape = new GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            new int[]{
                Color.parseColor("#E6083B7A"),  // Deep Navy
                Color.parseColor("#E60D47A1"),  // Signature Blue
                Color.parseColor("#E6006064")   // Dark Teal
            }
        );
        shape.setCornerRadius(TypedValueToPx(20));
        shape.setStroke(TypedValueToPx(1.5f), Color.parseColor("#66FFFFFF"));
        card.setBackground(shape);

        int padH = TypedValueToPx(20);
        int padV = TypedValueToPx(16);
        card.setPadding(padH, padV, padH, padV);

        // 좌측 액센트 바 + 아이콘
        LinearLayout iconBlock = new LinearLayout(this);
        iconBlock.setOrientation(LinearLayout.VERTICAL);
        iconBlock.setGravity(Gravity.CENTER);

        // 원형 아이콘 배지
        GradientDrawable circleBg = new GradientDrawable();
        circleBg.setShape(GradientDrawable.OVAL);
        circleBg.setColor(Color.parseColor("#3300BCD4")); // 반투명 Cyan
        circleBg.setStroke(TypedValueToPx(1), Color.parseColor("#8000BCD4"));
        
        ImageView iconView = new ImageView(this);
        iconView.setImageResource(android.R.drawable.ic_menu_call);
        iconView.setColorFilter(Color.parseColor("#80DEEA")); // Cyan 200
        iconView.setBackground(circleBg);
        int iconPad = TypedValueToPx(8);
        iconView.setPadding(iconPad, iconPad, iconPad, iconPad);
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(TypedValueToPx(44), TypedValueToPx(44));
        iconParams.setMargins(0, 0, TypedValueToPx(16), 0);
        iconView.setLayoutParams(iconParams);
        card.addView(iconView);

        // 텍스트 블록 (이름 + 부서 컬러 분리)
        LinearLayout textBlock = new LinearLayout(this);
        textBlock.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams textBlockParams = new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f); // weight=1로 남은 공간 채움
        textBlock.setLayoutParams(textBlockParams);
        
        // info를 줄바꿈으로 분리: 첫 줄 = 이름, 두번째 줄 = 부서
        String nameLine = info != null ? info : "알 수 없는 발신자";
        String deptLine = "";
        if (info != null && info.contains("\n")) {
            String[] parts = info.split("\n");
            nameLine = parts[0];
            deptLine = parts.length > 1 ? parts[1] : "";
        }

        // 이름 (White Bold)
        TextView nameText = new TextView(this);
        nameText.setText(nameLine);
        nameText.setTextColor(Color.WHITE);
        nameText.setTextSize((float) fontSize);
        nameText.setTypeface(null, Typeface.BOLD);
        nameText.setShadowLayer(4f, 0f, 2f, Color.parseColor("#40000000"));
        textBlock.addView(nameText);

        // 부서 (Golden Amber)
        if (!deptLine.isEmpty()) {
            TextView deptText = new TextView(this);
            deptText.setText(deptLine);
            deptText.setTextColor(Color.parseColor("#FFECB3")); // Amber 100
            deptText.setTextSize((float) Math.max(fontSize - 4, 14));
            deptText.setTypeface(null, Typeface.NORMAL);
            LinearLayout.LayoutParams deptParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            deptParams.setMargins(0, TypedValueToPx(4), 0, 0);
            deptText.setLayoutParams(deptParams);
            textBlock.addView(deptText);
        }

        card.addView(textBlock);
        wrapper.addView(card);

        wrapper.setOnClickListener(v -> stopSelf());
        
        // v1.5.0: 타이머 관리 (나중에 취소 가능하도록 Runnable로 감쌈)
        if (hideRunnable != null) {
            timerHandler.removeCallbacks(hideRunnable);
        }
        hideRunnable = this::stopSelf;
        timerHandler.postDelayed(hideRunnable, duration * 1000L); 
        
        return wrapper;
    }

    private int TypedValueToPx(float dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }

    private void removeExistingOverlay() {
        if (overlayView != null && windowManager != null) {
            try {
                windowManager.removeView(overlayView);
                overlayView = null;
            } catch (Exception e) {
                Log.e("CallerIDDEBUG", "Error removing overlay: " + e.getMessage());
            }
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "비즈후 프리미엄 엔진", NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }
    }

    private Notification getServiceNotification() {
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("비즈후 프리미엄 카드 가동 중")
                .setContentText("발신 정보를 분석하고 있습니다.")
                .setSmallIcon(android.R.drawable.stat_notify_chat)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }

    @Override
    public void onDestroy() {
        isShowingActive = false; // 서비스 종료 시 상태 해제
        removeExistingOverlay();
        super.onDestroy();
    }
}
