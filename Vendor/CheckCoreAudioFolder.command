#!/bin/bash
# Proper header for a Bash script.

AWLSrcDirPath=$(cd "$(dirname "$0")/../"; pwd)
cd "$AWLSrcDirPath"

function AWLCheckFolderAndReportWarning {
	if [ ! -d "$1" ]; then
		echo "warning: $1 does NOT exists. Please read file Readme.md"
	fi
}

AWLCheckFolderAndReportWarning "Vendor/CoreAudio/PublicUtility"
