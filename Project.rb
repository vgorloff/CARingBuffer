MAIN_FILE = "#{ENV['AWL_LIB_SRC']}/Scripts/Automation.rb".freeze
if File.exist?(MAIN_FILE)
   require MAIN_FILE
else
   Dir[File.dirname(__FILE__) + "/Vendor/WL/Scripts/**/*.rb"].each { |file| require file }
end

class Project < AbstractProject

   def initialize(rootDirPath)
      super(rootDirPath)
      @tmpDirPath = rootDirPath + "/DerivedData"
      @keyChainPath = @tmpDirPath + "/VST3NetSend.keychain"
      @p12FilePath = rootDirPath + '/Codesign/DeveloperIDApplication.p12'
      @projectFilePath = rootDirPath + "/CARingBuffer.xcodeproj"
      @projectSchema = "Developer: Build Everything"
      @versionFilePath = rootDirPath + "/Configuration/Version.xcconfig"
   end

   def ci()
      unless Environment.isCI
         release()
         return
      end
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "→ Preparing environment..."
      FileUtils.mkdir_p @tmpDirPath
      puts Tool.announceEnvVars
      puts "→ Setting up keychain..."
      kc = KeyChain.create(@keyChainPath)
      puts KeyChain.list
      defaultKeyChain = KeyChain.default
      puts "→ Default keychain: #{defaultKeyChain}"
      kc.setSettings()
      kc.info()
      kc.import(@p12FilePath, ENV['AWL_P12_PASSWORD'], ["/usr/bin/codesign"])
      kc.setKeyCodesignPartitionList()
      kc.dump()
      KeyChain.setDefault(kc.nameOrPath)
      puts "→ Default keychain now: #{KeyChain.default}"
      begin
         puts "→ Making build..."
         release()
         puts "→ Making cleanup..."
         KeyChain.setDefault(defaultKeyChain)
         KeyChain.delete(kc.nameOrPath)
      rescue StandardError
         KeyChain.setDefault(defaultKeyChain)
         KeyChain.delete(kc.nameOrPath)
         puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         raise
      end
   end

   def build()
      XcodeBuilder.new(@projectFilePath).build(@projectSchema)
   end

   def clean()
      XcodeBuilder.new(@projectFilePath).clean(@projectSchema)
   end

   def self.test()
      XcodeBuilder.new(@projectFilePath).test("Logic Tests: C++")
   end

   def release()
      XcodeBuilder.new(@projectFilePath).ci("Developer: Analyze Performance")
      XcodeBuilder.new(@projectFilePath).ci("Demo: CAPlayThrough")
   end

   def deploy()
      require 'yaml'
      releaseInfo = YAML.load_file("#{@rootDirPath}/Configuration/Release.yml")
      releaseName = releaseInfo['name']
      releaseDescriptions = releaseInfo['description'].map { |l| "* #{l}" }
      releaseDescription = releaseDescriptions.join("\n")
      version = Version.new(@versionFilePath).projectVersion
      puts "! Will make GitHub release → #{version}: \"#{releaseName}\""
      puts releaseDescriptions.map { |l| "  #{l}" }
      gh = GitHubRelease.new("vgorloff", "CARingBuffer")
      Readline.readline("OK? > ")
      gh.release(version, releaseName, releaseDescription)
   end

   def generate()
      project = XcodeProject.new(projectPath: File.join(@rootDirPath, "CARingBuffer.xcodeproj"), vendorSubpath: 'WL')
      app = project.addApp(name: "CAPlayThrough",
                           sources: ["Sources/CAPlayThrough"], platform: :osx, deploymentTarget: "10.11", needsLogger: true)
      project.useFilters(target: app, filters: [
                            "AppKit/Extensions/NSButton*", "AppKit/Extensions/NSMenu*", "AppKit/Extensions/NSView*", "AppKit/Extensions/NSWindow*",
                            "AppKit/Extensions/NSControl*", "AppKit/Reusable/View*", "Foundation/Dispatch/Dispatch*",
                            "AppKit/Sources/SystemAppearance*", "Core/Converters/NumericTypes*", "Foundation/NSRegularExpression/*",
                            "AppKit/Sources/Menu*", "AppKit/Media/Audio*", "AppKit/Reusable/Button*", "AppKit/Reusable/Window*",
                            "Foundation/Notification/*",
                            "Foundation/os/log/*", "Foundation/Sources/*Info*", "Foundation/ObjectiveC/*",
                            "Media/Sources/AudioUnit*",
                            "UI/Layout/*", "UI/Reporting/*", "UI/Extensions/*",
                            "Foundation/Extensions/Scanner*", "Foundation/Extensions/*Dictionary*", "Foundation/Extensions/*String*"
                         ])
      setupSources(project, app)

      tool = project.addTool(name: "CARBMeasure", sources: ["Sources/CARBMeasure"], platform: :osx)
      setupSources(project, tool)

      swiftTests = project.addTest(name: "SwiftTests", sources: "Tests/Swift", platform: :osx, needsSchema: true)
      setupSources(project, swiftTests)

      cppTests = project.addTest(name: "CppTests", sources: "Tests/C++", platform: :osx, needsSchema: true, buildSettings: {
         "SWIFT_INSTALL_OBJC_HEADER" => "YES"
      })
      setupSources(project, cppTests)
      project.save()
   end

   def setupSources(project, target)
      project.useFilters(target: target, filters: [
         "Media/Sources/Ring*", "Media/Sources/Media*", "Core/Concurrency/Atomic*", "Media/Sources/*Type*",
         "Media/Extensions/*Audio*", "Foundation/Testability/*", "Foundation/Extensions/CG*",
         "Foundation/Extensions/EdgeInsets*", "MediaTests/Types/RingBufferTestsUtility*"
      ])
   end

end
