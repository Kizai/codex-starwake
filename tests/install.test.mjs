import test from 'node:test';
import assert from 'node:assert/strict';
import {
  mkdtemp,
  mkdir,
  readFile,
  writeFile,
  readdir,
  access,
  symlink,
  rm,
} from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const label = 'io.github.kizai.codex-starwake';
async function fixture(t) {
  const directory = await mkdtemp(join(tmpdir(), 'starwake-install-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const install = join(directory, 'User & Friends <demo>', 'Codex Starwake');
  const agents = join(directory, 'Launch Agents');
  const trash = join(directory, 'Trash');
  const env = {
    ...process.env,
    STARWAKE_INSTALL_DIR: install,
    STARWAKE_AGENTS_DIR: agents,
    STARWAKE_TRASH_DIR: trash,
    STARWAKE_SKIP_LAUNCHCTL: '1',
  };
  const agent = join(agents, `${label}.plist`);
  function run(script) {
    return spawnSync('/bin/zsh', [join(root, 'scripts', script)], {
      cwd: root,
      env,
      encoding: 'utf8',
    });
  }
  function success(script) {
    const result = run(script);
    assert.equal(result.status, 0, result.stderr + result.stdout);
    return result.stdout;
  }
  return { directory, install, agents, trash, agent, run, success };
}

test('installer escapes XML paths and generates a user-scoped watcher', async (t) => {
  const f = await fixture(t);
  f.success('install.sh');
  const plist = spawnSync(
    '/usr/bin/plutil',
    ['-convert', 'json', '-o', '-', f.agent],
    { encoding: 'utf8' },
  );
  assert.equal(plist.status, 0, plist.stderr);
  const config = JSON.parse(plist.stdout);
  assert.equal(config.Label, label);
  assert.deepEqual(config.ProgramArguments, [
    join(f.install, 'Starwake'),
    join(f.install, 'web'),
    '--watch',
  ]);
  assert.equal(config.RunAtLoad, true);
  assert.equal(config.KeepAlive, true);
  assert.equal(config.LimitLoadToSessionType, 'Aqua');
  assert.equal(config.StandardOutPath, join(f.install, 'watcher.log'));
  await access(join(f.install, 'web', 'assets', 'shorekeeper.png'));
  const installedCommon = await readFile(
    join(f.install, 'scripts', 'common.sh'),
    'utf8',
  );
  assert.ok(
    !installedCommon.includes(root),
    'installed scripts must not depend on the checkout',
  );
});

test('reinstall is idempotent; enable, disable and status retain files', async (t) => {
  const f = await fixture(t);
  f.success('install.sh');
  await writeFile(join(f.install, 'custom-note.txt'), 'keep');
  f.success('install.sh');
  assert.equal(
    await readFile(join(f.install, 'custom-note.txt'), 'utf8'),
    'keep',
  );
  assert.match(f.success('disable.sh'), /disabled/);
  assert.match(f.success('enable.sh'), /enabled/);
  assert.match(f.success('status.sh'), /Installed:/);
});

test('unmanaged installation and symlink destinations are rejected', async (t) => {
  const f = await fixture(t);
  await mkdir(f.install, { recursive: true });
  await writeFile(join(f.install, 'keep.txt'), 'unrelated');
  assert.notEqual(f.run('install.sh').status, 0);
  assert.notEqual(f.run('uninstall.sh').status, 0);
  assert.equal(
    await readFile(join(f.install, 'keep.txt'), 'utf8'),
    'unrelated',
  );
  const g = await fixture(t);
  await mkdir(dirname(g.install), { recursive: true });
  await symlink(f.install, g.install);
  assert.notEqual(g.run('install.sh').status, 0);
});

test('installer refuses an unrelated LaunchAgent', async (t) => {
  const f = await fixture(t);
  await mkdir(f.agents, { recursive: true });
  const contents =
    '<?xml version="1.0"?><plist version="1.0"><dict><key>Label</key><string>unrelated</string><key>ProgramArguments</key><array><string>/bin/true</string></array></dict></plist>';
  await writeFile(f.agent, contents);
  assert.notEqual(f.run('install.sh').status, 0);
  assert.equal(await readFile(f.agent, 'utf8'), contents);
});

test('uninstall moves only the managed installation and agent to Trash', async (t) => {
  const f = await fixture(t);
  f.success('install.sh');
  const unrelated = join(f.directory, 'keep.txt');
  await writeFile(unrelated, 'keep');
  f.success('uninstall.sh');
  await assert.rejects(access(f.install));
  await assert.rejects(access(f.agent));
  assert.equal(await readFile(unrelated, 'utf8'), 'keep');
  const entries = await readdir(f.trash);
  assert.equal(entries.length, 1);
  await access(join(f.trash, entries[0], 'installation', '.starwake-managed'));
  await access(join(f.trash, entries[0], `${label}.plist`));
});
