const functions = require('firebase-functions');
const admin = require('firebase-admin');

const { createApp } = require('./src/app');

admin.initializeApp();

const app = createApp({ admin });

exports.api = functions.https.onRequest(app);
