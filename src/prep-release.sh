#!/bin/bash

### Prepares the application for a GitHub Release

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="${DIR}/${PROJECT_NAME}/application.macosx"
PROJECT_NAME="photon_metronome"
APP="${DIR}/application.macosx/${PROJECT_NAME}.app"
CONFIG="config.properties"
PLIST="${APP}/Contents/Info.plist"
VERSION='0.1-beta.3'
COPYRIGHT='Copyright © 2019 Krishna Bhamidipati. All rights reserved.'
CERT_IDENITY="Developer ID Application: Krishna Bhamidipati (V2H2HR4VR9)"

# externalize config via symlink for easy editing
# properties file need still be bundled inside app for proper sandboxing
cd "${BUILD_DIR}"
if [ -f "${CONFIG}" ]; then rm "${CONFIG}"; fi
ln -s "${APP}/Contents/Java/data/${CONFIG}" "${CONFIG}"

# write plist metadata
defaults write "${PLIST}" CFBundleShortVersionString "${VERSION}"
defaults write "${PLIST}" NSHumanReadableCopyright "${COPYRIGHT}"
# use SHA1 hash of the binary for a pseudo-build number
defaults write "${PLIST}" CFBundleVersion `shasum "${APP}/Contents/MacOS/${PROJECT_NAME}" | head -c 6`


# SIGN IT!! Gatekeeper ftw
codesign --force --sign "${CERT_IDENITY}" "${APP}"
