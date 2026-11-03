'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret, defineString} = require('firebase-functions/params');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {generateReply, RequestError} = require('./ai-core');
initializeApp();
const apiKey = defineSecret('OPENAI_API_KEY');
const model = defineString('OPENAI_MODEL', {description: 'A Responses API model available in your OpenAI project.'});
async function reserveQuota(uid) {
  const day = new Date().toISOString().slice(0, 10);
  const db = getFirestore();
  const ref = db.collection('_aiUsage').doc(`${uid}_${day}`);
  await db.runTransaction(async tx => {
    const snapshot = await tx.get(ref);
    const count = snapshot.data()?.count || 0;
    if (count >= 20) throw new RequestError('resource-exhausted', 'Daily AI request limit reached.');
    tx.set(ref, {count: count + 1, expiresAt: new Date(Date.now() + 2 * 86400000)});
  });
}
exports.aiReply = onCall({secrets: [apiKey], region: 'us-central1', timeoutSeconds: 45, maxInstances: 3}, async request => {
  try {
    return await generateReply({data: request.data, uid: request.auth?.uid, key: apiKey.value(), model: model.value(), reserveQuota});
  } catch (e) {
    throw new HttpsError(e instanceof RequestError ? e.code : 'internal', e instanceof RequestError ? e.message : 'Could not complete this request.');
  }
});
