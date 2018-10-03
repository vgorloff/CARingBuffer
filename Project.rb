MAIN_FILE = "#{ENV['AWL_LIB_SRC']}/Scripts/Automation.rb".freeze
if File.exist?(MAIN_FILE)
   require MAIN_FILE
else
   Dir[File.dirname(__FILE__) + "/Vendor/WL/Scripts/**/*.rb"].each { |file| require file }
end

class Project < AbstractProject

   def initialize(rootDirPath)
      super(rootDirPath)
      TmpDirPath = GitRepoDirPath + "/DerivedData"
      KeyChainPath = TmpDirPath + "/VST3NetSend.keychain"
      P12FilePath = GitRepoDirPath + '/Codesign/DeveloperIDApplication.p12'
      XCodeProjectFilePath = GitRepoDirPath + "/CARingBuffer.xcodeproj"
      XCodeProjectSchema = "Developer: Build Everything"
      VSTSDKDirPath = GitRepoDirPath + "/Vendor/Steinberg"
      VersionFilePath = GitRepoDirPath + "/Configuration/Version.xcconfig"
   end

   def ci()
      unless Environment.isCI
         release()
         return
      end
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "→ Preparing environment..."
      FileUtils.mkdir_p TmpDirPath
      puts Tool.announceEnvVars
      puts "→ Setting up keychain..."
      kc = KeyChain.create(KeyChainPath)
      puts KeyChain.list
      defaultKeyChain = KeyChain.default
      puts "→ Default keychain: #{defaultKeyChain}"
      kc.setSettings()
      kc.info()
      kc.import(P12FilePath, ENV['AWL_P12_PASSWORD'], ["/usr/bin/codesign"])
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
      rescue
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
      XcodeBuilder.new(XCodeProjectFilePath).test("Logic Tests: C++")
   end

   def release()
      XcodeBuilder.new(XCodeProjectFilePath).ci("Developer: Analyze Performance")
      XcodeBuilder.new(XCodeProjectFilePath).ci("Demo: CAPlayThrough")
   end

   def deploy()
      require 'yaml'
      releaseInfo = YAML.load_file("#{GitRepoDirPath}/Configuration/Release.yml")
      releaseName = releaseInfo['name']
      releaseDescriptions = releaseInfo['description'].map { |l| "* #{l}"}
      releaseDescription = releaseDescriptions.join("\n")
      version = Version.new(VersionFilePath).projectVersion
      puts "! Will make GitHub release → #{version}: \"#{releaseName}\""
      puts releaseDescriptions.map { |l| "  #{l}" }
      gh = GitHubRelease.new("vgorloff", "CARingBuffer")
      Readline.readline("OK? > ")
      gh.release(version, releaseName, releaseDescription)
   end

   def generate()
      project = XcodeProject.new(projectPath: File.join(@rootDirPath, "VST3NetSend.xcodeproj"), vendorSubpath: 'WL')
      netSendKit = project.addFramework(name: "VST3NetSendKit",
                                        sources: ["Sources/NetSendKit"], platform: :osx, deploymentTarget: "10.11",
                                        bundleID: "ua.com.wavelabs.vst3.$(PRODUCT_NAME)",
                                        buildSettings: {
                                           "SWIFT_INSTALL_OBJC_HEADER" => "YES",
                                           "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES" => "YES",
                                           "APPLICATION_EXTENSION_API_ONLY" => "YES",
                                           "OTHER_LDFLAGS" => "-framework AudioToolbox",
                                           "DEFINES_MODULE" => "YES",
                                           "LD_RUNPATH_SEARCH_PATHS" => "$(inherited) @executable_path/../Frameworks @loader_path/Frameworks"
                                        })
      project.useFilters(target: netSendKit, filters: [
                            "Core/Formatters/IntegerFormatter*", "Foundation/os/log/*", "Foundation/Sources/*Info*",
                            "Media/Extensions/AudioComponentDescription*", "Media/Sources/AudioUnit*"
                         ])

      netSend = project.addBundle(name: "VST3NetSend",
                                  sources: ["Sources/VST"], platform: :osx, deploymentTarget: "10.11",
                                  bundleID: "ua.com.wavelabs.$(PRODUCT_NAME)",
                                  buildSettings: {
                                     "DSTROOT" => "$(HOME)",
                                     "INSTALL_PATH" => "/Library/Audio/Plug-Ins/VST3/WaveLabs",
                                     "EXPORTED_SYMBOLS_FILE" => "$(GV_VST_SDK)/public.sdk/source/main/macexport.exp",
                                     "WRAPPER_EXTENSION" => "vst3",
                                     "GCC_PREFIX_HEADER" => "Sources/VST/Prefix.h",
                                     "GCC_PREPROCESSOR_DEFINITIONS_Debug" => "DEVELOPMENT=1 $(inherited)",
                                     "GCC_PREPROCESSOR_DEFINITIONS_Release" => "RELEASE=1 NDEBUG=1 $(inherited)",
                                     "DEPLOYMENT_LOCATION" => "YES",
                                     "GENERATE_PKGINFO_FILE" => "YES",
                                     "SKIP_INSTALL" => "NO",
                                     "OTHER_LDFLAGS" => "-framework AudioToolbox -framework CoreAudio -framework Cocoa -framework AudioUnit"
                                  })

      project.addDependencies(to: netSend, dependencies: [netSendKit])
      project.save()
   end

end
