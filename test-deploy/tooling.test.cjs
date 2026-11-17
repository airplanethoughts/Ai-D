'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createRequire} = require('node:module');
const {mkdtemp, writeFile, rm} = require('node:fs/promises');
const {readFileSync} = require('node:fs');
const {tmpdir} = require('node:os');
const {join} = require('node:path');
const {once} = require('node:events');
const cliRequire = createRequire(require.resolve('firebase-tools/package.json'));

test('patched Hosting server serves assets, route fallback and cache headers', {timeout: 15000}, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'aid-hosting-test-'));
  let server;
  try {
    await writeFile(join(directory, 'index.html'), '<h1>Ai-D fixture</h1>');
    await writeFile(join(directory, 'main.dart.js'), '/* fixture asset */');
    const hosting = JSON.parse(readFileSync('firebase.json', 'utf8')).hosting;
    server = cliRequire('superstatic').server({
      hostname: '127.0.0.1', port: 0, cwd: directory, stack: 'strict',
      config: {...hosting, public: '.', ignore: []},
    }).listen();
    await once(server, 'listening');
    const origin = `http://127.0.0.1:${server.address().port}`;
    const home = await fetch(`${origin}/index.html`);
    assert.equal(home.status, 200);
    assert.match(await home.text(), /Ai-D fixture/);
    assert.equal(home.headers.get('cache-control'), 'no-store');
    const route = await fetch(`${origin}/journal/example`);
    assert.equal(route.status, 200);
    assert.match(await route.text(), /Ai-D fixture/);
    const asset = await fetch(`${origin}/main.dart.js`);
    assert.match(await asset.text(), /fixture asset/);
    assert.equal(asset.headers.get('cache-control'), 'no-cache');
  } finally {
    if (server) await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
    await rm(directory, {recursive: true, force: true});
  }
});

test('CLI Pub/Sub tracing initializes with patched OpenTelemetry', async () => {
  const {PubSub} = cliRequire('@google-cloud/pubsub');
  const pubsub = new PubSub({projectId: 'demo-ai-d', enableOpenTelemetryTracing: true});
  try {
    assert.match(pubsub.topic('aid-fixture').name, /topics\/aid-fixture$/);
  } finally {
    await pubsub.close();
  }
});
