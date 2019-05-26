require "#{ENV['AWL_SCRIPTS']}/Automation.rb"

class Project < AbstractProject

   def deploy()
      gitHubRelease(assets: [])
   end

   def generate()
      deleteXcodeFiles()
      gen = XCGen.new(File.join(@rootDirPath, "CARingBuffer.xcodeproj"))
      gen.setDeploymentTarget("10.12", "macOS")
      app = gen.addApplication("CAPlayThrough", "Sources/CAPlayThrough", "macOS")
      gen.addComponentFiles(app, [
         "AudioDevice.swift", "AudioUnitSettings.swift", "AudioObjectUtility.swift", "AudioComponentDescription.swift",
         "AppKit/.+/(NS|)WindowController\.swift", "AppKit/.+/(NS|)Window\.swift", "AppKit/.+/(NS|)ViewController\.swift", "AppKit/.+/(NS|)Menu.*\.swift",
         "AppKit/.+/(NS|)View\.swift", "AppKit/.+/(NS|)Button\.swift", "NSControl.swift", "NSAppearance.swift",
         "BuildInfo.swift", "RuntimeInfo.swift", "FailureReporting.swift", "ObjCAssociation.swift", "DispatchUntil.swift",
         "NumericTypesConversions.swift", "FileManager.swift", "SystemAppearance.swift", "Log.swift",
         "UnfairLock.swift", "String.swift", "String.Index.swift", "NonRecursiveLocking.swift", "NotificationObserver.swift"
      ])
      setupSources(gen, app)

      tool = gen.addTool("CARBMeasure", "Sources/CARBMeasure", "macOS")
      setupSources(gen, tool)
      gen.addTestFiles(tool, ["RingBufferTestsUtility.swift"])

      swiftTests = gen.addTest("SwiftTests", "Tests/Swift", "macOS", false)
      setupSources(gen, swiftTests)
      gen.addTestFiles(swiftTests, ["RingBufferTestsUtility.swift"])

      cppTests = gen.addTest("CppTests", "Tests/C++", "macOS", false)
      gen.addBuildSettings(cppTests, {
         "SWIFT_INSTALL_OBJC_HEADER" => "YES"
      })
      setupSources(gen, cppTests)
      gen.addTestFiles(cppTests, ["RingBufferTestsUtility.swift"])

      gen.save()
   end

   def setupSources(gen, target)
      gen.addComponentFiles(target, [ "RingBuffer.*\.swift", "Atomic.m", "Atomic.h", "MediaBuffer.*\.swift",
         "DefaultInitializerType.swift", "UnsafeMutableAudioBufferListPointer.swift", "AudioBuffer.swift"
      ])
      gen.addBuildSettings(target, {
         "SWIFT_OBJC_BRIDGING_HEADER" => "Tests/Bridging-Header.h",
         "SWIFT_INCLUDE_PATHS" => "Tests"
      })
   end

end
