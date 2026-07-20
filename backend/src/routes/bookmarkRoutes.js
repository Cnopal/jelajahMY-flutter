const express = require('express');

const {
  addBookmark,
  getBookmarks,
  getBookmarkStatus,
  removeBookmark,
} = require('../controllers/bookmarkController');

const {
  authenticateFirebaseUser,
} = require(
  '../middleware/firebaseAuthMiddleware',
);

const router = express.Router();

router.use(authenticateFirebaseUser);

router.get(
  '/',
  getBookmarks,
);

router.get(
  '/status/:attractionId',
  getBookmarkStatus,
);

router.post(
  '/:attractionId',
  addBookmark,
);

router.delete(
  '/:attractionId',
  removeBookmark,
);

module.exports = router;