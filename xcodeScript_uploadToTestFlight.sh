#!/bin/sh

#  xcodeScript_uploadToTestFlight.sh
#
#  Created by IPaPa on 13/8/24.
#
# this script will upload archive to testflight and increase build version num by 1
# run this script with:
#    bash xcodeScript_uploadToTestFlight.sh -a api_token -t team_token -d distribution_list -g git_tag_prefix

plist="$PROJECT_DIR/$INFOPLIST_FILE"
buildVersionNum=$(/usr/libexec/Plistbuddy -c "Print CFBundleVersion" "$plist")
if [ -z "$buildVersionNum" ]; then
    echo "No build number in $plist"
exit 2
fi
while getopts a:t:g:d: option
do
    case "${option}"
    in
    a) API_TOKEN=${OPTARG};;
    t) TEAM_TOKEN=${OPTARG};;
    g) GIT_TAG_PREFIX=${OPTARG};;
    d) DISTRIBUTION_LIST=${OPTARG};;
    esac
done
#generate note from git
COMMIT_LOG="Build uploaded automatically from Xcode."
tagVersion=$buildVersionNum
if [ ! -z "$GIT_TAG_PREFIX" ]; then
    cd "${PROJECT_DIR}"
    targetTag=$(git describe --match "$GIT_TAG_PREFIX*")
    if [[ -z $targetTag ]]
    then
        COMMIT_LOG=$(echo $(git log --reverse --format="%b %s"))
    else
        IFS="-" read -a array <<< "$targetTag"
        targetTag="${array[0]}"
        COMMIT_LOG=$(echo $(git log --reverse --format="%b %s" $targetTag..HEAD))
    fi

fi

#zip dsym
#DATE=`date +%Y%m%d`
ZIPPED_DSYM_OUTPUT_FILE_PATH="${PROJECT_DIR}/${PRODUCT_NAME}.dsym.zip"
cd "$ARCHIVE_DSYMS_PATH"
zip -r "$ZIPPED_DSYM_OUTPUT_FILE_PATH" "$DWARF_DSYM_FILE_NAME"
#create ipa
ipaPath="${PROJECT_DIR}/${PRODUCT_NAME}.ipa"
appPath="$ARCHIVE_PRODUCTS_PATH/$INSTALL_PATH/$WRAPPER_NAME"
echo "use code sign ${CODE_SIGN_IDENTITY}"
xcrun -sdk iphoneos PackageApplication "$appPath" -o "$ipaPath" --sign "${CODE_SIGN_IDENTITY}"
if [ ! -z $DISTRIBUTION_LIST ]; then
    /usr/bin/curl "http://testflightapp.com/api/builds.json" \
    -F file=@"$ipaPath" \
    -F api_token="${API_TOKEN}" \
    -F team_token="${TEAM_TOKEN}" \
    -F notes="$COMMIT_LOG" \
    -F dsym=@"$ZIPPED_DSYM_OUTPUT_FILE_PATH" \
    -F replace=True \
    -F distribution_lists="$DISTRIBUTION_LIST"
else
    /usr/bin/curl "http://testflightapp.com/api/builds.json" \
    -F file=@"$ipaPath" \
    -F api_token="${API_TOKEN}" \
    -F team_token="${TEAM_TOKEN}" \
    -F notes="$COMMIT_LOG" \
    -F dsym=@"$ZIPPED_DSYM_OUTPUT_FILE_PATH" \
    -F replace=True

fi

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
    git tag -a "$GIT_TAG_PREFIX$tagVersion" -m "$GIT_TAG_PREFIX$tagVersion"
    echo "add tag $GIT_TAG_PREFIX$tagVersion to current commit"
    git add "$plist"
    git commit -m "$GIT_TAG_PREFIX build version $buildVersionNum"
fi
#git push
fi



