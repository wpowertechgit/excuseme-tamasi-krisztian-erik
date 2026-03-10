# Architecture

## Stack

- Client: Flutter mobile app in `mobile/`
- Server: FastAPI service in `server/`
- Cloud database: Firebase Firestore
- AI provider: OpenRouter with Gemini model
- Version control: Git monorepo

## Runtime flow

```text
[Flutter App]
  -> POST /api/excuses/generate
[FastAPI Server]
  -> OpenRouter chat completions
[OpenRouter / Gemini]
  -> generated excuse
[FastAPI Server]
  -> JSON response back to client

[Flutter App]
  -> Firestore wall_posts collection
[Firestore]
  -> real-time snapshots for Wall of Shame
```

## Why this satisfies the coursework

- Client-Server: Flutter client communicates with FastAPI over HTTP.
- Cloud: Firestore stores shared wall posts in a hosted database.
- API: FastAPI exposes a documented JSON endpoint.
- Git: all project layers live in one repository with traceable changes.

## Main components

### Mobile client

- Generator screen for truth input and style selection
- Result card with regenerate and post actions
- Wall of Shame screen with real-time Firestore stream and `LOL` increments

### Backend

- Input validation for empty and oversized truth strings
- Fixed server-side prompt to keep AI behavior stable
- OpenRouter integration that hides API keys from the client
- Normalized timeout and upstream failure responses

### Database

- Firestore `wall_posts` collection
- Public v1 access in test mode
- Fields: `truth`, `excuse`, `style`, `language`, `lolCount`, `createdAt`
