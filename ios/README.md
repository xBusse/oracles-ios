# Oracles on iOS

The same native app as the Android build (SDL3, touch overlay, menus, mods, save sync), as an iOS
app bundle. No JIT and no executable memory: the game is compiled C, so it runs from a normal
sideload with no extra entitlements.

## Build (on a Mac with Xcode)

```sh
brew install cmake            # 3.25 or newer
ios/build.sh                  # → Oracles.ipa (unsigned, for SideStore / AltStore)
```

Other ways to build:

| Command | What you get |
| --- | --- |
| `ios/build.sh --team ABCDE12345` | signed with your team, ready to install from Xcode |
| `ios/build.sh --xcode` | generates `build-ios/oracles.xcodeproj` and opens it (scheme `oracles-ios`) |
| `ios/build.sh --sim` | an iOS Simulator build |
| `--bundle-id com.you.oracles` | add to any of the above |

The first configure downloads SDL 3.4.16 and builds it from source for iOS.

## First launch

The app asks for a ROM — *The Legend of Zelda: Oracle of Ages* and/or *Oracle of Seasons* (USA,
`.gbc`, `.zip`, `.gz`). The Files picker opens; choose it from iCloud Drive, On My iPhone, etc.
The app extracts what it needs and never needs the ROM again. Add the other game the same way from
the home screen.

## Files

Everything the app keeps (saves, save states, mods, extracted assets, settings) is in its
Documents folder, visible in **Files → On My iPhone → Oracles**. Back that folder up to keep your
saves across reinstalls; drop mod folders into `mods/` there.

## What differs from desktop

- Fullscreen only, touch overlay on, landscape and portrait (as on Android).
- Haptics on overlay presses use the Taptic Engine.
- Save sync works (NSURLSession instead of libcurl).
- No update check — a sideloaded build updates by rebuilding.
- Controllers (MFi, Xbox, DualSense) work through SDL's gamepad support.

## What changed in the source

- `CMakeLists.txt` — `if(IOS)` target `oracles-ios`; desktop tools and tests are skipped for iOS.
- `src/platform/mobile.h` — `ORACLES_MOBILE` (Android or iOS) and `ORACLES_IOS`.
- `src/platform/ios_glue.{h,m}` — document picker, Documents folder, haptics.
- `src/sync/http_apple.m` — the HTTP backend for sync.
- `src/platform/app.c`, `src/platform/haptic.c` — phone checks now use `ORACLES_MOBILE`.
- `ios/` — Info.plist, icons, build script.
