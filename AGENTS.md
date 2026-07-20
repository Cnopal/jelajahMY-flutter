# JelajahMY Development Instructions

## Project Overview

JelajahMY is a Malaysian tourism planner built with:

- Flutter Android application
- Node.js and Express backend
- MySQL database
- Firebase Authentication
- Firebase Admin SDK for backend token verification
- Cloudinary for profile images
- Open-Meteo for weather
- OpenStreetMap through flutter_map

## Project Structure

- `mobile/` — Flutter application
- `backend/` — Express REST API
- `database/` — MySQL schema and seed scripts
- `progressProject.md` — current project progress

## Existing Features

Do not rebuild or replace these working modules:

- Firebase registration, login, logout and password reset
- Firebase user synchronization with MySQL
- User profile management
- Cloudinary profile image upload
- Attraction list and details
- Attraction search and filters
- Weather forecast
- OpenStreetMap attraction map
- Authenticated bookmarks

## Architecture Rules

- Continue using CommonJS in the Express backend.
- Continue using `mysql2/promise`.
- Protected routes must use `firebaseAuthMiddleware`.
- Obtain the database user from the verified Firebase UID.
- Never trust a Firebase UID or user ID sent through the request body.
- Flutter network services must use `ApiConfig.baseUrl`.
- Keep UI consistent with the existing Material 3 interface.
- Do not replace existing working architecture or rename major folders.

## Security Rules

Never commit or print:

- `backend/.env`
- Firebase Admin service-account JSON
- Cloudinary API secret
- Database credentials
- Private keys or access tokens

Do not place backend secrets inside Flutter source code.

## Environment Rules

Do not change:

- Flutter or Dart versions
- Gradle versions
- Kotlin versions
- Android package name
- Firebase project configuration
- PUB_CACHE or JAVA_HOME configuration

Do not delete existing database data or recreate the whole schema.

## Required Validation

After Flutter changes, run:

```bash
dart format lib test
flutter analyze
flutter test