# CI/CD Flutter — Reference

## §GitHub-Actions

### Complete PR Check Workflow

```yaml
# .github/workflows/flutter_pr.yml
name: Flutter PR Check

on:
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    name: Analyze & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Check formatting
        run: dart format --set-exit-if-changed .

      - name: Analyze
        run: dart analyze --fatal-infos

      - name: Run tests with coverage
        run: flutter test --coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "::error::Coverage $COVERAGE% is below 80% threshold"
            exit 1
          fi

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/lcov.info

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
          channel: stable
          cache: true

      - name: Build APK (staging)
        run: |
          flutter build apk \
            --flavor staging \
            --dart-define=ENVIRONMENT=staging \
            --dart-define=API_URL=${{ vars.STAGING_API_URL }}

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: staging-apk
          path: build/app/outputs/flutter-apk/app-staging-release.apk

  build-ios:
    name: Build iOS
    runs-on: macos-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
          channel: stable
          cache: true

      - name: Build iOS (no codesign for PR check)
        run: |
          flutter build ios --no-codesign \
            --flavor staging \
            --dart-define=ENVIRONMENT=staging \
            --dart-define=API_URL=${{ vars.STAGING_API_URL }}
```

---

## §Test-Gate

### Test Workflow Details

```yaml
- name: Run unit and widget tests
  run: flutter test --coverage --reporter=github

- name: Run golden tests
  run: flutter test --tags golden

- name: Exclude generated code from coverage
  run: |
    lcov --remove coverage/lcov.info \
      '*.g.dart' \
      '*.freezed.dart' \
      '*/l10n/*' \
      '*/generated/*' \
      -o coverage/lcov_cleaned.info

- name: Enforce coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov_cleaned.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
    echo "Cleaned coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "::error::Coverage $COVERAGE% below 80%"
      exit 1
    fi
```

### Integration Test Job

```yaml
integration-test:
  name: Integration Tests
  runs-on: macos-latest
  needs: analyze
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: "3.24.0"
        channel: stable

    - name: Boot iOS Simulator
      run: |
        DEVICE_ID=$(xcrun simctl list devices available -j | jq -r '.devices | to_entries[] | .value[] | select(.name=="iPhone 15") | .udid' | head -1)
        xcrun simctl boot "$DEVICE_ID"

    - name: Run integration tests
      run: flutter test integration_test/ -d "$DEVICE_ID"
```

---

## §Analysis-Gate

### Static Analysis Steps

```yaml
- name: Dart analyze (strict)
  run: dart analyze --fatal-infos --fatal-warnings

- name: Check for banned imports
  run: |
    # Ensure domain layer has no Flutter imports
    if grep -r "package:flutter" lib/features/*/domain/; then
      echo "::error::Domain layer must not import Flutter"
      exit 1
    fi

- name: Check for print statements
  run: |
    if grep -rn "print(" lib/ --include="*.dart" | grep -v "debugPrint" | grep -v "//"; then
      echo "::error::Use debugPrint() or logger instead of print()"
      exit 1
    fi
```

---

## §Build-Config

### Multi-Flavor Build Matrix

```yaml
build-release:
  strategy:
    matrix:
      flavor: [dev, staging, prod]
      platform: [android, ios]
      exclude:
        - flavor: dev
          platform: ios  # Skip dev iOS builds in CI

  steps:
    - name: Build ${{ matrix.platform }} (${{ matrix.flavor }})
      run: |
        if [ "${{ matrix.platform }}" = "android" ]; then
          flutter build appbundle \
            --flavor ${{ matrix.flavor }} \
            --release \
            --obfuscate \
            --split-debug-info=build/symbols/${{ matrix.flavor }} \
            --dart-define=ENVIRONMENT=${{ matrix.flavor }} \
            --dart-define=API_URL=${{ vars[format('{0}_API_URL', matrix.flavor)] }}
        else
          flutter build ipa \
            --flavor ${{ matrix.flavor }} \
            --release \
            --obfuscate \
            --split-debug-info=build/symbols/${{ matrix.flavor }} \
            --dart-define=ENVIRONMENT=${{ matrix.flavor }} \
            --dart-define=API_URL=${{ vars[format('{0}_API_URL', matrix.flavor)] }}
        fi
```

---

## §Signing

### Android Signing in CI

```yaml
- name: Decode Android keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

- name: Create key.properties
  run: |
    cat > android/key.properties <<EOF
    storeFile=keystore.jks
    storePassword=${{ secrets.KEYSTORE_PASSWORD }}
    keyAlias=${{ secrets.KEY_ALIAS }}
    keyPassword=${{ secrets.KEY_PASSWORD }}
    EOF
```

### iOS Signing in CI

