IPa-xcode-Archive-post-script
=============================

a post script for xcode to archive product

How to use it:

1.create a new scheme

2.select new scheme and select Archive Directory->Post-actions

3.tap + and add a new script

4.Provide build settings from "select your target"

5.run script with "bash xxxxx.sh"


xcodeScript_uploadToAppStore.sh
------------------------

this script will automatically upload product to apple store
run script with argument -a appleID -w password -g git_tag_prefix

    bash xcodeScript_uploadToAppStore.sh -a appleID -w password

this script will create an item named Xcode:itunesconnect.apple.com
and after uploaded will delete this item

-g is an optional argument,this will integrate with git,each time it upload to App Store

this script will automatically add a tag with prefix (argument come with -g) 

xcodeScript_uploadToTestFlight.sh
------------------------

this script will automatically upload product to testflight
run script with argument -a api_token -t team_token -g git_tag_prefix

    bash xcodeScript_uploadToTestFlight.sh -a api_token -t team_token -g git_tag_prefix

get api_token and team_token from  [TestFlight Upload API][1]

-g is an optional argument,this will integrate with git,each time it upload to testflight

this script will automatically add a tag with prefix (argument come with -g) 

and will catch commit message from last tag with prefix to current commit

and send to testflight as update note


  [1]: https://testflightapp.com/api/doc/ "TestFlight"

