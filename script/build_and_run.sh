#!/usr/bin/env bash
set -euo pipefail

MODE="run"
if [[ $# -gt 0 && "$1" != "--arch" ]]; then
  MODE="$1"
  shift
fi

ARCHITECTURE="${ARCHITECTURE:-$(uname -m)}"
if [[ $# -gt 0 ]]; then
  if [[ "$1" != "--arch" || $# -ne 2 ]]; then
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--release-app] [--arch arm64|x86_64]" >&2
    exit 2
  fi
  ARCHITECTURE="$2"
fi

case "$ARCHITECTURE" in
  arm64|x86_64)
    ;;
  *)
    echo "unsupported architecture: $ARCHITECTURE (expected arm64 or x86_64)" >&2
    exit 2
    ;;
esac
APP_NAME="MacBookPet"
DISPLAY_NAME="CubePet"
BUNDLE_ID="com.susunext.MacBookPet"
APP_VERSION="1.0.0"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/$ARCHITECTURE"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/MacBookPet.icns"
STATUS_ICON="$ROOT_DIR/Assets/CubePetStatusIcon.png"
FROG_PET_IMAGE="$ROOT_DIR/Assets/FrogPet.png"
FROG_LARGE_MOUTH_IMAGE="$ROOT_DIR/Assets/FrogPetMouthLarge.png"
CAT_PET_IMAGE="$ROOT_DIR/Assets/CatPetFaceless.png"
CAT_LARGE_MOUTH_IMAGE="$ROOT_DIR/Assets/CatPetMouthLarge.png"
CAT_CURLED_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetCurledSleeping.png"
CAT_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetHungry.png"
CAT_GRAY_PET_IMAGE="$ROOT_DIR/Assets/CatPetGrayFaceless.png"
CAT_GRAY_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetGrayHungry.png"
CAT_GRAY_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetGraySleeping.png"
CAT_GRAY_LARGE_MOUTH_IMAGE="$ROOT_DIR/Assets/CatPetGrayMouthLarge.png"
CAT_CALICO_PET_IMAGE="$ROOT_DIR/Assets/CatPetCalicoFaceless.png"
CAT_CALICO_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetCalicoSleeping.png"
CAT_CALICO_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetCalicoHungry.png"
CAT_CALICO_LARGE_MOUTH_IMAGE="$ROOT_DIR/Assets/CatPetCalicoMouthLarge.png"
CAT_CALICO_MOUTH_ONLY_IMAGE="$ROOT_DIR/Assets/CatPetCalicoMouthOnly.png"
CAT_BLACK_PET_IMAGE="$ROOT_DIR/Assets/CatPetBlackFaceless.png"
CAT_BLACK_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetBlackSleeping.png"
CAT_BLACK_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetBlackHungry.png"
CAT_BLACK_LARGE_MOUTH_IMAGE="$ROOT_DIR/Assets/CatPetBlackMouthLarge.png"
CAT_SIAMESE_PET_IMAGE="$ROOT_DIR/Assets/CatPetSiameseFaceless.png"
CAT_SIAMESE_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetSiameseSleeping.png"
CAT_SIAMESE_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetSiameseHungry.png"
CAT_SIAMESE_MOUTH_IMAGE="$ROOT_DIR/Assets/CatPetSiameseMouthUnique.png"
CAT_YELLOW_IMAGE="$ROOT_DIR/Assets/CatPetYellowFaceless.png"
CAT_YELLOW_HAPPY_IMAGE="$ROOT_DIR/Assets/CatPetYellowHappy.png"
CAT_YELLOW_SCARED_IMAGE="$ROOT_DIR/Assets/CatPetYellowScared.png"
CAT_YELLOW_SLEEPING_IMAGE="$ROOT_DIR/Assets/CatPetYellowSleeping.png"
CAT_YELLOW_EATING_IMAGE="$ROOT_DIR/Assets/CatPetYellowEatingOfficial689cdacb.png"
CAT_YELLOW_HUNGRY_IMAGE="$ROOT_DIR/Assets/CatPetYellowHungry.png"
SHIBA_WATERCOLOR_EYE_OPEN_IMAGE="$ROOT_DIR/Assets/ShibaInuWatercolorEyeOpen.png"
SHIBA_WATERCOLOR_EYE_CLOSED_IMAGE="$ROOT_DIR/Assets/ShibaInuWatercolorEyeClosed.png"
SHIBA_PET_IMAGE="$ROOT_DIR/Assets/ShibaPet.png"
SHIBA_PET_HAPPY_IMAGE="$ROOT_DIR/Assets/ShibaPetHappy.png"
SHIBA_PET_SCARED_IMAGE="$ROOT_DIR/Assets/ShibaPetScaredApproved.png"
SHIBA_PET_EATING_IMAGE="$ROOT_DIR/Assets/ShibaPetEating.png"
SHIBA_PET_HUNGRY_IMAGE="$ROOT_DIR/Assets/ShibaPetHungry.png"
SHIBA_PET_SLEEPING_IMAGE="$ROOT_DIR/Assets/ShibaPetSleeping.png"
NETEASE_MUSIC_PERMISSION_ICON="$ROOT_DIR/Assets/NetEaseMusicPermissionIcon.png"
QQ_MUSIC_PERMISSION_ICON="$ROOT_DIR/Assets/QQMusicPermissionIcon.png"
KUGOU_MUSIC_PERMISSION_ICON="$ROOT_DIR/Assets/KuGouMusicPermissionIcon.png"
BEAGLE_PET_NORMAL_IMAGE="$ROOT_DIR/Assets/BeaglePetNormal.png"
BEAGLE_PET_HAPPY_IMAGE="$ROOT_DIR/Assets/BeaglePetHappy.png"
BEAGLE_PET_SCARED_IMAGE="$ROOT_DIR/Assets/BeaglePetScared.png"
BEAGLE_PET_EATING_IMAGE="$ROOT_DIR/Assets/BeaglePetEating.png"
BEAGLE_PET_HUNGRY_IMAGE="$ROOT_DIR/Assets/BeaglePetHungry.png"
BEAGLE_PET_SLEEPING_IMAGE="$ROOT_DIR/Assets/BeaglePetSleeping.png"
COOKIE_PET_IMAGE="$ROOT_DIR/Assets/CookiePetFaceless.png"
COOKIE_BLACK_BEAN_EYE_IMAGE="$ROOT_DIR/Assets/CookieBlackBeanEye.png"
CUBE_SKIN_ICE2_IMAGE="$ROOT_DIR/Assets/CubeSkinIce2.png"
CUBE_SKIN_RAINBOW2_IMAGE="$ROOT_DIR/Assets/CubeSkinRainbow2.png"
PET_COLA_IMAGE="$ROOT_DIR/Assets/PetCola.png"
FISH_SHAPED_PASTRY_IMAGE="$ROOT_DIR/Assets/FishShapedPastry.png"
PUDDING_CUP_IMAGE="$ROOT_DIR/Assets/PuddingCup.png"
THREE_COLOR_DANGO_IMAGE="$ROOT_DIR/Assets/ThreeColorDango.png"
PET_MENU_BACKGROUND_IMAGE="$ROOT_DIR/Assets/PetMenuBackground.jpg"
PET_MENU_HAND_DRAWN_BUTTON_IMAGE="$ROOT_DIR/Assets/PetMenuHandDrawnButton.png"
PET_MENU_HAND_DRAWN_CARD_IMAGE="$ROOT_DIR/Assets/PetMenuHandDrawnCard.png"
MY_PETS_COLLECTION_CARD_IMAGE="$ROOT_DIR/Assets/MyPetsCollectionCard.png"
PET_NECK_SCARF_IMAGE="$ROOT_DIR/Assets/PetNeckScarf.png"
PET_NECK_SCARF_MUSHROOM_IMAGE="$ROOT_DIR/Assets/PetNeckScarfMushroom.png"
PET_NECK_SCARF_FLOWER_PLAID_IMAGE="$ROOT_DIR/Assets/PetNeckScarfFlowerPlaid.png"
PET_NECK_SCARF_BLUE_STRIPE_IMAGE="$ROOT_DIR/Assets/PetNeckScarfBlueStripe.png"
PET_NECK_SCARF_CREAM_FLOWER_IMAGE="$ROOT_DIR/Assets/PetNeckScarfCreamFlower.png"
PET_NECK_SCARF_STAR_TASSEL_IMAGE="$ROOT_DIR/Assets/PetNeckScarfStarTassel.png"
PET_NECK_SCARF_RED_STRIPE_IMAGE="$ROOT_DIR/Assets/PetNeckScarfRedStripe.png"
PET_NECK_SCARF_RUST_KNIT_IMAGE="$ROOT_DIR/Assets/PetNeckScarfRustKnit.png"
PET_NECK_SCARF_COLORFUL_POLKA_DOT_IMAGE="$ROOT_DIR/Assets/PetNeckScarfColorfulPolkaDot.png"
PET_NECK_SCARF_KOI_WAVE_IMAGE="$ROOT_DIR/Assets/PetNeckScarfKoiWave.png"
PET_NECK_SCARF_ROCK_LIGHTNING_IMAGE="$ROOT_DIR/Assets/PetNeckScarfRockLightning.png"
PET_NECK_SCARF_LEMON_LACE_IMAGE="$ROOT_DIR/Assets/PetNeckScarfLemonLace.png"
PET_NECK_SCARF_GALAXY_IMAGE="$ROOT_DIR/Assets/PetNeckScarfGalaxy.png"
PET_NECK_SCARF_RAINBOW_POM_POM_IMAGE="$ROOT_DIR/Assets/PetNeckScarfRainbowPomPom.png"
PET_NECK_SCARF_AUTUMN_PLAID_IMAGE="$ROOT_DIR/Assets/PetNeckScarfAutumnPlaid.png"
PET_NECK_SCARF_ACORN_ARGYLE_IMAGE="$ROOT_DIR/Assets/PetNeckScarfAcornArgyle.png"
PET_NECK_SCARF_STRAWBERRY_HEART_IMAGE="$ROOT_DIR/Assets/PetNeckScarfStrawberryHeart.png"
PET_HEAD_PAW_BASEBALL_CAP_IMAGE="$ROOT_DIR/Assets/PetHeadPawBaseballCap.png"
PET_HEAD_AVIATOR_CAP_IMAGE="$ROOT_DIR/Assets/PetHeadAviatorCap.png"
PET_HEAD_LEAF_NEWSBOY_CAP_IMAGE="$ROOT_DIR/Assets/PetHeadLeafNewsboyCap.png"

BUILD_CONFIGURATION="debug"
if [[ "$MODE" == "--release-app" || "$MODE" == "release-app" ]]; then
  BUILD_CONFIGURATION="release"
fi

# Keep local builds independent from an unlicensed full Xcode installation.
# Callers can still override this explicitly when they need another toolchain.
if [[ -z "${DEVELOPER_DIR:-}" && -d "/Library/Developer/CommandLineTools" ]]; then
  export DEVELOPER_DIR="/Library/Developer/CommandLineTools"
fi

# The currently selected Command Line Tools can expose a newer default SDK
# whose Swift module version does not match its compiler. Prefer the installed
# 15.4 SDK for this macOS 14+ app when no SDK has been selected explicitly.
COMPATIBLE_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ -z "${SDKROOT:-}" && -d "$COMPATIBLE_SDK" ]]; then
  export SDKROOT="$COMPATIBLE_SDK"
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT_DIR/.build/swiftpm-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFTPM_MODULECACHE_OVERRIDE"

if [[ "$MODE" != "--release-app" && "$MODE" != "release-app" ]]; then
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi

swift build -c "$BUILD_CONFIGURATION" --arch "$ARCHITECTURE"
BUILD_BINARY="$(swift build -c "$BUILD_CONFIGURATION" --arch "$ARCHITECTURE" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/MacBookPet.icns"
cp "$STATUS_ICON" "$APP_RESOURCES/CubePetStatusIcon.png"
cp "$FROG_PET_IMAGE" "$APP_RESOURCES/FrogPet.png"
cp "$FROG_LARGE_MOUTH_IMAGE" "$APP_RESOURCES/FrogPetMouthLarge.png"
cp "$CAT_PET_IMAGE" "$APP_RESOURCES/CatPet.png"
cp "$CAT_LARGE_MOUTH_IMAGE" "$APP_RESOURCES/CatPetMouthLarge.png"
cp "$CAT_CURLED_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetCurledSleeping.png"
cp "$CAT_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetHungry.png"
cp "$CAT_GRAY_PET_IMAGE" "$APP_RESOURCES/CatPetGrayFaceless.png"
cp "$CAT_GRAY_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetGrayHungry.png"
cp "$CAT_GRAY_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetGraySleeping.png"
cp "$CAT_GRAY_LARGE_MOUTH_IMAGE" "$APP_RESOURCES/CatPetGrayMouthLarge.png"
cp "$CAT_CALICO_PET_IMAGE" "$APP_RESOURCES/CatPetCalicoFaceless.png"
cp "$CAT_CALICO_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetCalicoSleeping.png"
cp "$CAT_CALICO_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetCalicoHungry.png"
cp "$CAT_CALICO_LARGE_MOUTH_IMAGE" "$APP_RESOURCES/CatPetCalicoMouthLarge.png"
cp "$CAT_CALICO_MOUTH_ONLY_IMAGE" "$APP_RESOURCES/CatPetCalicoMouthOnly.png"
cp "$CAT_BLACK_PET_IMAGE" "$APP_RESOURCES/CatPetBlackFaceless.png"
cp "$CAT_BLACK_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetBlackSleeping.png"
cp "$CAT_BLACK_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetBlackHungry.png"
cp "$CAT_BLACK_LARGE_MOUTH_IMAGE" "$APP_RESOURCES/CatPetBlackMouthLarge.png"
cp "$CAT_SIAMESE_PET_IMAGE" "$APP_RESOURCES/CatPetSiameseFaceless.png"
cp "$CAT_SIAMESE_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetSiameseSleeping.png"
cp "$CAT_SIAMESE_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetSiameseHungry.png"
cp "$CAT_SIAMESE_MOUTH_IMAGE" "$APP_RESOURCES/CatPetSiameseMouthUnique.png"
cp "$CAT_YELLOW_IMAGE" "$APP_RESOURCES/CatPetYellowFaceless.png"
cp "$CAT_YELLOW_HAPPY_IMAGE" "$APP_RESOURCES/CatPetYellowHappy.png"
cp "$CAT_YELLOW_SCARED_IMAGE" "$APP_RESOURCES/CatPetYellowScared.png"
cp "$CAT_YELLOW_SLEEPING_IMAGE" "$APP_RESOURCES/CatPetYellowSleeping.png"
cp "$CAT_YELLOW_EATING_IMAGE" "$APP_RESOURCES/CatPetYellowEatingOfficial689cdacb.png"
cp "$CAT_YELLOW_HUNGRY_IMAGE" "$APP_RESOURCES/CatPetYellowHungry.png"
cp "$SHIBA_WATERCOLOR_EYE_OPEN_IMAGE" "$APP_RESOURCES/ShibaInuWatercolorEyeOpen.png"
cp "$SHIBA_WATERCOLOR_EYE_CLOSED_IMAGE" "$APP_RESOURCES/ShibaInuWatercolorEyeClosed.png"
cp "$SHIBA_PET_IMAGE" "$APP_RESOURCES/ShibaPet.png"
cp "$SHIBA_PET_HAPPY_IMAGE" "$APP_RESOURCES/ShibaPetHappy.png"
cp "$SHIBA_PET_SCARED_IMAGE" "$APP_RESOURCES/ShibaPetScaredApproved.png"
cp "$SHIBA_PET_EATING_IMAGE" "$APP_RESOURCES/ShibaPetEating.png"
cp "$SHIBA_PET_HUNGRY_IMAGE" "$APP_RESOURCES/ShibaPetHungry.png"
cp "$SHIBA_PET_SLEEPING_IMAGE" "$APP_RESOURCES/ShibaPetSleeping.png"
cp "$NETEASE_MUSIC_PERMISSION_ICON" "$APP_RESOURCES/NetEaseMusicPermissionIcon.png"
cp "$QQ_MUSIC_PERMISSION_ICON" "$APP_RESOURCES/QQMusicPermissionIcon.png"
cp "$KUGOU_MUSIC_PERMISSION_ICON" "$APP_RESOURCES/KuGouMusicPermissionIcon.png"
cp "$BEAGLE_PET_NORMAL_IMAGE" "$APP_RESOURCES/BeaglePetNormal.png"
cp "$BEAGLE_PET_HAPPY_IMAGE" "$APP_RESOURCES/BeaglePetHappy.png"
cp "$BEAGLE_PET_SCARED_IMAGE" "$APP_RESOURCES/BeaglePetScared.png"
cp "$BEAGLE_PET_EATING_IMAGE" "$APP_RESOURCES/BeaglePetEating.png"
cp "$BEAGLE_PET_HUNGRY_IMAGE" "$APP_RESOURCES/BeaglePetHungry.png"
cp "$BEAGLE_PET_SLEEPING_IMAGE" "$APP_RESOURCES/BeaglePetSleeping.png"
cp "$COOKIE_PET_IMAGE" "$APP_RESOURCES/CookiePetFaceless.png"
cp "$COOKIE_BLACK_BEAN_EYE_IMAGE" "$APP_RESOURCES/CookieBlackBeanEye.png"
cp "$CUBE_SKIN_ICE2_IMAGE" "$APP_RESOURCES/CubeSkinIce2.png"
cp "$CUBE_SKIN_RAINBOW2_IMAGE" "$APP_RESOURCES/CubeSkinRainbow2.png"
cp "$PET_COLA_IMAGE" "$APP_RESOURCES/PetCola.png"
cp "$FISH_SHAPED_PASTRY_IMAGE" "$APP_RESOURCES/FishShapedPastry.png"
cp "$PUDDING_CUP_IMAGE" "$APP_RESOURCES/PuddingCup.png"
cp "$THREE_COLOR_DANGO_IMAGE" "$APP_RESOURCES/ThreeColorDango.png"
cp "$PET_MENU_BACKGROUND_IMAGE" "$APP_RESOURCES/PetMenuBackground.jpg"
cp "$PET_MENU_HAND_DRAWN_BUTTON_IMAGE" "$APP_RESOURCES/PetMenuHandDrawnButton.png"
cp "$PET_MENU_HAND_DRAWN_CARD_IMAGE" "$APP_RESOURCES/PetMenuHandDrawnCard.png"
cp "$MY_PETS_COLLECTION_CARD_IMAGE" "$APP_RESOURCES/MyPetsCollectionCard.png"
cp "$PET_NECK_SCARF_IMAGE" "$APP_RESOURCES/PetNeckScarf.png"
cp "$PET_NECK_SCARF_MUSHROOM_IMAGE" "$APP_RESOURCES/PetNeckScarfMushroom.png"
cp "$PET_NECK_SCARF_FLOWER_PLAID_IMAGE" "$APP_RESOURCES/PetNeckScarfFlowerPlaid.png"
cp "$PET_NECK_SCARF_BLUE_STRIPE_IMAGE" "$APP_RESOURCES/PetNeckScarfBlueStripe.png"
cp "$PET_NECK_SCARF_CREAM_FLOWER_IMAGE" "$APP_RESOURCES/PetNeckScarfCreamFlower.png"
cp "$PET_NECK_SCARF_STAR_TASSEL_IMAGE" "$APP_RESOURCES/PetNeckScarfStarTassel.png"
cp "$PET_NECK_SCARF_RED_STRIPE_IMAGE" "$APP_RESOURCES/PetNeckScarfRedStripe.png"
cp "$PET_NECK_SCARF_RUST_KNIT_IMAGE" "$APP_RESOURCES/PetNeckScarfRustKnit.png"
cp "$PET_NECK_SCARF_COLORFUL_POLKA_DOT_IMAGE" "$APP_RESOURCES/PetNeckScarfColorfulPolkaDot.png"
cp "$PET_NECK_SCARF_KOI_WAVE_IMAGE" "$APP_RESOURCES/PetNeckScarfKoiWave.png"
cp "$PET_NECK_SCARF_ROCK_LIGHTNING_IMAGE" "$APP_RESOURCES/PetNeckScarfRockLightning.png"
cp "$PET_NECK_SCARF_LEMON_LACE_IMAGE" "$APP_RESOURCES/PetNeckScarfLemonLace.png"
cp "$PET_NECK_SCARF_GALAXY_IMAGE" "$APP_RESOURCES/PetNeckScarfGalaxy.png"
cp "$PET_NECK_SCARF_RAINBOW_POM_POM_IMAGE" "$APP_RESOURCES/PetNeckScarfRainbowPomPom.png"
cp "$PET_NECK_SCARF_AUTUMN_PLAID_IMAGE" "$APP_RESOURCES/PetNeckScarfAutumnPlaid.png"
cp "$PET_NECK_SCARF_ACORN_ARGYLE_IMAGE" "$APP_RESOURCES/PetNeckScarfAcornArgyle.png"
cp "$PET_NECK_SCARF_STRAWBERRY_HEART_IMAGE" "$APP_RESOURCES/PetNeckScarfStrawberryHeart.png"
cp "$PET_HEAD_PAW_BASEBALL_CAP_IMAGE" "$APP_RESOURCES/PetHeadPawBaseballCap.png"
cp "$PET_HEAD_AVIATOR_CAP_IMAGE" "$APP_RESOURCES/PetHeadAviatorCap.png"
cp "$PET_HEAD_LEAF_NEWSBOY_CAP_IMAGE" "$APP_RESOURCES/PetHeadLeafNewsboyCap.png"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>CFBundleIconFile</key>
  <string>MacBookPet.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSInputMonitoringUsageDescription</key>
  <string>MacBookPet uses input monitoring to release the desktop pet immediately when you stop dragging it.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>MacBookPet checks whether Music, NetEase Music, QQ Music, or KuGou Music is playing so the pet can react to your music.</string>
  <key>UTExportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeIdentifier</key>
      <string>com.susunext.macbookpet.food</string>
      <key>UTTypeConformsTo</key>
      <array>
        <string>public.data</string>
      </array>
      <key>UTTypeDescription</key>
      <string>CubePet Food</string>
      <key>UTTypeTagSpecification</key>
      <dict>
        <key>public.filename-extension</key>
        <array>
          <string>mbpetfood</string>
        </array>
      </dict>
    </dict>
  </array>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --release-app|release-app)
    echo "$APP_BUNDLE"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--release-app] [--arch arm64|x86_64]" >&2
    exit 2
    ;;
esac
