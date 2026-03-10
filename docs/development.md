# Development Notes

## Suggested Git workflow

- `main` stays presentation-ready
- Create short-lived feature branches such as `feature/mobile-ui` or `feature/openrouter-api`
- Use small commits with clear messages:
  - `feat: add excuse generation endpoint`
  - `feat: build wall of shame screen`
  - `docs: add system architecture notes`

## Backend deployment on Render

1. Create a new Web Service from this repository.
2. Set root directory to `server`.
3. Add env vars:
   - `OPENROUTER_API_KEY`
   - `OPENROUTER_MODEL`
   - `OPENROUTER_TIMEOUT_SECONDS`
4. Deploy using `render.yaml`.

## Firebase setup

1. Create a Firebase project.
2. Enable Firestore in test mode.
3. Replace placeholder values in `mobile/lib/firebase_options.dart`.
4. Register Android and iOS apps if you want native builds on devices.

## Manual acceptance checklist

- App opens to a generator screen and wall screen
- `SAVE ME` is disabled until input exists
- Goofy and serious requests both reach the backend
- Returned excuses respect the input language
- Posting writes a wall document with `lolCount = 0`
- Pressing `LOL` increments the counter in Firestore
