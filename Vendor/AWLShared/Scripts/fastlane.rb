
class BuildSettings
  @@NoCodesign = {
    "CODE_SIGN_IDENTITY" => "",
    "CODE_SIGNING_REQUIRED" => "NO",
    "CODE_SIGN_ENTITLEMENTS" => ""
  }
  def self.NoCodesign
    @@NoCodesign
  end
end

def XcodeClean(*schemes)
  schemes.each { |schema|
    xcodebuild(scheme: schema, build_settings: BuildSettings.NoCodesign, xcargs: "clean")
  }
end

def XcodeTest(*schemes)
  schemes.each { |schema|
    scan(scheme: schema, output_directory: "fastlane/test_output/#{schema}")
  }
end

def XcodeBuild(*schemes)
  schemes.each { |schema|
    xcodebuild(scheme: schema, build_settings: BuildSettings.NoCodesign)
  }
end

# class XcodeBuild
#   def self.Clean(*schemes)
#     puts self.inspect
#     # XcodeBuildClean(schemes)
#   end
#   def initialize
#     # puts "foo"
#   end
# end

