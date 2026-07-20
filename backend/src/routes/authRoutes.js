const express = require('express');

const {
  getAuthenticatedUser,
  syncFirebaseUser,
} = require('../controllers/authController');

const {
  authenticateFirebaseUser,
} = require(
  '../middleware/firebaseAuthMiddleware',
);

const router = express.Router();

router.post(
  '/sync',
  authenticateFirebaseUser,
  syncFirebaseUser,
);

router.get(
  '/me',
  authenticateFirebaseUser,
  getAuthenticatedUser,
);

module.exports = router;