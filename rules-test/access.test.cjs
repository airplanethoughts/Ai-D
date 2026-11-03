const {test, before, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc} = require('firebase/firestore');
const {ref, set, get} = require('firebase/database');
const {ref: storageRef, uploadBytes, getBytes} = require('firebase/storage');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-ai-d',
    firestore: {rules: readFileSync('firestore.rules','utf8')},
    database: {rules: readFileSync('database.rules.json','utf8')},
    storage: {rules: readFileSync('storage.rules','utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
test('users cannot create or promote themselves to administrator', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const profile = doc(db,'JackSocialApp','All Users','Users','alice');
  await assertFails(setDoc(profile, {role:'Admins'}));
  await assertSucceeds(setDoc(profile, {role:'Users'}));
  await assertFails(updateDoc(profile, {role:'Admins'}));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(),'JackSocialApp','All Users','Users','alice')));
});
test('ordinary users cannot publish activities; admin claims can', async () => {
  const data = {title:'A walk',content:'A short walk',postOwner:'admin',date:1,likes:0,comments:[],picURL:''};
  await assertFails(setDoc(doc(env.authenticatedContext('alice').firestore(),'JackSocialAppAdminPosts','one'),data));
  await assertSucceeds(setDoc(doc(env.authenticatedContext('admin',{admin:true}).firestore(),'JackSocialAppAdminPosts','one'),data));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'JackSocialAppAdminPosts','one')));
});
test('journals belong to their authenticated owner', async () => {
  const a=env.authenticatedContext('alice').database(), b=env.authenticatedContext('bob').database();
  await assertSucceeds(set(ref(a,'users/alice/entry'),{date:1,title_for_today:'Today',happiness_level:5}));
  await assertFails(get(ref(b,'users/alice/entry')));
  await assertFails(set(ref(b,'users/alice/entry'),{date:2}));
  await assertFails(set(ref(a,'users/alice/bad'),{date:1,happiness_level:11}));
});
test('private journal images and shared admin activity images have separate access', async () => {
  const a=env.authenticatedContext('alice').storage(), b=env.authenticatedContext('bob').storage();
  await assertSucceeds(uploadBytes(storageRef(a,'JackSocialApp/Users/alice/photo.jpg'),new Uint8Array([1,2]),{contentType:'image/jpeg'}));
  await assertFails(getBytes(storageRef(b,'JackSocialApp/Users/alice/photo.jpg')));
  await assertFails(uploadBytes(storageRef(a,'activities/alice/photo.jpg'),new Uint8Array([1]),{contentType:'image/jpeg'}));
  const admin=env.authenticatedContext('admin',{admin:true}).storage();
  await assertSucceeds(uploadBytes(storageRef(admin,'activities/admin/photo.jpg'),new Uint8Array([1,2]),{contentType:'image/jpeg'}));
  await assertSucceeds(getBytes(storageRef(b,'activities/admin/photo.jpg')));
  await assertFails(uploadBytes(storageRef(a,'JackSocialApp/Users/alice/text.txt'),new Uint8Array([1]),{contentType:'text/plain'}));
});
