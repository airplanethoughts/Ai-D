'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');

// Loads the real SDKs and deployed entry point; no credentials, network or AI key.
test('updated Firebase SDKs load the callable and construct its quota reference', async () => {
  process.env.GCLOUD_PROJECT = 'demo-ai-d';
  const {aiReply} = require('../index');
  const {getApp, deleteApp} = require('firebase-admin/app');
  const {getFirestore} = require('firebase-admin/firestore');
  const app = getApp();
  try {
    assert.equal(typeof aiReply, 'function');
    assert.equal(aiReply.__endpoint.platform, 'gcfv2');
    assert.ok(aiReply.__endpoint.callableTrigger);
    const db = getFirestore(app);
    assert.equal(db.collection('_aiUsage').doc('test_2026-11-17').path,
      '_aiUsage/test_2026-11-17');
    await db.terminate();
  } finally {
    await deleteApp(app);
  }
});
