const express = require('express');

const {
  getAuthenticatedUser,
  syncFirebaseUser,
  updateAuthenticatedUserProfile,
  uploadAuthenticatedUserProfileImage,
} = require('../controllers/authController');

const {
  authenticateFirebaseUser,
} = require('../middleware/firebaseAuthMiddleware');

const {
  uploadSingleProfileImage,
} = require('../middleware/profileImageUpload');

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

router.post(
  '/profile-image',
  authenticateFirebaseUser,
  uploadSingleProfileImage,
  uploadAuthenticatedUserProfileImage,
);

module.exports = router;