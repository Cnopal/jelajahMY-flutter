const {
  firebaseAdminAuth,
} = require('../config/firebaseAdmin');

async function authenticateFirebaseUser(
  request,
  response,
  next,
) {
  const authorizationHeader =
    request.headers.authorization;

  if (
    !authorizationHeader ||
    !authorizationHeader.startsWith('Bearer ')
  ) {
    return response.status(401).json({
      success: false,
      message:
        'Authentication token is required.',
    });
  }

  const idToken = authorizationHeader
    .substring('Bearer '.length)
    .trim();

  if (!idToken) {
    return response.status(401).json({
      success: false,
      message:
        'Authentication token is required.',
    });
  }

  try {
    const decodedToken =
      await firebaseAdminAuth.verifyIdToken(
        idToken,
      );

    request.firebaseUser = decodedToken;

    return next();
  } catch (error) {
    console.error(
      'Firebase token verification failed:',
      error.code ?? error.message,
    );

    return response.status(401).json({
      success: false,
      message:
        'The authentication token is invalid or expired.',
    });
  }
}

module.exports = {
  authenticateFirebaseUser,
};