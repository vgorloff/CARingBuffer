import * as FileSystem from 'fs';
import * as Path from 'path';
import * as WL from "wl-scripting";

class Project extends WL.AbstractProject {

   private projectFilePath: string;

   constructor(projectDirPath: string) {
      super(projectDirPath)
      this.projectFilePath = Path.join(this.projectDirPath, "CARingBuffer.xcodeproj")
   }

   actions() {
      return ["ci", "build", "clean", "test", "release", "verify", "deploy", "archive"]
   }

   deploy() {
      // gitHubRelease(assets: [])
   }

   build() {
      new WL.XcodeBuilder(this.projectFilePath).build("CAPlayThrough-macOS")
      new WL.XcodeBuilder(this.projectFilePath).build("CARBMeasure-macOS")
   }

   clean() {
      super.clean()
      WL.FileSystem.rmdirIfExists(`${this.projectDirPath}/DerivedData`)
      WL.FileSystem.rmdirIfExists(`${this.projectDirPath}/Build`)
   }

   ci() {
      new WL.XcodeBuilder(this.projectFilePath).ci("CAPlayThrough-macOS")
      new WL.XcodeBuilder(this.projectFilePath).ci("CARBMeasure-macOS")
   }

   generate() {
      this.deleteXcodeFiles()
      let gen = new WL.XCGen(this.projectFilePath)
      gen.setDeploymentTarget("10.12", WL.XCPlatform.macOS)
      let app = gen.addApplication("CAPlayThrough", "Sources/CAPlayThrough", WL.XCPlatform.macOS)
      app.addComponentFiles([
         "AudioDevice.swift", "AudioUnitSettings.swift", "AudioObjectUtility.swift", "AudioComponentDescription.swift",
         "AppKit/.+/(NS|)WindowController\.swift", "AppKit/.+/(NS|)Window\.swift", "AppKit/.+/(NS|)ViewController\.swift", "AppKit/.+/(NS|)Menu.*\.swift",
         "AppKit/.+/(NS|)View\.swift", "AppKit/.+/(NS|)Button\.swift", "NSControl.swift", "NSAppearance.swift",
         "BuildInfo.swift", "RuntimeInfo.swift", "FailureReporting.swift", "ObjCAssociation.swift", "DispatchUntil.swift",
         "NumericTypesConversions.swift", "FileManager.swift", "SystemAppearance.swift", "Log.swift",
         "UnfairLock.swift", "String.swift", "String.Index.swift", "NonRecursiveLocking.swift", "NotificationObserver.swift"
      ])
      this.setupSources(app)

      let tool = gen.addTool("CARBMeasure", "Sources/CARBMeasure", WL.XCPlatform.macOS)
      this.setupSources(tool)
      tool.addTestFiles(["RingBufferTestsUtility.swift"])

      let swiftTests = gen.addTest("SwiftTests", "Tests/Swift", WL.XCPlatform.macOS, false)
      this.setupSources(swiftTests)
      swiftTests.addTestFiles(["RingBufferTestsUtility.swift"])

      let cppTests = gen.addTest("CppTests", "Tests/C++", WL.XCPlatform.macOS, false)
      cppTests.addBuildSettings(new Map([
         ["SWIFT_INSTALL_OBJC_HEADER", "YES"]
      ]))
      this.setupSources(cppTests)
      cppTests.addTestFiles(["RingBufferTestsUtility.swift"])

      gen.save()
   }

   private setupSources(target: WL.XCTarget) {
      target.addComponentFiles([ "RingBuffer.*\.swift", "Atomic.m", "Atomic.h", "MediaBuffer.*\.swift",
         "DefaultInitializerType.swift", "UnsafeMutableAudioBufferListPointer.swift", "AudioBuffer.swift"
      ])
      target.addBuildSettings(new Map([
         ["SWIFT_OBJC_BRIDGING_HEADER", "Tests/Bridging-Header.h"],
         ["SWIFT_INCLUDE_PATHS", "Tests"]
      ]))
   }

}
