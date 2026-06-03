# 🚌 TransitWay – Developer Setup Guide

> دليل شامل لإعداد بيئة التطوير وفتح المشروع من الصفر

---

## 📋 المتطلبات الأساسية

| المتطلب | الإصدار المطلوب |
|---------|----------------|
| نظام التشغيل | Windows 10/11 (64-bit) |
| RAM | 8 GB كحد أدنى (16 GB موصى به) |
| مساحة القرص | 10 GB على الأقل |

---

## 1️⃣ تنزيل وتثبيت Android Studio

### الرابط الرسمي:
🔗 **https://developer.android.com/studio**

### خطوات التثبيت:
1. افتح الرابط واضغط **"Download Android Studio"**
2. اقبل الشروط وحمّل الملف (~1 GB)
3. شغّل الـ `.exe` واتبع الـ Setup Wizard
4. في خطوة **"Install Type"** اختر **Standard**
5. اتركه يكمل تنزيل الـ SDK تلقائياً

---

## 2️⃣ تنزيل وتثبيت Flutter SDK

### الرابط الرسمي:
🔗 **https://docs.flutter.dev/get-started/install/windows**

### خطوات التثبيت:
1. نزّل أحدث إصدار من **Flutter SDK** (`.zip`)
2. فكّ الضغط في: `C:\flutter\`
3. أضف Flutter لـ **PATH**:
   - **System Properties** → **Environment Variables**
   - **User Variables** → **Path** → **Edit** → **New**
   - أضف: `C:\flutter\bin`
4. تحقق من التثبيت:
   ```bash
   flutter --version
   ```

> Flutter بيجيب Dart SDK معاه تلقائياً.

---

## 3️⃣ إعداد Android SDK

افتح: **Settings** → **Languages & Frameworks** → **Android SDK**

#### SDK Platforms المطلوبة:
- ✅ Android 14 (API 34)
- ✅ Android 13 (API 33)

#### SDK Tools المطلوبة:
- ✅ Android SDK Build-Tools
- ✅ Android SDK Command-line Tools
- ✅ Android Emulator
- ✅ Android SDK Platform-Tools

---

## 4️⃣ الـ Plugins المطلوبة في Android Studio

**Settings** → **Plugins** → **Marketplace**

| Plugin | الأهمية |
|--------|---------|
| **Flutter** | 🔴 إلزامي |
| **Dart** | 🔴 إلزامي (بيجي مع Flutter) |
| **Rainbow Brackets** | 🟡 موصى به |
| **GitToolBox** | 🟡 موصى به |
| **.env files support** | 🟡 موصى به |

---

## 5️⃣ إعداد Flutter في Android Studio

**Settings** → **Languages & Frameworks** → **Flutter**

في خانة **Flutter SDK path** أدخل:
```
C:\flutter
```

---

## 6️⃣ التحقق من إعداد البيئة

```bash
flutter doctor
```

المفروض تشوف ✅ لكل العناصر.

---

## 7️⃣ فتح مشروع TransitWay

### Clone من GitHub:
```bash
git clone https://github.com/youssefkhalil772/NewTransitWay.git
```

### أو من Android Studio:
```
File → New → Project from Version Control
URL: https://github.com/youssefkhalil772/NewTransitWay.git
```

---

## 8️⃣ تشغيل المشروع

```bash
# تنزيل الـ packages
flutter pub get

# تشغيل على جهاز
flutter run

# بناء APK
flutter build apk --release
```

الـ APK هيكون في:
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## 9️⃣ هيكل المشروع

```
TransitWay/
├── lib/
│   ├── core/              # الأدوات المشتركة
│   ├── feature/
│   │   ├── home/          # شاشة الراكب الرئيسية
│   │   ├── driver/        # تطبيق السائق
│   │   ├── login/         # تسجيل الدخول
│   │   ├── tickets/       # التذاكر
│   │   ├── tracking/      # تتبع الباصات
│   │   ├── profile/       # الملف الشخصي
│   │   └── notifications/ # الإشعارات
├── android/
├── assets/
└── pubspec.yaml
```

---

## 🔧 الـ Dependencies الرئيسية

| Package | الاستخدام |
|---------|----------|
| `supabase_flutter` | قاعدة البيانات والـ Auth |
| `flutter_map` | خرائط OpenStreetMap |
| `geolocator` | تحديد الموقع GPS |
| `qr_flutter` | إنشاء QR codes |
| `mobile_scanner` | مسح QR codes |
| `shared_preferences` | حفظ البيانات محلياً |
| `flutter_screenutil` | تكييف الشاشات |
| `google_sign_in` | تسجيل الدخول بـ Google |

---

## ❓ مشاكل شائعة وحلولها

| المشكلة | الحل |
|---------|------|
| `flutter: command not found` | تأكد إن Flutter مضاف لـ PATH |
| `Gradle build failed` | شغّل `flutter clean` ثم `flutter pub get` |
| `Minimum SDK error` | تأكد إن `minSdkVersion >= 23` في build.gradle |
| `Package not found` | شغّل `flutter pub get` |

---

*آخر تحديث: يونيو 2026*
