# Excuse Me

Turning your pathetic truths into legendary alibis.

## Monorepo layout

- `mobile/`: Flutter client
- `server/`: FastAPI backend
- `docs/`: architecture and coursework documentation

## Product flow

1. User enters the real reason.
2. User picks `GOOFY` or `SERIOUS`.
3. Flutter calls the FastAPI backend.
4. FastAPI calls OpenRouter with the fixed Alibi Architect prompt.
5. User can publish the result to Firestore Wall of Shame and other users can hit `LOL`.

## Local setup

### Mobile

1. Install Flutter.
2. Create a Firebase project and replace the placeholder values in `mobile/lib/firebase_options.dart`.
3. Run:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Server

1. Install Python 3.11+.
2. Copy `server/.env.example` to `server/.env`.
3. Fill in your OpenRouter API key.
4. Run:

```bash
cd server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Deployment and docs

- Render deployment config lives in `render.yaml`
- API details: `docs/api.md`
- System architecture: `docs/architecture.md`
- Coursework and workflow notes: `docs/development.md`
