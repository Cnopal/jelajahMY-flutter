const express = require('express');

const {
  createReview,
  deleteReview,
  getCurrentUserReview,
  getRatingSummary,
  getReviews,
  updateReview,
} = require('../controllers/reviewController');

const {
  authenticateFirebaseUser,
} = require('../middleware/firebaseAuthMiddleware');

const router = express.Router({ mergeParams: true });

router.get('/', getReviews);
router.get('/summary', getRatingSummary);
router.get('/me', authenticateFirebaseUser, getCurrentUserReview);
router.post('/', authenticateFirebaseUser, createReview);
router.put('/:reviewId', authenticateFirebaseUser, updateReview);
router.delete('/:reviewId', authenticateFirebaseUser, deleteReview);

module.exports = router;
