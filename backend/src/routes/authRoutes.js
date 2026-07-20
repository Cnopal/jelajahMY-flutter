const express = require('express');

const {
  getAuthenticatedUser,
  syncFirebaseUser,
  updateAuthenticatedUserProfile,
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

router.put(
  '/profile',
  authenticateFirebaseUser,
  updateAuthenticatedUserProfile,
);

module.exports = router;