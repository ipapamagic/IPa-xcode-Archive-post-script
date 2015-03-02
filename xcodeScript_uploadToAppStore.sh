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
while getopts a:w:g: option
do
case "${option}"
in
a) LOGIN=${OPTARG};;
w) PASSWORD=${OPTARG};;
g) GIT_TAG_PREFIX=${OPTARG};;
esac
done
if [ ! -z $LOGIN ] && [ ! -z $PASSWORD ]
then
security add-generic-password -s "Xcode:itunesconnect.apple.com" -a "$LOGIN" -w "$PASSWORD" -U
xcrun -sdk iphoneos Validation -online -upload -verbose "$ipaPath"
security delete-generic-password -s Xcode:itunesconnect.apple.com -a "$LOGIN"
#check git integrate
GIT_TAG_VERSIONNUM=$versionNum

#delete ipa
rm "$ipaPath"
fi
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
buildnum="${versionNum}.1"
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "$plist"
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $versionNum" "$plist"
echo "Incremented version number to $versionNum"

#commit plist to git
if [ ! -z "$GIT_TAG_PREFIX" ]; then
#ask should integrate git
USE_GIT=`/usr/bin/osascript << EOT
tell application "Xcode"
display dialog "Commit to git?" buttons {"NO", "YES"} \
default button "YES"
set result to button returned of result
end tell
EOT`
if [[ $USE_GIT == "YES" ]]
then
cd "${PROJECT_DIR}"
git tag -a "$GIT_TAG_PREFIX$GIT_TAG_VERSIONNUM" -m "$GIT_TAG_PREFIX$GIT_TAG_VERSIONNUM"
echo "add tag $GIT_TAG_PREFIX$GIT_TAG_VERSIONNUM to current commit"
git add "$plist"
git commit -m "version $versionNum"
fi
#git push
fi
