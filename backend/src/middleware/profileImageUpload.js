const multer = require('multer');

const allowedMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const upload = multer({
  storage: multer.memoryStorage(),

  limits: {
    files: 1,
    fileSize: 10 * 1024 * 1024,
  },

  fileFilter: (
    request,
    file,
    callback,
  ) => {
   
    if (!allowedMimeTypes.has(file.mimetype)) {
      return callback(
        new Error(
          'Only JPEG, PNG and WebP images are allowed.',
        ),
      );
    }

    return callback(null, true);
  },
});

function uploadSingleProfileImage(
  request,
  response,
  next,
) {
  upload.single('image')(
    request,
    response,
    (error) => {
      if (!error) {
        return next();
      }

      if (
        error instanceof multer.MulterError &&
        error.code === 'LIMIT_FILE_SIZE'
      ) {
        return response.status(413).json({
          success: false,
          message:
            'Profile image cannot exceed 5 MB.',
        });
      }

      return response.status(400).json({
        success: false,
        message:
          error.message ||
          'Unable to process the profile image.',
      });
    },
  );
}

module.exports = {
  uploadSingleProfileImage,
};