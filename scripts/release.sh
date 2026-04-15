#!/bin/bash
# Usage: ./scripts/release.sh 1.0.0

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

APP_NAME="GridPoint"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo "▶ Building ${APP_NAME} v${VERSION}..."
xcodebuild -scheme "$APP_NAME" -configuration Release \
  -archivePath "build/${APP_NAME}.xcarchive" archive

echo "▶ Creating zip..."
cd "build/${APP_NAME}.xcarchive/Products/Applications"
zip -r "../../../../${ZIP_NAME}" "${APP_NAME}.app"
cd -

echo "▶ SHA256:"
SHA=$(shasum -a 256 "$ZIP_NAME" | awk '{print $1}')
echo "$SHA"

echo ""
echo "Done: ${ZIP_NAME}"
echo ""
echo "Next steps:"
echo "1. Upload ${ZIP_NAME} to GitHub Releases"
echo "2. Put the SHA256 below into the Cask file:"
echo "   sha256 \"${SHA}\""
