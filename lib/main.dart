name: Build Mobile Apps
on:
  push:
    branches: [ main ]
jobs:
  build-apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          flutter-version: '3.44.0'
      - name: Install Dependencies
        run: flutter pub get
      - name: Build APK
        run: flutter build apk --release --no-tree-shake-icons
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: SafeLive-APK
          path: build/app/outputs/flutter-apk/app-release.apk
