#!/usr/bin/env ruby

gitRepoDirPath = File.expand_path("#{File.dirname(__FILE__)}/..")

require "#{gitRepoDirPath}/Vendor/WL/Conf/Scripts/lib/FileHeaderChecker.rb"
require "#{gitRepoDirPath}/Vendor/WL/Conf/Scripts/lib/Tool.rb"
require "#{gitRepoDirPath}/Vendor/WL/Conf/Scripts/lib/GitStatus.rb"

changedFiles = GitStatus.new(gitRepoDirPath).changedFiles

targetName = ENV['TARGET_NAME']
if targetName == "CARBTestsCpp"
   targetDir = "#{gitRepoDirPath}/Vendor/CoreAudio/PublicUtility"
   if !Dir.exists?(targetDir)
      puts "error: Folder \"#{targetDir}\" does NOT exists. Please read file Readme.md"
      exit(1)
   end
else
   if Tool.verifyEnvironment("Check Headers")
      puts "→ Checking headers..."
      puts FileHeaderChecker.new(["WaveLabs"]).analyseFiles(changedFiles)
   end
   if Tool.canRunSwiftLint()
      puts "→ Linting..."
      changedFiles.select { |f| File.extname(f) == ".swift" }.each { |f|
         puts `swiftlint lint --quiet --config \"#{gitRepoDirPath}/.swiftlint.yml\" --path \"#{f}\"`
      }
   end
end