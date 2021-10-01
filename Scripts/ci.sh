#!/bin/bash

source $(dirname "$0")/common.sh

SrcDirPath=$(cd "$(dirname "$0")/../"; pwd)
cd "$SrcDirPath"

xcodebuild -quiet -project "$AppProjectFilePath" -scheme "CAPlayThrough-macOS" CODE_SIGNING_REQUIRED=NO CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY= build || exit 1
xcodebuild -quiet -project "$AppProjectFilePath" -scheme "CARBMeasure-macOS" CODE_SIGNING_REQUIRED=NO CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY= build || exit 1

