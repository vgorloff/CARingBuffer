.PHONY: default all clean build

AWLBuildRootDirPath:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
AWLBuildDirPath:=$(AWLBuildRootDirPath)/DerivedData
AWLBuildToolName = xctool
AWLBuildToolAvailable = $(shell hash $(AWLBuildToolName) 2>/dev/null && echo "YES" )

ifeq ($(AWLBuildToolName),xcodebuild)
AWLArgsBuildReporter =
else
AWLArgsBuildReporter = -reporter plain
endif

AWLArgsCommon = -derivedDataPath "$(AWLBuildDirPath)" DEPLOYMENT_LOCATION=NO
AWLArgsNoCodesign = CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS=""
AWLArgsDevIDCodesign = CODE_SIGN_IDENTITY="Developer ID Application" CODE_SIGNING_REQUIRED=YES
AWLArgsEnvVariables = AWLBuildSkipAuxiliaryScripts=YES

ifneq ($(AWLBuildToolAvailable),YES)
$(error "$(AWLBuildToolName)" does not exist. Solution: brew install $(AWLBuildToolName))
endif

default:
	@echo "Available targets:"
	@echo "    all:\t Invoke targets: clean build"
	@echo "    clean:\t Cleans all build targets and configurations"
	@echo "    build:\t Builds all build targets and configurations"
	
all: \
	clean \
	build

clean:
	rm -rf "$(AWLBuildDirPath)"
	
build:
	$(AWLArgsEnvVariables) $(AWLBuildToolName) $(AWLArgsBuildReporter) $(AWLArgsCommon) $(AWLArgsNoCodesign) -configuration Release -project CARingBuffer.xcodeproj -scheme CARBMeasure build
	$(AWLArgsEnvVariables) $(AWLBuildToolName) $(AWLArgsBuildReporter) $(AWLArgsCommon) $(AWLArgsNoCodesign) -configuration Release -project CARingBuffer.xcodeproj -scheme CARBTestsSwift test