```yaml
- name: Install Apple certificate and provisioning profile
  env:
    P12_CERT_BASE64: ${{ secrets.IOS_P12_CERT_BASE64 }}
    P12_PASSWORD: ${{ secrets.IOS_P12_PASSWORD }}
    PROVISION_PROFILE_BASE64: ${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}
  run: |
    # Create keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    security create-keychain -p "" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "" $KEYCHAIN_PATH

    # Import certificate
    echo "$P12_CERT_BASE64" | base64 --decode > certificate.p12
    security import certificate.p12 -k $KEYCHAIN_PATH -P "$P12_PASSWORD" -T /usr/bin/codesign
    security list-keychains -d user -s $KEYCHAIN_PATH

    # Install provisioning profile
    echo "$PROVISION_PROFILE_BASE64" | base64 --decode > profile.mobileprovision
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/

- name: Build signed IPA
  run: |
    flutter build ipa \
      --flavor prod \
      --release \
      --obfuscate \
      --split-debug-info=build/symbols/ios \
      --export-options-plist=ios/ExportOptions.plist
```

---

## §Release-Build

### Release Build with Obfuscation

```yaml
- name: Build release Android
  run: |
    flutter build appbundle \
      --flavor prod \
      --release \
      --obfuscate \
      --split-debug-info=build/symbols/android \
      --dart-define=ENVIRONMENT=prod \
      --dart-define=API_URL=${{ vars.PROD_API_URL }} \
      --build-number=${{ github.run_number }}

- name: Build release iOS
  run: |
    flutter build ipa \
      --flavor prod \
      --release \
      --obfuscate \
      --split-debug-info=build/symbols/ios \
      --dart-define=ENVIRONMENT=prod \
      --dart-define=API_URL=${{ vars.PROD_API_URL }} \
      --build-number=${{ github.run_number }} \
      --export-options-plist=ios/ExportOptions.plist
```

---

## §Symbol-Upload

### Upload Debug Symbols to Crashlytics

```yaml
- name: Upload Android symbols
  run: |
    firebase crashlytics:symbols:upload \
      --app=${{ secrets.FIREBASE_ANDROID_APP_ID }} \
      build/symbols/android

- name: Upload iOS dSYM
  run: |
    firebase crashlytics:symbols:upload \
      --app=${{ secrets.FIREBASE_IOS_APP_ID }} \
      build/ios/archive/Runner.xcarchive/dSYMs
```

---

## §Artifacts

### Upload Build Artifacts

```yaml
- name: Upload Android artifacts
  uses: actions/upload-artifact@v4
  with:
    name: android-release-${{ github.run_number }}
    path: |
      build/app/outputs/bundle/prodRelease/app-prod-release.aab
      build/symbols/android/
    retention-days: 90

- name: Upload iOS artifacts
  uses: actions/upload-artifact@v4
  with:
    name: ios-release-${{ github.run_number }}
    path: |
      build/ios/ipa/*.ipa
      build/symbols/ios/
    retention-days: 90
```

---

## §Fastlane

### Android Fastlane Configuration

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to internal testing track"
  lane :internal do
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/prodRelease/app-prod-release.aab',
      json_key_data: ENV['PLAY_STORE_CONFIG_JSON'],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
    )
  end

  desc "Promote internal to production"
  lane :promote_to_production do
    upload_to_play_store(
      track: 'internal',
      track_promote_to: 'production',
      json_key_data: ENV['PLAY_STORE_CONFIG_JSON'],
      skip_upload_changelogs: false,
    )
  end
end
```

### iOS Fastlane Configuration

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Upload to TestFlight"
  lane :beta do
    api_key = app_store_connect_api_key(
      key_id: ENV['ASC_KEY_ID'],
      issuer_id: ENV['ASC_ISSUER_ID'],
      key_content: ENV['ASC_KEY_CONTENT'],
    )

    upload_to_testflight(
      api_key: api_key,
      ipa: '../build/ios/ipa/BankApp.ipa',
      skip_waiting_for_build_processing: true,
    )
  end

  desc "Submit for App Store review"
  lane :release do
    api_key = app_store_connect_api_key(
      key_id: ENV['ASC_KEY_ID'],
      issuer_id: ENV['ASC_ISSUER_ID'],
      key_content: ENV['ASC_KEY_CONTENT'],
    )

    deliver(
      api_key: api_key,
      submit_for_review: true,
      automatic_release: false,
      force: true,
      precheck_include_in_app_purchases: false,
    )
  end
end
```

### Fastlane CI Integration

```yaml
# In GitHub Actions
- name: Install Fastlane
  run: |
    gem install bundler
    cd android && bundle install
    cd ../ios && bundle install

- name: Deploy Android to internal testing
  run: cd android && bundle exec fastlane internal
  env:
    PLAY_STORE_CONFIG_JSON: ${{ secrets.PLAY_STORE_CONFIG_JSON }}

- name: Deploy iOS to TestFlight
  run: cd ios && bundle exec fastlane beta
  env:
    ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
    ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
    ASC_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
```

### Pipeline Summary

| Stage | Trigger | Actions |
|---|---|---|
| PR Check | Pull request | Format, analyze, test, coverage, build (no sign) |
| Staging Deploy | Merge to `develop` | Test, build staging flavor, sign, deploy to internal |
| Production Build | Merge to `main` | Test, build prod flavor, sign, upload symbols |
| Production Deploy | Manual approval | Fastlane promote to production / App Store |
