#!/bin/sh

#  xcodeScript_testDistribution.sh
#
#  Created by IPaPa on 13/8/24.
#
# this script will increase build version num by 1 , and add tag to git if -g is given and export release note if -r is given
# run this script with:
#    bash xcodeScript_testDistribution.sh -g git_tag_prefix -r release_note_fileName
plist="$PROJECT_DIR/$INFOPLIST_FILE"
buildVersionNum=$(/usr/libexec/Plistbuddy -c "Print CFBundleVersion" "$plist")
if [ -z "$buildVersionNum" ]; then
    echo "No build number in $plist"
exit 2
fi
while getopts g:r:v: option
do
    case "${option}"
    in
    g) GIT_TAG_PREFIX=${OPTARG};;
    r) RELEASE_NOTE_FILE=${OPTARG};;
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
        COMMIT_LOG=$(echo -e $(git log --reverse --format="%b %s\n"))
    else
        IFS="-" read -a array <<< "$targetTag"
        targetTag="${array[0]}"
        COMMIT_LOG=$(echo -e $(git log --reverse --format="%b %s\n" $targetTag..HEAD))
    fi

fi

#increase build version number
agvtool next-version -all

#IFS='.' read -a array <<< "$buildVersionNum"
#vlen="${#array[@]}"
#lastIdx=$((vlen-1))
#array[$lastIdx]=$(expr ${array[$lastIdx]} + 1)
#buildVersionNum="${array[0]}"
#for (( i=1; i<$vlen; i=i+1 ))
#do
#buildVersionNum="${buildVersionNum}.${array[i]}"
#done
#/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildVersionNum" "$plist"
#echo "Incremented build number to $buildVersionNum"

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
    if [ ! -z "$RELEASE_NOTE_FILE" ]; then
        rm "$RELEASE_NOTE_FILE"
        echo "$COMMIT_LOG" >> "$RELEASE_NOTE_FILE"
    fi
#git push
fi





