import cp from 'child_process';
import path from 'path';
import fs from 'fs';
import gulp from 'gulp';
import os from 'os';
import url from 'url';

const rootDirPath = path.dirname(url.fileURLToPath(import.meta.url));

/**
 * @param {string} cmd
 * @param {string?} cwd
 */
function _run(cmd, cwd) {
   console.log('ℹ️  ' + cmd);
   cp.execSync(cmd, { stdio: 'inherit', cwd: cwd ?? rootDirPath });
}

//~~~

class Version {
   #versionNumberKey = 'APP_PROJECT_VERSION';
   #buildNumberKey = 'APP_BUNDLE_VERSION';
   #filePath;
   #lines;

   constructor(filePath) {
      this.#filePath = filePath;
      this.#lines = fs.readFileSync(filePath).toString().trim().split('\n');
   }

   get version() {
      const line = this.#lines.filter((item) => item.startsWith(this.#versionNumberKey))[0];
      const value = line.split('=')[1].trim();
      return value;
   }

   get build() {
      const line = this.#lines.filter((item) => item.startsWith(this.#buildNumberKey))[0];
      const value = line.split('=')[1].trim();
      return parseInt(value);
   }

   bump() {
      const latestTag = cp.execSync('git describe --tags --abbrev=0').toString().trim();
      const components = latestTag.split('.');
      const last = parseInt(components[components.length - 1]);
      components[components.length - 1] = last + 1;
      const newTag = components.join('.');
      if (newTag === this.version) {
         console.log('Nothing to do. Skipping.');
         return;
      }

      const newBuild = this.build + 1;
      this.#lines = [`${this.#versionNumberKey} = ${newTag}`, `${this.#buildNumberKey} = ${newBuild}`];

      const contents = this.#lines.join('\n') + '\n';
      fs.writeFileSync(this.#filePath, contents);
   }
}

//~~~

const v = new Version(path.join(rootDirPath, 'Configuration/Version.xcconfig'));

function ci() {
   const cmd = `xcodebuild -quiet -project "${rootDirPath}/CARingBuffer.xcodeproj" -scheme "SwiftTests" CODE_SIGNING_REQUIRED=NO CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY= build-for-testing`;
   _run(cmd);
}

//~~~

gulp.task('ci', (cb) => {
   ci();
   cb();
});

gulp.task('default', (cb) => {
   console.log('✅ Available tasks:');
   cp.execSync('gulp -T', { stdio: 'inherit' });
   cb();
});

gulp.task('finish', (cb) => {
   const buildNum = v.version;
   console.log(`Creating tag: "${buildNum}"`);
   cp.execSync(`git tag "${buildNum}"`, { stdio: 'inherit' });
   cp.execSync(`git push origin "${buildNum}"`, { stdio: 'inherit' });
   cb();
});
