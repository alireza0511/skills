# Security Flutter — Reference

## §Secure-Storage

### flutter_secure_storage Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'bank_secure_prefs',
      preferencesKeyPrefix: 'bank_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'com.bank.app',
    ),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### Platform Configuration

| Platform | Backend | Minimum OS |
|---|---|---|
| Android | EncryptedSharedPreferences (AES-256-SIV) | API 23+ |
| iOS | Keychain Services | iOS 12+ |
| Android StrongBox | Hardware-backed keystore | API 28+ (where available) |

### What NOT to Store in Secure Storage

| Data | Storage | Reason |
|---|---|---|
| Auth tokens | `flutter_secure_storage` | Encrypted at rest |
| Biometric enrollment flag | `flutter_secure_storage` | Tamper-resistant |
| User preferences (non-sensitive) | `SharedPreferences` | No encryption needed |
| Cached API responses | Encrypted database (`drift` + `sqlcipher`) | Too large for keychain |

---

## §Certificate-Pinning

### Dio Certificate Pinning Interceptor

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class CertificatePinningInterceptor extends Interceptor {
  // SHA-256 fingerprints of trusted leaf or intermediate certificates
  static const _trustedFingerprints = <String>{
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // primary
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // backup
  };

  static Dio createPinnedClient() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.bank.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => false;
        return client;
      },
      validateCertificate: (certificate, host, port) {
        if (certificate == null) return false;
        final fingerprint = _sha256Fingerprint(certificate);
        return _trustedFingerprints.contains(fingerprint);
      },
    );

    return dio;
  }

  static String _sha256Fingerprint(X509Certificate cert) {
    // Implementation: compute SHA-256 of DER-encoded certificate
    // Use crypto package for production
    return 'sha256/${base64Encode(sha256.convert(cert.der).bytes)}';
  }
}
```

### Pin Rotation Strategy

| Step | Action |
|---|---|
| 1 | Include backup pin in app before certificate rotation |
| 2 | Deploy app update with both old and new pins |
| 3 | Wait for adoption threshold (>95% on new version) |
| 4 | Rotate server certificate |
| 5 | Remove old pin in next app release |

---

## §Biometric-Auth

### local_auth Integration

```yaml
# pubspec.yaml
dependencies:
  local_auth: ^2.2.0
```

```dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isBiometricAvailable async {
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }

  Future<BiometricResult> authenticate({
    required String reason,
  }) async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,     // Never fall back to PIN/pattern
          stickyAuth: true,        // Re-auth if app goes to background
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate
          ? BiometricResult.success
          : BiometricResult.cancelled;
    } on PlatformException catch (e) {
      return switch (e.code) {
        'NotAvailable' => BiometricResult.notAvailable,
        'NotEnrolled' => BiometricResult.notEnrolled,
        'LockedOut' => BiometricResult.lockedOut,
        'PermanentlyLockedOut' => BiometricResult.permanentlyLockedOut,
        _ => BiometricResult.error,
      };
    }
  }
}

enum BiometricResult {
  success,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}
```

### Android Configuration

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

### iOS Configuration

```xml
<!-- ios/Runner/Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>Authenticate to access your bank account</string>
```

---

## §Obfuscation

### Release Build Commands

```bash
# Android
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android

# iOS
flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/ios
```

### Symbol Map Storage

| Artifact | Storage | Retention |
|---|---|---|
| `build/debug-info/*.symbols` | CI artifact storage | 2 years minimum |
| Mapping file | Firebase Crashlytics upload | Matches app version lifetime |
| dSYM (iOS) | Upload to Crashlytics + archive | 2 years minimum |

### Symbolication for Crash Reports

```bash
# Upload Android symbols to Crashlytics
firebase crashlytics:symbols:upload \
  --app=1:123456:android:abc123 \
  build/debug-info/android

# Upload iOS dSYM
firebase crashlytics:symbols:upload \
  --app=1:123456:ios:def456 \
  build/ios/archive/Runner.xcarchive/dSYMs
```

---

## §ProGuard-Config

### Android ProGuard Rules

```proguard
# android/app/proguard-rules.pro

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Gson / JSON serialization (if used)
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
```

### build.gradle Configuration

```groovy
// android/app/build.gradle
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
        }
    }
}
```

---

## §Device-Integrity

### Root/Jailbreak Detection

```yaml
# pubspec.yaml
dependencies:
  safe_device: ^1.1.0
  flutter_jailbreak_detection: ^1.10.0
```

```dart
import 'package:safe_device/safe_device.dart';

class DeviceIntegrityService {
  Future<DeviceIntegrityResult> check() async {
    final results = await Future.wait([
      SafeDevice.isJailBroken,
      SafeDevice.isRealDevice,
      SafeDevice.canMockLocation,
      SafeDevice.isOnExternalStorage,
      SafeDevice.isDevelopmentModeEnable,
    ]);

    final isJailbroken = results[0];
    final isRealDevice = results[1];
    final canMockLocation = results[2];
    final isExternalStorage = results[3];
    final isDevMode = results[4];

    if (isJailbroken) return DeviceIntegrityResult.compromised;
    if (!isRealDevice) return DeviceIntegrityResult.emulator;
    if (canMockLocation) return DeviceIntegrityResult.mockLocation;

    return DeviceIntegrityResult.safe;
  }
}

enum DeviceIntegrityResult { safe, compromised, emulator, mockLocation }
```

### Response Strategy

| Result | Action | User Message |
|---|---|---|
| `compromised` | Block sensitive operations | "This device does not meet security requirements." |
| `emulator` | Block in release builds | "Banking is not available on emulated devices." |
| `mockLocation` | Warn; log for fraud analysis | "Location services appear to be modified." |
| `safe` | Proceed normally | — |

---

## §Network-Security

### Android Network Security Configuration

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.bank.com</domain>
        <pin-set expiration="2025-12-31">
            <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
            <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="false">
```

### iOS App Transport Security

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.bank.com</key>
        <dict>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Secure Dio Client Factory

```dart
class SecureApiClient {
  static Dio create() {
    final dio = CertificatePinningInterceptor.createPinnedClient();

    dio.options
      ..connectTimeout = const Duration(seconds: 5)
      ..receiveTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 10);

    dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),  // Redacts PII in debug only
      _RetryInterceptor(maxRetries: 3),
    ]);

    return dio;
  }
}
```
