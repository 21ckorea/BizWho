# 🔐 안드로이드 앱 서명 키 생성 기록 (BizWho)

이 문서는 앱 배포를 위해 생성된 안드로이드 키스토어(`key.jks`) 정보를 기록하기 위한 **비밀 문서**입니다. 보안을 위해 GitHub에는 업로드되지 않도록 설정되어 있습니다.

## 🔑 키 생성 명령어 (Executed on 2026-04-05)

사용자님이 실행한 실제 명령어는 다음과 같습니다:

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
-genkey -v \
-keystore android/app/key.jks \
-keyalg RSA \
-keysize 2048 \
-validity 10000 \
-alias bizwho_key \
-storepass bizwho2026 \
-keypass bizwho2026 \
-dname "CN=BizWho, OU=Development, O=BizWho, L=Seoul, S=Seoul, C=KR"
```

## 📋 핵심 정보 요약

| 항목 | 정보 | 비고 |
| :--- | :--- | :--- |
| **파일명** | `android/app/key.jks` | 프로젝트 안드로이드 앱 폴더 내부 |
| **별칭 (Alias)** | `bizwho_key` | `key.properties`의 `keyAlias`와 일치해야 함 |
| **비밀번호** | `bizwho2026` | `storePassword` 및 `keyPassword`와 동일 |
| **유효 기간** | 10,000일 | 약 27년 (영구적 사용 가능) |

## ⚙️ 연동 파일 (`key.properties`)

위 정보를 바탕으로 `android/key.properties` 파일이 다음과 같이 구성되어 있습니다:

```properties
storePassword=bizwho2026
keyPassword=bizwho2026
keyAlias=bizwho_key
storeFile=key.jks
```

> [!CAUTION]
> - 이 문서와 `key.jks`, `key.properties` 파일은 절대 외부에 노출되지 않도록 주의하세요. 🔐
> - `.gitignore`에서 `key_setup.md`가 제대로 제외되어 있는지 항상 확인해 주세요.
