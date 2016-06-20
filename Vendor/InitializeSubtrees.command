#!/bin/bash
# Proper header for a Bash script.

AWLSrcDirPath=$(cd "$(dirname "$0")/../"; pwd)
cd "$AWLSrcDirPath"

# Setting up Subtree
git subtree add --prefix Vendor/WLMediaOpen https://github.com/vgorloff/WLMediaOpen.git master --squash

# Updating Subtree
# git subtree pull --prefix Vendor/WLMediaOpen https://github.com/vgorloff/WLMediaOpen.git master --squash
