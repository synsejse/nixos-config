const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const { EventEmitter } = require('node:events');

const source = fs.readFileSync(process.argv[2], 'utf8');
for (const mode of ['disabled', 'local', 'enabled']) {
  const writes = [];
  const modulesRoot = mode === 'local' ? '/nix/store/test/modules' : '/config/discord/1/modules';
  const write = (operation, target) => {
    if (mode !== 'enabled') throw Object.assign(new Error('read-only modules'), { code: 'EROFS' });
    writes.push([operation, target]);
  };
  const dependencies = {
    path,
    fs: {
      readFileSync: () => JSON.stringify({ discord_desktop_core: { installedVersion: 1 } }),
      rmSync: target => write('rm', target),
      mkdirSync: target => write('mkdir', target),
    },
    module: { globalPaths: [] },
    child_process: {},
    electron: { app: {}, autoUpdater: new EventEmitter() },
    https: {},
    events: { EventEmitter },
    '../paths': { getUserDataVersioned: () => '/config/discord/1' },
    '../utils/buildInfo': { localModulesRoot: mode === 'local' ? modulesRoot : undefined },
  };
  const context = {
    exports: {}, process: { platform: 'linux' },
    settings: { get: key => key === 'SKIP_HOST_UPDATE' || (key === 'SKIP_MODULE_UPDATE' && mode === 'disabled') },
    require: name => {
      assert.ok(name in dependencies, `unexpected dependency: ${name}`);
      return dependencies[name];
    },
  };
  vm.runInNewContext(source, context);
  context.exports.init('https://example.invalid', { releaseChannel: 'stable', version: '1' });
  assert.equal(context.exports.getInstalled().discord_desktop_core.installedVersion, 1);
  assert.deepEqual(writes, mode === 'enabled' ? [['rm', path.join(modulesRoot, 'pending')], ['mkdir', path.join(modulesRoot, 'pending')]] : []);
  console.log(`PASS: updater initialization with ${mode} module updates`);
}
