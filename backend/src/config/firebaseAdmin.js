require('dotenv').config();

const {
  applicationDefault,
  getApps,
  initializeApp,
} = require('firebase-admin/app');

const { getAuth } = require('firebase-admin/auth');

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
  });
}

const firebaseAdminAuth = getAuth();

module.exports = {
  firebaseAdminAuth,
};