const express = require('express');

const {
  addTripItem,
  createTrip,
  deleteTrip,
  getTrip,
  getTrips,
  removeTripItem,
  updateItinerary,
  updateTrip,
} = require('../controllers/tripController');

const {
  authenticateFirebaseUser,
} = require('../middleware/firebaseAuthMiddleware');

const router = express.Router();

router.use(authenticateFirebaseUser);

router.get('/', getTrips);
router.post('/', createTrip);
router.get('/:tripId', getTrip);
router.put('/:tripId', updateTrip);
router.delete('/:tripId', deleteTrip);
router.post('/:tripId/items', addTripItem);
router.delete('/:tripId/items/:itemId', removeTripItem);
router.put('/:tripId/itinerary', updateItinerary);

module.exports = router;
