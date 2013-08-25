#!/bin/sh

#  xcodeScript_uploadToTestFlight.sh
#
#  Created by IPaPa on 13/8/24.
#
# this script will upload archive to testflight and increase build version num by 1
# run this script with:
#    bash xcodeScript_uploadToTestFlight.sh -a api_token -t team_token

plist="$PROJECT_DIR/$INFOPLIST_FILE"
buildVersionNum=$(/usr/libexec/Plistbuddy -c "Print CFBundleVersion" "$plist")
if [ -z "$buildVersionNum" ]; then
echo "No build number in $plist"
exit 2
fi
while getopts a:t: option
do
case "${option}"
in
a) API_TOKEN=${OPTARG};;
t) TEAM_TOKEN=${OPTARG};;
esac
done
#zip dsym
#DATE=`date +%Y%m%d`
ZIPPED_DSYM_OUTPUT_FILE_PATH="${PROJECT_DIR}/${PRODUCT_NAME}.dsym.zip"
cd "$ARCHIVE_DSYMS_PATH"
zip -r "$ZIPPED_DSYM_OUTPUT_FILE_PATH" "$DWARF_DSYM_FILE_NAME"
#create ipa
ipaPath="${PROJECT_DIR}/${PRODUCT_NAME}.ipa"
appPath="$ARCHIVE_PRODUCTS_PATH/$INSTALL_PATH/$WRAPPER_NAME"
xcrun -sdk iphoneos PackageApplication "$appPath" -o "$ipaPath" --sign "${CODE_SIGN_IDENTITY}"

/usr/bin/curl "http://testflightapp.com/api/builds.json" \
-F file=@"$ipaPath" \
-F api_token="${API_TOKEN}" \
-F team_token="${TEAM_TOKEN}" \
-F notes="Build uploaded automatically from Xcode." \
-F dsym=@"$ZIPPED_DSYM_OUTPUT_FILE_PATH"
#delete ipa
rm "$ipaPath"

#delete zip dsym
rm "$ZIPPED_DSYM_OUTPUT_FILE_PATH"


#increase build version number

IFS='.' read -a array <<< "$buildVersionNum"
vlen="${#array[@]}"
lastIdx=$((vlen-1))
array[$lastIdx]=$(expr ${array[$lastIdx]} + 1)
buildVersionNum="${array[0]}"
for (( i=1; i<$vlen; i=i+1 ))
do
buildVersionNum="${buildVersionNum}.${array[i]}"
done
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildVersionNum" "$plist"
echo "Incremented build number to $buildVersionNum"

#open testflight page
/usr/bin/open "https://testflightapp.com/dashboard/builds/"
