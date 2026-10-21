#!/bin/bash
#
# Builds IssuerProvisioningKit.xcframework for iOS devices and the iOS Simulator.
#
# Usage:   ./scripts/build-xcframework.sh
# Signing: SIGNING_IDENTITY="Apple Distribution: Name (TEAMID)" ./scripts/build-xcframework.sh
#
# Can be run from any folder. Output: build/IssuerProvisioningKit.xcframework

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/IssuerProvisioningKit.xcodeproj"
SCHEME="IssuerProvisioningKit"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVES_DIR="$BUILD_DIR/archives"
XCFRAMEWORK="$BUILD_DIR/$SCHEME.xcframework"

archive() {
    local destination="$1"
    local archive_path="$2"

    echo "Archiving for $destination"
    # Library evolution keeps the binary usable with newer Swift compilers.
    # Left unsigned: the app embedding the framework signs it again anyway.
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "$destination" \
        -archivePath "$archive_path" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
}

rm -rf "$BUILD_DIR"

archive "generic/platform=iOS" "$ARCHIVES_DIR/ios"
archive "generic/platform=iOS Simulator" "$ARCHIVES_DIR/ios-simulator"

echo "Creating $SCHEME.xcframework"
# dSYMs are bundled so crashes inside the framework can be symbolicated.
xcodebuild -create-xcframework \
    -framework "$ARCHIVES_DIR/ios.xcarchive/Products/Library/Frameworks/$SCHEME.framework" \
    -debug-symbols "$ARCHIVES_DIR/ios.xcarchive/dSYMs/$SCHEME.framework.dSYM" \
    -framework "$ARCHIVES_DIR/ios-simulator.xcarchive/Products/Library/Frameworks/$SCHEME.framework" \
    -debug-symbols "$ARCHIVES_DIR/ios-simulator.xcarchive/dSYMs/$SCHEME.framework.dSYM" \
    -output "$XCFRAMEWORK"

# Xcode checks this signature when the framework is added to an app.
if [ -n "${SIGNING_IDENTITY:-}" ]; then
    echo "Signing with $SIGNING_IDENTITY"
    codesign --timestamp --sign "$SIGNING_IDENTITY" "$XCFRAMEWORK"
else
    echo "SIGNING_IDENTITY not set, the XCFramework is left unsigned"
fi

rm -rf "$ARCHIVES_DIR"
echo "Done: $XCFRAMEWORK"
