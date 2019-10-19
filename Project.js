const Path = require('path');
const FileSystem = require('wl-scripting').FileSystem;
const AbstractProject = require('wl-scripting').AbstractProject;
const XcodeBuilder = require('wl-scripting').XcodeBuilder;

class Project extends AbstractProject {
   constructor(projectDirPath) {
      super(projectDirPath);
      this.projectFilePath = Path.join(this.projectDirPath, 'CARingBuffer.xcodeproj');
   }

   actions() {
      return ['ci', 'build', 'clean', 'test', 'release', 'verify', 'deploy', 'archive'];
   }

   deploy() {
      // gitHubRelease(assets: [])
   }

   build() {
      new XcodeBuilder(this.projectFilePath).build('CAPlayThrough-macOS');
      new XcodeBuilder(this.projectFilePath).build('CARBMeasure-macOS');
   }

   clean() {
      super.clean();
      FileSystem.rmdirIfExists(`${this.projectDirPath}/DerivedData`);
      FileSystem.rmdirIfExists(`${this.projectDirPath}/Build`);
   }

   ci() {
      new XcodeBuilder(this.projectFilePath).ci('CAPlayThrough-macOS');
      new XcodeBuilder(this.projectFilePath).ci('CARBMeasure-macOS');
   }
}
