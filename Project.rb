MAIN_FILE = "#{ENV['AWL_LIB_SRC']}/Scripts/Automation.rb".freeze
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

      tool = project.addTool(name: "CARBMeasure", sources: ["Sources/CARBMeasure"], platform: :osx, deploymentTarget: "10.11")
      setupSources(project, tool)

      swiftTests = project.addTest(name: "SwiftTests", sources: "Tests/Swift", platform: :osx, deploymentTarget: "10.11", needsSchema: true)
      setupSources(project, swiftTests)

      cppTests = project.addTest(name: "CppTests", sources: "Tests/C++", platform: :osx, deploymentTarget: "10.11", needsSchema: true, buildSettings: {
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
