#!/bin/bash
# Builds the iOS app on a Mac with Xcode (and CMake 3.25+: `brew install cmake`).
#
#   ios/build.sh                 unsigned Oracles.ipa for SideStore / AltStore (they re-sign it)
#   ios/build.sh --team ABCDE12345   signed with your Apple ID's team, then install from Xcode
#   ios/build.sh --sim           a build for the iOS Simulator (Apple Silicon)
#   ios/build.sh --xcode         just generate build-ios/oracles.xcodeproj and open it
#
# Options can be combined with --bundle-id com.you.oracles (default dev.oracles-decomp.oracles).
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM=""; SIM=0; XCODE=0; BUNDLE_ID="dev.oracles-decomp.oracles"
while [ $# -gt 0 ]; do
  case "$1" in
    --team) TEAM="$2"; shift 2 ;;
    --sim) SIM=1; shift ;;
    --xcode) XCODE=1; shift ;;
    --bundle-id) BUNDLE_ID="$2"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

command -v cmake >/dev/null || { echo "CMake not found: brew install cmake" >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode not found" >&2; exit 1; }

BUILD=build-ios
EXTRA=()
[ -n "$TEAM" ] && EXTRA+=(-DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="$TEAM" -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE=Automatic)

cmake -S . -B "$BUILD" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DORACLES_IOS_BUNDLE_ID="$BUNDLE_ID" \
  ${EXTRA[@]+"${EXTRA[@]}"}

if [ "$XCODE" = 1 ]; then
  open "$BUILD/oracles.xcodeproj"
  echo "Pick the oracles-ios scheme, set your team under Signing & Capabilities, and run on your device."
  exit 0
fi

if [ "$SIM" = 1 ]; then
  xcodebuild -project "$BUILD/oracles.xcodeproj" -target oracles-ios -configuration Release \
    -sdk iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO -quiet build
  APP=$(find "$BUILD" -maxdepth 3 -path "*Release-iphonesimulator/Oracles.app" | head -1)
  echo "Simulator app: $APP"
  echo "Install: xcrun simctl install booted \"$APP\""
  exit 0
fi

SIGN=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="")
[ -n "$TEAM" ] && SIGN=(-allowProvisioningUpdates)
xcodebuild -project "$BUILD/oracles.xcodeproj" -target oracles-ios -configuration Release \
  -sdk iphoneos ARCHS=arm64 "${SIGN[@]}" -quiet build

APP=$(find "$BUILD" -maxdepth 3 -path "*Release-iphoneos/Oracles.app" | head -1)
[ -d "$APP" ] || { echo "build produced no Oracles.app" >&2; exit 1; }

rm -rf "$BUILD/Payload" Oracles.ipa
mkdir -p "$BUILD/Payload"
cp -R "$APP" "$BUILD/Payload/"
(cd "$BUILD" && zip -qry ../Oracles.ipa Payload)
echo
echo "Built $(pwd)/Oracles.ipa"
if [ -z "$TEAM" ]; then
  echo "Unsigned: open it in SideStore / AltStore (or AirDrop it to the phone) to sign and install."
fi
