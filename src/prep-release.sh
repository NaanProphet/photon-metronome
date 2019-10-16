#!/bin/bash

### Prepares the application for a GitHub Release

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_NAME="photon_metronome"
BUILD_DIR="${DIR}/${PROJECT_NAME}/application.macosx"
APP="${BUILD_DIR}/${PROJECT_NAME}.app"
CONFIG="config.properties"
PLIST="${APP}/Contents/Info.plist"
VERSION='0.1-beta.3'
COPYRIGHT='Copyright © 2019 Krishna Bhamidipati. All rights reserved.'
CERT_IDENITY="Developer ID Application: Krishna Bhamidipati (V2H2HR4VR9)"


# gatekeeper ftw
# don't force signature because it changes the binary's hash
codesign --sign "${CERT_IDENITY}" "${APP}"


# use SHA1 hash as a pseudo-build number
BUILD_NUMBER=`shasum "${APP}/Contents/MacOS/${PROJECT_NAME}" | head -c 6`
# prepare zip file name
ZIP="${DIR}/${PROJECT_NAME}_v${VERSION}-macosx-${BUILD_NUMBER}.zip"


# externalize config via symlink for easy editing
# properties file need still be bundled inside app for proper sandboxing
if [ -f "${BUILD_DIR}/${CONFIG}" ]; then rm "${BUILD_DIR}/${CONFIG}"; fi
ln -s "${APP}/Contents/Java/data/${CONFIG}" "${BUILD_DIR}/${CONFIG}"


# write plist metadata
defaults write "${PLIST}" CFBundleShortVersionString "${VERSION}"
defaults write "${PLIST}" NSHumanReadableCopyright "${COPYRIGHT}"
defaults write "${PLIST}" CFBundleVersion "${BUILD_NUMBER}"


# zip up folder
# use ditto because it compresses folders exactly like Finder
# whereas zip is unwiedly with parent folders
ditto -c -k --sequesterRsrc "${BUILD_DIR}" "${ZIP}"
