#!/bin/sh

#  xcodeScript_create_ipa_and_dsym.sh
#
#  Created by IPaPa on 13/8/24.
#
# this script will create ipa and dsym

#zip dsym
#DATE=`date +%Y%m%d`
ZIPPED_DSYM_OUTPUT_FILE_PATH="${PROJECT_DIR}/${PRODUCT_NAME}.dsym.zip"
cd "$ARCHIVE_DSYMS_PATH"
zip -r "$ZIPPED_DSYM_OUTPUT_FILE_PATH" "$DWARF_DSYM_FILE_NAME"
#create ipa
ipaPath="${PROJECT_DIR}/${PRODUCT_NAME}.ipa"
appPath="$ARCHIVE_PRODUCTS_PATH/$INSTALL_PATH/$WRAPPER_NAME"
xcrun -sdk iphoneos PackageApplication "$appPath" -o "$ipaPath" --sign "${CODE_SIGN_IDENTITY}"