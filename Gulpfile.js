import cp from 'child_process';
import path from 'path';
import fs from 'fs';
import gulp from 'gulp';
import os from 'os';
import url from 'url';
import glob from 'glob';

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

function makeStandalone() {
   const projectPath = `${rootDirPath}/Shared.xcodeproj/project.pbxproj`;
   const vendorDirPath = `${rootDirPath}/Vendor`;
   const vendorPath = `${vendorDirPath}/mc`;
   const regex = /mc-shared\/\w+\/Sources/g;

   const contents = fs.readFileSync(projectPath).toString();
   const matches = contents.match(regex);

   if (matches == undefined) {
      console.log('➔ Nothing to do!');
      return;
   }
   if (fs.existsSync(vendorPath)) {
      fs.rmdirSync(vendorPath, { recursive: true, force: true });
   }
   fs.mkdirSync(vendorPath, { recursive: true });
   for (const match of matches) {
      const from = `${vendorDirPath}/${match}`;
      const to = vendorPath + match.replace('mc-shared', '');
      const swiftFiles = glob
         .sync(`${from}/**/*.swift`)
         .concat(glob.sync(`${from}/**/*.h`))
         .concat(glob.sync(`${from}/**/*.m`));
      for (const file of swiftFiles) {
         const contents = fs.readFileSync(file).toString();
         if (contents.includes('MCA-OSS-CARB')) {
            const dstName = path.join(to, file.replace(from, ''));
            const dstDir = path.dirname(dstName);
            fs.mkdirSync(dstDir, { recursive: true });
            // console.log(`➔ Copying '${file}' to '${dstName}'`);
            fs.copyFileSync(file, dstName);
         }
      }

      const fromSpec = from.replace('/Sources', '/project.yml');
      const toSpec = to.replace('/Sources', '/project.yml');
      fs.mkdirSync(to, { recursive: true });
      fs.copyFileSync(fromSpec, toSpec);
   }
   fs.copyFileSync(`${vendorDirPath}/mc-shared/templates.yml`, `${vendorPath}/templates.yml`);

   const testsSourceRoot = `${vendorDirPath}/mc-shared/mcxMedia/Tests/Types`;
   const testsDestRoot = `${vendorDirPath}/mc/mcxMedia/Tests/Types`;
   fs.mkdirSync(testsDestRoot, { recursive: true });
   fs.copyFileSync(`${testsSourceRoot}/RingBufferTestsUtility.swift`, `${testsDestRoot}/RingBufferTestsUtility.swift`);
   fs.copyFileSync(`${testsSourceRoot}/RingBufferTests.swift`, `${testsDestRoot}/RingBufferTests.swift`);
}

//~~~

const v = new Version(path.join(rootDirPath, 'Configuration/Version.xcconfig'));

function ci() {
   const cmd = `xcodebuild -quiet -project "${rootDirPath}/CARingBuffer.xcodeproj" -scheme "SwiftTests" CODE_SIGNING_REQUIRED=NO CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY= build-for-testing`;
   _run(cmd);
}

//~~~

gulp.task('gen', (cb) => {
   _run(`xcodegen --spec project-shared.yml`);
   cb();
});

gulp.task('st', (cb) => {
   _run(`xcodegen --spec project-shared.yml`);
   makeStandalone();
   _run(`xcodegen --spec project.yml`);
   cb();
});

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
