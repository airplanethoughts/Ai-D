'use strict';
class RequestError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const prompts = {
  chat: 'You are a supportive reflection companion. Be warm, brief and practical. Do not claim to be a therapist or diagnose. Never promise outcomes. Respect personal boundaries. If immediate danger is described, encourage contacting local emergency support or a trusted person.',
  journal: 'Respond to this journal with a brief, kind reflection and one practical question. Do not diagnose or claim professional expertise.',
  encouragement: 'Offer one brief, grounded reflection prompt. Do not invent facts about the user or promise that everything will be fine.'
};
function validateRequest(data, uid) {
  if (!uid) throw new RequestError('unauthenticated', 'Sign in to use AI.');
  if (!data || !Object.hasOwn(prompts, data.mode) || !Array.isArray(data.messages) || data.messages.length < 1 || data.messages.length > 21) throw new RequestError('invalid-argument', 'Invalid request.');
  let total = 0;
  const messages = data.messages.map((m, i) => {
    if (!m || m.role !== (i % 2 === 0 ? 'user' : 'assistant') || typeof m.content !== 'string' || !m.content.trim() || m.content.length > 2000) throw new RequestError('invalid-argument', 'Invalid conversation.');
    total += m.content.length;
    return {role: m.role, content: m.content.trim()};
  });
  if (messages.at(-1).role !== 'user' || total > 20000) throw new RequestError('invalid-argument', 'Conversation is too long.');
  return {mode: data.mode, messages};
}
async function generateReply({data, uid, key, model, reserveQuota, fetchImpl = fetch}) {
  const {mode, messages} = validateRequest(data, uid);
  if (!key || !model) throw new RequestError('failed-precondition', 'AI is not configured.');
  await reserveQuota(uid);
  let response;
  try {
    response = await fetchImpl('https://api.openai.com/v1/responses', {
      method: 'POST', headers: {'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json'},
      body: JSON.stringify({model, instructions: prompts[mode], input: messages, store: false, max_output_tokens: 500}),
      signal: AbortSignal.timeout(30000)
    });
    if (!response.ok) throw Error('Upstream failed');
    const body = await response.json();
    const text = (body.output || []).filter(item => item.type === 'message').flatMap(item => item.content || []).filter(part => part.type === 'output_text').map(part => part.text).join('\n').trim();
    if (!text) throw Error('Empty response');
    return {text};
  } catch (_) {
    // Never return provider payloads, user text, credentials or internal errors.
    throw new RequestError('unavailable', 'The assistant is unavailable. Please retry later.');
  }
}
module.exports = {RequestError, validateRequest, generateReply};
