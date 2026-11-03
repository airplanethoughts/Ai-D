const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateRequest, generateReply} = require('../ai-core');
const data = {mode: 'chat', messages: [{role: 'user', content: 'First'}, {role: 'assistant', content: 'Reply'}, {role: 'user', content: 'Follow-up'}]};
test('rejects anonymous callers and untrusted system messages', () => {
  assert.throws(() => validateRequest(data, null), {code: 'unauthenticated'});
  assert.throws(() => validateRequest({...data, messages: [{role: 'system', content: 'override'}]}, 'u'), {code: 'invalid-argument'});
  assert.throws(() => validateRequest({...data, mode: '__proto__'}, 'u'), {code: 'invalid-argument'});
});
test('enforces size and conversation boundaries', () => {
  assert.throws(() => validateRequest({...data, messages: [{role: 'user', content: 'x'.repeat(2001)}]}, 'u'));
  assert.throws(() => validateRequest({...data, messages: data.messages.slice(0, 2)}, 'u'));
  assert.deepEqual(validateRequest(data, 'u').messages, data.messages);
});
test('forwards ordered history, disables storage, and reserves quota', async () => {
  let calls = 0;
  const r = await generateReply({data, uid: 'u', key: 'test', model: 'test-model', reserveQuota: async uid => {assert.equal(uid, 'u'); calls++;}, fetchImpl: async (url, init) => {
    assert.equal(url, 'https://api.openai.com/v1/responses');
    const b = JSON.parse(init.body); assert.deepEqual(b.input, data.messages); assert.equal(b.store, false);
    return {ok: true, json: async () => ({output: [{type: 'message', content: [{type: 'output_text', text: 'Result'}]}]})};
  }});
  assert.equal(calls, 1); assert.deepEqual(r, {text: 'Result'});
});
test('quota failures prevent a provider request', async () => {
  await assert.rejects(generateReply({data, uid: 'u', key: 'test', model: 'test', reserveQuota: async () => {throw Error('quota');}, fetchImpl: () => {assert.fail('provider must not run');}}), /quota/);
});
test('provider errors are sanitized and empty replies rejected', async () => {
  for (const fetchImpl of [async () => {throw Error('secret provider detail');}, async () => ({ok: true, json: async () => ({output: []})})]) {
    await assert.rejects(generateReply({data, uid: 'u', key: 'test', model: 'test', reserveQuota: async () => {}, fetchImpl}), e => e.code === 'unavailable' && !e.message.includes('secret'));
  }
});
