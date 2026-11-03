'use strict';
const fs=require('node:fs');
function validateConfig(config,project){
  if(!config||config.USE_FIREBASE!==true)throw Error('USE_FIREBASE must be true for a connected release.');
  if(config.USE_EMULATORS===true)throw Error('Emulator configuration cannot be deployed as a live app.');
  if(typeof project!=='string'||!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project)||project.startsWith('demo-'))throw Error('Pass your real Firebase project ID explicitly.');
  if(config.FIREBASE_PROJECT_ID!==project)throw Error('Client configuration and deployment project must match.');
  for(const key of ['FIREBASE_API_KEY','FIREBASE_APP_ID','FIREBASE_PROJECT_ID','FIREBASE_MESSAGING_SENDER_ID','FIREBASE_AUTH_DOMAIN','FIREBASE_DATABASE_URL','FIREBASE_STORAGE_BUCKET']){
    if(typeof config[key]!=='string'||!config[key].trim()||/^your-|^placeholder$|^demo-key-/i.test(config[key]))throw Error('Replace the placeholder for '+key+'.');
  }
  if(!/^https:\/\//.test(config.FIREBASE_DATABASE_URL))throw Error('Use the HTTPS Realtime Database URL from your Firebase console.');
  if(config.OPENAI_API_KEY||config.GOOGLE_APPLICATION_CREDENTIALS)throw Error('Server secrets must not be included in the client build configuration.');
  if(config.FUNCTIONS_REGION && config.FUNCTIONS_REGION!=='us-central1')throw Error('The current aiReply backend is deployed in us-central1. Match FUNCTIONS_REGION to that region.');
  return {projectId:project,region:'us-central1'};
}
if(require.main===module){try{const [file,project]=process.argv.slice(2);if(!file||!project)throw Error('Usage: npm run check:deploy -- config/firebase.local.json YOUR_PROJECT_ID');const result=validateConfig(JSON.parse(fs.readFileSync(file,'utf8')),project);console.log('Connected release configuration is ready for project '+result.projectId+'. No services were deployed.');}catch(e){console.error('Deployment setup: '+e.message);process.exitCode=1;}}
module.exports={validateConfig};
