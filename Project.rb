MAIN_FILE = "#{ENV['AWL_SCRIPTS']}/Automation.rb".freeze
if File.exist?(MAIN_FILE)
   require MAIN_FILE
else
   Dir[File.dirname(__FILE__) + "/Vendor/WL/Scripts/**/*.rb"].each { |file| require file }
end

class Project < AbstractProject

   def initialize(rootDirPath)
      super(rootDirPath)
      @projectFilePath = rootDirPath + "/CARingBuffer.xcodeproj"
   end

   def build()
      XcodeBuilder.new(@projectFilePath).build("CAPlayThrough")
      XcodeBuilder.new(@projectFilePath).build("CARBMeasure")
   end

   def clean()
      XcodeBuilder.new(@projectFilePath).clean("CAPlayThrough")
      XcodeBuilder.new(@projectFilePath).clean("CARBMeasure")
   end

   def release()
      XcodeBuilder.new(@projectFilePath).ci("CAPlayThrough")
      XcodeBuilder.new(@projectFilePath).ci("CARBMeasure")
   end

   def archive()
      release()
   end

   def deploy()
      gitHubRelease([])
   end

   def generate()
      deleteXcodeFiles()
      gen = XCGen.new(File.join(@rootDirPath, "CARingBuffer.xcodeproj"))
      gen.setDeploymentTarget("10.12", "macOS")
      app = gen.addApplication("CAPlayThrough", "Sources/CAPlayThrough", "macOS")
      gen.addBuildSettings(app, {
         "SWIFT_OBJC_BRIDGING_HEADER" => "Tests/Bridging-Header.h",
         "SWIFT_INCLUDE_PATHS" => "Tests"
      })
      gen.addComponentFiles(app, [
         "AudioDevice.swift", "AudioUnitSettings.swift", "AudioObjectUtility.swift", "AudioComponentDescription.swift",
         "AppKit/.+/(NS|)WindowController\.swift", "AppKit/.+/(NS|)Window\.swift", "AppKit/.+/(NS|)ViewController\.swift", "AppKit/.+/(NS|)Menu.*\.swift",
         "AppKit/.+/(NS|)View\.swift", "AppKit/.+/(NS|)Button\.swift", "NSControl.swift",
         "BuildInfo.swift", "RuntimeInfo.swift", "FailureReporting.swift", "ObjCAssociation.swift", "DispatchUntil.swift",
         "NumericTypesConversions.swift", "FileManager.swift", "SystemAppearance.swift", "Log.swift",
         "UnfairLock.swift", "String.swift", "NonRecursiveLocking.swift"
      ])
      setupSources(gen, app)


      swiftTests = gen.addTest("SwiftTests", "Tests/Swift", "macOS", false)
      setupSources(gen, swiftTests)
      gen.addTestFiles(swiftTests, [ "RingBufferTestsUtility.swift"])
      gen.addBuildSettings(swiftTests, {
         "SWIFT_OBJC_BRIDGING_HEADER" => "Tests/Bridging-Header.h",
         "SWIFT_INCLUDE_PATHS" => "Tests"
      })

      cppTests = gen.addTest("CppTests", "Tests/C++", "macOS", false)
      gen.addBuildSettings(cppTests, {
         "SWIFT_OBJC_BRIDGING_HEADER" => "Tests/Bridging-Header.h",
         "SWIFT_INCLUDE_PATHS" => "Tests",
         "SWIFT_INSTALL_OBJC_HEADER" => "YES"
      })
      setupSources(gen, cppTests)
      gen.addTestFiles(cppTests, [ "RingBufferTestsUtility.swift"])

      # tool = project.addTool(name: "CARBMeasure", sources: ["Sources/CARBMeasure"], platform: :osx, deploymentTarget: "10.11")
      # setupSources(gen, tool)
      gen.save()
   end

   def setupSources(project, target)
      project.addComponentFiles(target, [ "RingBuffer.*\.swift", "Atomic.m", "Atomic.h", "MediaBuffer.*\.swift",
         "DefaultInitializerType.swift", "UnsafeMutableAudioBufferListPointer.swift", "AudioBuffer.swift"
      ])
   end

end
