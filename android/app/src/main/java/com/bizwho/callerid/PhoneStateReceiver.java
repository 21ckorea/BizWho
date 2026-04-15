package com.bizwho.callerid;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Build;
import android.telephony.TelephonyManager;
import android.util.Log;
import java.io.File;

public class PhoneStateReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction().equals(TelephonyManager.ACTION_PHONE_STATE_CHANGED)) {
            String state = intent.getStringExtra(TelephonyManager.EXTRA_STATE);
            Log.i("CallerIDDEBUG", "PhoneState: " + state);

            if (TelephonyManager.EXTRA_STATE_RINGING.equals(state)) {
                String phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER);
                if (phoneNumber != null) {
                    // v1.0: 8210... -> 010..., 10... -> 010... (10자리인 경우)
                    String cleaned = phoneNumber.replace("+82", "").replace("-", "").replace(" ", "");
                    if (cleaned.startsWith("82")) cleaned = cleaned.substring(2);
                    if (cleaned.startsWith("10") && cleaned.length() == 10) cleaned = "0" + cleaned;
                    
                    processIncomingCall(context, cleaned);
                }
            } else if (TelephonyManager.EXTRA_STATE_OFFHOOK.equals(state)) {
                // v1.5.0: 통화 시작 시 타이머 중지 명령 전송
                Intent stopTimerIntent = new Intent(context, BizWhoUIBridge.class);
                stopTimerIntent.setAction(BizWhoUIBridge.ACTION_STOP_TIMER);
                context.startService(stopTimerIntent);
            } else if (TelephonyManager.EXTRA_STATE_IDLE.equals(state)) {
                // v1.5.0: 통화 종료 시 오버레이 즉시 제거
                Intent clearIntent = new Intent(context, BizWhoUIBridge.class);
                clearIntent.setAction(BizWhoUIBridge.ACTION_CLEAR);
                context.startService(clearIntent);
            }
        }
    }

    private void processIncomingCall(Context context, String phoneNumber) {
        String employeeInfo = findEmployee(context, phoneNumber);
        if (employeeInfo != null) {
            startOverlayService(context, employeeInfo);
        } else {
            Log.i("CallerIDDEBUG", "No employee found in Receiver for: " + phoneNumber);
        }
    }

    private String findEmployee(Context context, String phoneNumber) {
        SQLiteDatabase db = null;
        Cursor cursor = null;
        try {
            SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
            String dbPath = prefs.getString("flutter.db_path", null);
            File dbFile = (dbPath != null) ? new File(dbPath) : context.getDatabasePath("employee_caller_id.db");
            
            Log.i("CallerIDDEBUG", "Receiver Searching DB at: " + dbFile.getAbsolutePath());
            
            if (!dbFile.exists()) {
                Log.e("CallerIDDEBUG", "Receiver DATABASE MISSING!");
                return null;
            }

            db = SQLiteDatabase.openDatabase(dbFile.getPath(), null, SQLiteDatabase.OPEN_READONLY);
            // v1.0: 정식 키 사용 검색할 수 있도록 쿼리 확장
            String query = "SELECT department, name, rank, position FROM employees " +
                          "WHERE REPLACE(REPLACE(phone_number, '-', ''), ' ', '') IN (?, ?) " +
                          "OR REPLACE(REPLACE(office_phone, '-', ''), ' ', '') IN (?, ?)";
            
            String altPhone = phoneNumber.startsWith("0") ? phoneNumber.substring(1) : phoneNumber;
            cursor = db.rawQuery(query, new String[]{phoneNumber, altPhone, phoneNumber, altPhone});

            if (cursor.moveToFirst()) {
                String dept = cursor.getString(0);
                String name = cursor.getString(1);
                String rank = cursor.getString(2);
                String pos = cursor.getString(3);
                
                // v1.3.2: 이름(직급/직책) 형식 — 둘 다 있으면 슬래시, 하나만 있으면 그것만
                String rankStr = (rank != null && !rank.trim().isEmpty()) ? rank.trim() : "";
                String posStr = (pos != null && !pos.trim().isEmpty()) ? pos.trim() : "";
                
                String titlePart = "";
                if (!rankStr.isEmpty() && !posStr.isEmpty()) {
                    if (rankStr.equals(posStr)) {
                        titlePart = "(" + rankStr + ")";
                    } else {
                        titlePart = "(" + rankStr + "/" + posStr + ")";
                    }
                } else if (!rankStr.isEmpty()) {
                    titlePart = "(" + rankStr + ")";
                } else if (!posStr.isEmpty()) {
                    titlePart = "(" + posStr + ")";
                }
                
                String nameLine = name + titlePart;
                String deptLine = (dept != null && !dept.trim().isEmpty()) ? dept.trim() : "";
                
                Log.i("CallerIDDEBUG", "Receiver FOUND: " + nameLine + " / " + deptLine);
                return deptLine.isEmpty() ? nameLine : nameLine + "\n" + deptLine;
            }
        } catch (Exception e) {
            Log.e("CallerIDDEBUG", "Receiver Search Failure: " + e.getLocalizedMessage());
        } finally {
            if (cursor != null) cursor.close();
            if (db != null) db.close();
        }
        return null;
    }

    private void startOverlayService(Context context, String employeeInfo) {
        // v1.3.0: SharedPreferences에서 사용자 설정값 읽기
        SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        String position = prefs.getString("flutter.pref_pos_v4", "middle");
        int fontSize = (int) prefs.getLong("flutter.pref_size_v4", 25);
        String bgColor = prefs.getString("flutter.pref_bg_v1", "E60D47A1");
        String textColor = prefs.getString("flutter.pref_text_v1", "FFFFFF");

        // v1.4.0: 유지 시간 로드 (Flutter setDouble -> Android Long Bits 변환 필요)
        int duration = 30;
        try {
            long bits = prefs.getLong("flutter.pref_duration_v4", Double.doubleToRawLongBits(30.0));
            duration = (int) Double.longBitsToDouble(bits);
        } catch (Exception e) {
            Log.e("CallerIDDEBUG", "Error reading duration: " + e.getLocalizedMessage());
        }

        Intent intent = new Intent(context, BizWhoUIBridge.class);
        intent.putExtra("employeeInfo", employeeInfo);
        intent.putExtra("position", position);
        intent.putExtra("fontSize", fontSize);
        intent.putExtra("duration", duration);
        intent.putExtra("bgColor", bgColor);
        intent.putExtra("textColor", textColor);
        Log.i("CallerIDDEBUG", "Overlay settings: pos=" + position + ", size=" + fontSize + ", dur=" + duration + ", colors=" + bgColor + "/" + textColor);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent);
        } else {
            context.startService(intent);
        }
    }
}
