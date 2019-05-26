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

   build() {
      new WL.XcodeBuilder(this.projectFilePath).build("CAPlayThrough-macOS")
      new WL.XcodeBuilder(this.projectFilePath).build("CARBMeasure-macOS")
   }

   clean() {
      WL.FileSystem.rmdirIfExists(`${this.projectDirPath}/DerivedData`)
      WL.FileSystem.rmdirIfExists(`${this.projectDirPath}/Build`)
   }

   ci() {
      new WL.XcodeBuilder(this.projectFilePath).ci("CAPlayThrough-macOS")
      new WL.XcodeBuilder(this.projectFilePath).ci("CARBMeasure-macOS")
   }

}
