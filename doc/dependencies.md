# Dependencies

## pubspec.yaml

```yaml
name: sync_app
description: Local-first Flutter app with optional Google Drive sync
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
  equatable: ^2.0.5

  # Routing
  go_router: ^14.6.0

  # Networking
  dio: ^5.7.0

  # Local Storage
  objectbox: ^4.0.3
  objectbox_flutter_libs: ^4.0.3

  # Google Auth + Drive
  google_sign_in: ^6.2.2
  googleapis: ^13.2.0
  googleapis_auth: ^1.6.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.12

  # Storage
  shared_preferences: ^2.3.3
  flutter_secure_storage: ^9.2.2
  path_provider: ^2.1.5
  path: ^1.9.0

  # Utilities
  uuid: ^4.5.1
  get_it: ^8.0.2
  connectivity_plus: ^6.1.0
  intl: ^0.19.0
  logger: ^2.5.0

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  objectbox_generator: ^4.0.3
  mocktail: ^1.0.4
  bloc_test: ^9.1.7

flutter:
  uses-material-design: true
```

## Setup Commands

```bash
# Install dependencies
flutter pub get

# Generate ObjectBox files (run after defining/changing entities)
dart run build_runner build --delete-conflicting-outputs

# Run with verbose logging during development
flutter run --debug
```

## Platform Configuration

### Android (`android/app/build.gradle`)

```gradle
android {
    defaultConfig {
        minSdkVersion 23   // Required by ObjectBox + google_sign_in
        targetSdkVersion 34
    }
}
```

### iOS (`ios/Podfile`)

```ruby
platform :ios, '13.0'   # Required by googleapis
```

### iOS `Info.plist`

Add reversed OAuth client ID:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

## Google Cloud Console Setup

1. Create project at https://console.cloud.google.com
2. Enable **Google Drive API**
3. OAuth consent screen → External → add scope `.../auth/drive.appdata`
4. Credentials → Create OAuth client IDs:
   - Android: package name + SHA-1 (`./gradlew signingReport`)
   - iOS: bundle ID
   - Web (only if targeting web)
5. Download `google-services.json` → place in `android/app/`
6. Download `GoogleService-Info.plist` → place in `ios/Runner/`
