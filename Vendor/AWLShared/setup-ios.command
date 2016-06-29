#!/bin/bash
# Proper header for a Bash script.

AWLSrcDirPath=$(cd "$(dirname "$0")/../../"; pwd)
cd "$AWLSrcDirPath"

ln -sfv  "Vendor/AWLShared/Settings/gitignore" ".gitignore"
ln -sfv  "Vendor/AWLShared/Settings/swiftlint.yml" ".swiftlint.yml"
ln -sfv  "Vendor/AWLShared/Settings/travis-osx.yml" ".travis.yml"
ln -sfv  "Vendor/AWLShared/LICENSE" "LICENSE"