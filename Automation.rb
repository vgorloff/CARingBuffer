MainFile = "#{ENV['AWL_LIB_SRC']}/Scripts/Automation.rb"
if File.exist?(MainFile)
  require MainFile
else
  Dir[File.dirname(__FILE__) + "/Vendor/WL/Scripts/**/*.rb"].each { |f| require f }
end

class Automation

   GitRepoDirPath = ENV['PWD']
   TmpDirPath = GitRepoDirPath + "/DerivedData"
   KeyChainPath = TmpDirPath + "/VST3NetSend.keychain"
   P12FilePath = GitRepoDirPath + '/Codesign/DeveloperIDApplication.p12'
   XCodeProjectFilePath = GitRepoDirPath + "/CARingBuffer.xcodeproj"
   XCodeProjectSchema = "Developer: Build Everything"
   VSTSDKDirPath = GitRepoDirPath + "/Vendor/Steinberg"
   VersionFilePath = GitRepoDirPath + "/Configuration/Version.xcconfig"
      
   def self.ci()
      if !Tool.isCIServer
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
   
   def self.build()
      XcodeBuilder.new(XCodeProjectFilePath).build(XCodeProjectSchema)
   end
   
   def self.clean()
      XcodeBuilder.new(XCodeProjectFilePath).clean(XCodeProjectSchema)
   end
   
   def self.test()
      XcodeBuilder.new(XCodeProjectFilePath).test("Logic Tests: C++")
   end
   
   def self.release()
      XcodeBuilder.new(XCodeProjectFilePath).ci("Developer: Analyze Performance")
      XcodeBuilder.new(XCodeProjectFilePath).ci("Demo: CAPlayThrough")
   end
   
   def self.verify()
      if Tool.isCIServer
         return
      end
      t = Tool.new()
      l = Linter.new(GitRepoDirPath)
      h = FileHeaderChecker.new(["WaveLabs"])
      if t.isXcodeBuild
         if t.canRunActions("Verification")
            changedFiles = GitStatus.new(GitRepoDirPath).changedFiles()
            puts "→ Checking headers..."
            puts h.analyseFiles(changedFiles)
            if l.canRunSwiftLint()
               puts "→ Linting..."
               l.lintFiles(changedFiles)
            end
         end
      else
         puts h.analyseDir(GitRepoDirPath + "/Sources")
         puts h.analyseDir(GitRepoDirPath + "/Tests")
         if l.canRunSwiftFormat()
            puts "→ Correcting sources (SwiftFormat)..."
            l.correctWithSwiftFormat(GitRepoDirPath + "/Sources")
            l.correctWithSwiftFormat(GitRepoDirPath + "/Tests")
         end
         if l.canRunSwiftLint()
            puts "→ Correcting sources (SwiftLint)..."
            l.correctWithSwiftLint()
         end
      end
   end
   
   def self.deploy()
      if Tool.isCIServer
         return
      end
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

end