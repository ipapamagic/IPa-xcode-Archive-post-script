#!/bin/sh

#  xcodeScript_uploadToAppStore.sh
#
#  Created by IPaPa on 13/8/24.
#
# this script will upload archive to appstore
# Make sure you have an application in "waiting to upload" state.
# run this script with:
#    bash xcodeScript_uploadToAppStore.sh -a appleID -w password
# this script will create an item named Xcode:itunesconnect.apple.com
# and after uploaded will delete this item


plist="$PROJECT_DIR/$INFOPLIST_FILE"
versionNum=$(/usr/libexec/Plistbuddy -c "Print CFBundleShortVersionString" "$plist")
if [ -z "$versionNum" ]; then
echo "No build number in $plist"
exit 2
fi
#zip dsym
#DATE=`date +%Y%m%d`
#ZIPPED_DSYM_OUTPUT_FILE_PATH="${PROJECT_DIR}/../${PRODUCT_NAME}_v${versionNum}_${DATE}.dsym.zip"
#cd "$ARCHIVE_DSYMS_PATH"
#zip -r "$ZIPPED_DSYM_OUTPUT_FILE_PATH" "$DWARF_DSYM_FILE_NAME"

#create ipa
ipaPath="${PROJECT_DIR}/${PRODUCT_NAME}.ipa"
appPath="$ARCHIVE_PRODUCTS_PATH/$INSTALL_PATH/$WRAPPER_NAME"
xcrun -sdk iphoneos PackageApplication "$appPath" -o "$ipaPath" --sign "${CODE_SIGN_IDENTITY}"

#upload to app store
while getopts a:w: option
do
case "${option}"
in
a) LOGIN=${OPTARG};;
w) PASSWORD=${OPTARG};;
esac
done
security add-generic-password -s "Xcode:itunesconnect.apple.com" -a "$LOGIN" -w "$PASSWORD" -U
xcrun -sdk iphoneos Validation -online -upload -verbose "$ipaPath"
security delete-generic-password -s Xcode:itunesconnect.apple.com -a "$LOGIN"
#delete ipa
rm "$ipaPath"

#increase version number

IFS='.' read -a array <<< "$versionNum"
vlen="${#array[@]}"
lastIdx=$((vlen-1))
array[$lastIdx]=$(expr ${array[$lastIdx]} + 1)
versionNum="${array[0]}"
for (( i=1; i<$vlen; i=i+1 ))
do
versionNum="${versionNum}.${array[i]}"
done
buildnum="${versionNum}.0"
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "$plist"
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $versionNum" "$plist"
echo "Incremented version number to $versionNum"