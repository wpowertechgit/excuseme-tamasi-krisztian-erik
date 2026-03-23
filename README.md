# Android Project

## Student Information
Name: Tamasi Krisztian Erik  
Student ID: 115  
Course: Android Development

## Project Title
Excuse Me

## Description
Excuse Me is a mobile app that turns real excuses into funny or serious alibis. Users enter the truth, choose a tone, and the app generates a more polished excuse through the backend.

## Documentation
- LaTeX project documentation: [docs/latex/main.tex](docs/latex/main.tex)
- Compiled PDF version: [docs/latex/main.pdf](docs/latex/main.pdf)

## Features
- Generate excuses in `GOOFY` or `SERIOUS` mode
- Flutter mobile client connected to a FastAPI backend
- Firestore-backed persistence for users, history, and public wall posts
- Public "Wall of Shame" posting and `LOL` reactions
- Admin moderation for public posts

<details>
<summary>More about how the app works</summary>

1. The user enters the real reason.
2. The user selects a tone.
3. The Flutter app sends the request to the FastAPI backend.
4. The backend calls OpenRouter with the project prompt.
5. The generated excuse can be posted publicly for other users to react to.

</details>

## Screenshots
Add screenshots here.

<details>
<summary>Suggested screenshots to include</summary>

- Home screen
- Excuse generator screen
- Generated result in both modes
- Wall of Shame screen
- Admin moderation view

</details>

## Technologies Used
- Dart
- Flutter
- FastAPI
- Python 3.11+
- Firebase / Firestore
- OpenRouter API
- Render

<details>
<summary>Project structure</summary>

```text
excuseme/
|- mobile/   Flutter client
|- server/   FastAPI backend
|- docs/     Architecture and coursework documentation
```

</details>

## How to Run
1. Clone the repository.
2. Open the project in Android Studio or VS Code.
3. Configure the mobile and server environments.
4. Run the app on an emulator, browser, or device.

<details>
<summary>Quick start from repository root</summary>

Run:

```powershell
.\start.ps1
```

Or:

```bat
start.bat
```

This starts the FastAPI server and the Flutter app.

</details>

<details>
<summary>Mobile setup</summary>

1. Install Flutter.
2. Create a Firebase project.
3. Replace the placeholder values in `mobile/lib/firebase_options.dart`.
4. Run:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

</details>

<details>
<summary>Server setup</summary>

1. Install Python 3.11 or newer.
2. Copy `server/.env.example` to `server/.env`.
3. Add the OpenRouter API key.
4. Run:

```bash
cd server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

</details>

<details>
<summary>Admin account and persistence</summary>

- Default persistence is Firestore-backed.
- A seeded admin account is created if it does not already exist.

```text
username: admin
password: adminpass
```

- The admin can moderate and delete public wall posts.
- You can force a mode with:

```bash
PERSISTENCE_BACKEND=firestore
```

or

```bash
PERSISTENCE_BACKEND=memory
```

</details>

<details>
<summary>Backfill older categories</summary>

```bash
cd server
python scripts/backfill_categories.py
```

</details>

## Git Ignore File
This repository includes a `.gitignore` file so build files, environments, IDE files, and generated artifacts are not committed.

<details>
<summary>Included ignore patterns</summary>

```gitignore
*.iml
.gradle
/local.properties
/.idea
/build
/captures
.dart_tool/
.venv/
__pycache__/
.env
```

</details>

## Recommended Rules for Students
- Commit at least once per class and whenever major changes are made
- Commit each feature separately when possible
- Use clear, descriptive commit messages

<details>
<summary>Example commit messages</summary>

- Added excuse generation screen
- Integrated Firestore wall posts
- Fixed backend request validation bug

</details>

## Suggested Code Organization

<details>
<summary>Current repository organization</summary>

```text
mobile/
|- lib/
|- assets/

server/
|- app/
|- scripts/

docs/
|- api.md
|- architecture.md
|- development.md
```

</details>

<details>
<summary>Documentation and deployment files</summary>

- `render.yaml` contains deployment configuration
- `docs/api.md` contains API details
- `docs/architecture.md` contains system architecture notes
- `docs/development.md` contains coursework and workflow notes

</details>
