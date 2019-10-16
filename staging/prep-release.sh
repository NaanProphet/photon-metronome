#!/bin/bash

### Prepares the application for a GitHub Release

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_NAME="photon_metronome"
BUILD_TARGET="application.macosx"
BUILD_DIR="${DIR}/../src/${PROJECT_NAME}/${BUILD_TARGET}"
APP="${BUILD_DIR}/${PROJECT_NAME}.app"
CONFIG="config.properties"
PLIST="${APP}/Contents/Info.plist"
VERSION='0.1-beta.3'
COPYRIGHT='Copyright © 2019 Krishna Bhamidipati. All rights reserved.'
CERT_IDENITY="Developer ID Application: Krishna Bhamidipati (V2H2HR4VR9)"
DMG_INITIAL_SIZE="300m"


# gatekeeper ftw
# don't force signature because it changes the binary's hash
codesign --sign "${CERT_IDENITY}" "${APP}"


# use SHA1 hash as a pseudo-build number
BUILD_NUMBER=`shasum "${APP}/Contents/MacOS/${PROJECT_NAME}" | head -c 6`


# write plist metadata
defaults write "${PLIST}" CFBundleShortVersionString "${VERSION} build ${BUILD_NUMBER}"
defaults write "${PLIST}" NSHumanReadableCopyright "${COPYRIGHT}"
defaults write "${PLIST}" CFBundleVersion "${BUILD_NUMBER}"


# prepare package for DMG Canvas
# use dmg because it always preserves code signatures unlike zip, tar and ditto
DMG_DIR="${DIR}/Photon Metronome"
mkdir -p "${DMG_DIR}"
cp -r "${APP}" "${DMG_DIR}/"

# externalize config via symlink for easy editing
# properties file need still be bundled inside app for proper sandboxing
if [ -f "${DMG_DIR}/${CONFIG}" ]; then rm "${DMG_DIR}/${CONFIG}"; fi
# use relative path for symlink
cd "${DMG_DIR}"
ln -s "${PROJECT_NAME}.app/Contents/Java/data/${CONFIG}" "${CONFIG}"
cd -
