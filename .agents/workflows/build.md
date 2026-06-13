---
description: Build a split-ABI APK for minimal size and install it to the device via adb wireless debugging.
---
When the user executes `/build` or starts their request with `/build`:
1. Run `flutter build apk --split-per-abi` in the project root to compile optimized, small-size APKs.
2. Check for connected adb devices by running `adb devices`.
3. If no devices are connected:
   - Ask the user to provide the **Device Port**, **Pairing Port**, and **Pairing Code** for IP `192.168.0.150`.
   - Run `adb pair 192.168.0.150:<Pairing Port> <Pairing Code>`.
   - Run `adb connect 192.168.0.150:<Device Port>`.
4. Once connected, install the compiled arm64 release APK (`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`) by running:
   - `adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
5. Report build size details and successful deployment status.
