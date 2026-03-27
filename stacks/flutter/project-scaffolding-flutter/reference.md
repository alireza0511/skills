# Project Scaffolding Flutter — Reference

## §Project-Structure

### Full Directory Tree

```
bank_app/
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── dev/                    # Dev flavor resources
│   │   │   ├── staging/                # Staging flavor resources
│   │   │   ├── prod/                   # Prod flavor resources
│   │   │   └── main/
│   │   │       └── AndroidManifest.xml
│   │   ├── build.gradle
│   │   └── proguard-rules.pro
│   └── build.gradle
├── ios/
│   ├── Runner/
│   │   ├── Info.plist
│   │   └── Configs/
│   │       ├── Dev.xcconfig
│   │       ├── Staging.xcconfig
│   │       └── Prod.xcconfig
│   └── Runner.xcodeproj/
├── lib/
│   ├── app/
│   │   ├── app.dart                    # MaterialApp
│   │   ├── router.dart                 # go_router
│   │   └── di.dart                     # get_it
│   ├── core/
│   │   ├── error/                      # Result, AppError, exceptions
│   │   ├── network/                    # Dio client, interceptors
│   │   ├── theme/                      # BankTheme, colors, typography
│   │   ├── widgets/                    # Shared widgets
│   │   ├── extensions/                 # Dart extensions
│   │   └── constants/                  # App-wide constants
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/           # Screens, widgets
│   │   │   ├── application/            # BLoC
│   │   │   ├── domain/                 # Entities, interfaces
│   │   │   └── data/                   # Repository impl, DTOs
│   │   ├── dashboard/
│   │   ├── transfer/
│   │   ├── accounts/
│   │   └── settings/
│   ├── l10n/                           # ARB localization files
│   │   ├── app_en.arb
│   │   └── app_fa.arb
│   └── main.dart
├── test/
│   ├── features/                       # Mirrors lib/features/
│   ├── core/
│   ├── golden/
│   │   └── flutter_test_config.dart
│   └── helpers/                        # Test utilities, fixtures
├── integration_test/
│   └── app_test.dart
├── analysis_options.yaml
├── build.yaml
├── l10n.yaml
├── pubspec.yaml
└── .gitignore
```

---

## §Analysis-Options

### analysis_options.yaml

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/l10n/**"
    - "test/.test_coverage.dart"
  errors:
    invalid_annotation_target: ignore
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    # Additional strict rules beyond very_good_analysis
    public_member_api_docs: true
    prefer_single_quotes: true
    always_declare_return_types: true
    avoid_dynamic_calls: true
    avoid_print: true
    avoid_relative_lib_imports: true
    cancel_subscriptions: true
    close_sinks: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    prefer_final_locals: true
    unnecessary_await_in_return: true
    use_if_null_to_convert_nulls_to_bools: true
```

---

## §Flavor-Setup

### Android Flavor Configuration

```groovy
// android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 34
    }

    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Bank (Dev)"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "Bank (Staging)"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "National Bank"
        }
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
        }
    }
}
```

### iOS Flavor Configuration (xcconfig)

```
// ios/Runner/Configs/Dev.xcconfig
BUNDLE_IDENTIFIER=com.bank.app.dev
PRODUCT_NAME=Bank (Dev)
API_URL=https://dev-api.bank.com
DISPLAY_NAME=Bank (Dev)
```

```
// ios/Runner/Configs/Staging.xcconfig
BUNDLE_IDENTIFIER=com.bank.app.staging
PRODUCT_NAME=Bank (Staging)
API_URL=https://staging-api.bank.com
DISPLAY_NAME=Bank (Staging)
```

```
// ios/Runner/Configs/Prod.xcconfig
BUNDLE_IDENTIFIER=com.bank.app
PRODUCT_NAME=National Bank
API_URL=https://api.bank.com
DISPLAY_NAME=National Bank
```

### Flutter Flavor Run Commands

```bash
# Development
flutter run --flavor dev --dart-define=ENVIRONMENT=dev --dart-define=API_URL=https://dev-api.bank.com

# Staging
flutter run --flavor staging --dart-define=ENVIRONMENT=staging --dart-define=API_URL=https://staging-api.bank.com

# Production
flutter run --flavor prod --dart-define=ENVIRONMENT=prod --dart-define=API_URL=https://api.bank.com

# Release build
flutter build appbundle --flavor prod \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=API_URL=https://api.bank.com \
  --obfuscate --split-debug-info=build/debug-info
```

### Flavor Configuration in Dart

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://dev-api.bank.com');

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';
}
```

---

## §Required-Packages

### Bank-Approved Package List

```yaml
# pubspec.yaml — dependencies
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0

  # Navigation
  go_router: ^14.0.0

  # Networking
  dio: ^5.4.0

  # Dependency Injection
  get_it: ^8.0.0

  # Security
  flutter_secure_storage: ^9.2.0
  local_auth: ^2.2.0

  # Code Generation (runtime)
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.0

  # Localization
  intl: ^0.19.0

  # Crash Reporting
  firebase_core: ^3.0.0
  firebase_crashlytics: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Testing
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  golden_toolkit: ^0.15.0

  # Code Generation (build time)
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
  freezed: ^2.5.0

  # Analysis
  very_good_analysis: ^6.0.0
```

---

## §Pubspec-Config

### pubspec.yaml Template

```yaml
name: bank_app
description: National Bank mobile application
version: 1.0.0+1
publish_to: none

environment:
  sdk: ">=3.2.0 <4.0.0"
  flutter: ">=3.16.0"

# ... dependencies as listed in §Required-Packages

flutter:
  generate: true  # ARB code generation
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  fonts:
    - family: BankSans
      fonts:
        - asset: assets/fonts/BankSans-Regular.ttf
        - asset: assets/fonts/BankSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/BankSans-Bold.ttf
          weight: 700
```

---

## §Platform-Config

### Android Minimum Configuration

| Setting | Value | Reason |
|---|---|---|
| `minSdkVersion` | 24 (Android 7.0) | EncryptedSharedPreferences, BiometricPrompt |
| `targetSdkVersion` | 34 (Android 14) | Latest security patches |
| `compileSdkVersion` | 34 | Required for target 34 |
| Network security | cleartext disabled | HTTPS only |
| Backup rules | `android:allowBackup="false"` | Prevent data extraction |

### iOS Minimum Configuration

| Setting | Value | Reason |
|---|---|---|
| Deployment target | 15.0 | Modern security APIs, latest widgets |
| Bitcode | Disabled (Flutter default) | Flutter does not support bitcode |
| ATS | No arbitrary loads | HTTPS only |
| Face ID usage description | Required | Biometric prompt |

---

## §Build-Config

### build.yaml

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          field_rename: snake
          create_factory: true
          create_to_json: true
      freezed:
        options:
          union_key: runtimeType
```

### Code Generation Commands

```bash
# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

---

## §Signing

### Android Signing

```properties
# android/key.properties (NOT committed to VCS)
storePassword=<from-vault>
keyPassword=<from-vault>
keyAlias=bank-release
storeFile=../keystore/bank-release.jks
```

```groovy
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

### iOS Signing

| Environment | Profile Type | Certificate |
|---|---|---|
| Dev | Development | iOS Development |
| Staging | Ad Hoc | iOS Distribution |
| Prod | App Store | iOS Distribution |

### .gitignore Additions

```gitignore
# Signing
android/key.properties
android/keystore/
ios/Runner/Configs/*.local.xcconfig

# Generated
**/*.g.dart
**/*.freezed.dart
lib/l10n/gen/

# Build
build/
.dart_tool/
.packages

# IDE
.idea/
.vscode/
*.iml
```
