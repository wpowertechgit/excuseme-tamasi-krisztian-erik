# Code Summary

## Project Overview

`Excuse Me` is a small monorepo with two main applications:

- `mobile/`: a Flutter client where the user writes a real excuse, asks the backend to turn it into an alibi, and optionally posts it to a shared wall.
- `server/`: a FastAPI backend that validates input, calls OpenRouter, and returns a generated excuse.

There are also supporting docs, startup scripts, deployment config, and tests.

## End-to-End Workflow

### 1. App startup

- The repository root can launch both parts with `start.ps1` or `start.bat`.
- The Flutter app starts in `mobile/lib/main.dart`.
- The FastAPI app starts in `server/app/main.py`.

### 2. Generating an excuse

1. The user types a truth into the text field on the Generator tab in `mobile/lib/main.dart`.
2. The user picks a style with `mobile/lib/widgets/style_switch.dart`.
3. Pressing `SAVE ME` calls `ExcuseApiService.generateExcuse()` from `mobile/lib/services/excuse_api_service.dart`.
4. The Flutter client sends `POST /api/excuses/generate` to the backend.
5. The FastAPI route in `server/app/main.py` validates the request through Pydantic models from `server/app/models.py`.
6. `server/app/openrouter.py`:
   - detects the input language,
   - builds the system and user prompt,
   - sends the request to OpenRouter,
   - retries once if the model responds in the wrong language,
   - returns a normalized response object.
7. The backend responds with JSON containing the generated excuse, detected language, and style.
8. Flutter converts the JSON into `ExcuseResponse` from `mobile/lib/models/excuse_response.dart`.
9. The UI shows the result with `mobile/lib/widgets/result_card.dart`.

### 3. Posting to the wall

1. After generation, the user can press `Post to wall`.
2. `mobile/lib/main.dart` calls `WallService.addPost()` from `mobile/lib/services/wall_service.dart`.
3. That service writes a document into the Firestore `wall_posts` collection.
4. The Wall of Shame tab listens with `WallService.streamPosts()`.
5. Firestore snapshots are converted into `WallPost` model objects from `mobile/lib/models/wall_post.dart`.
6. The wall list updates live, and the `LOL` button increments `lolCount` with `WallService.incrementLol()`.

### 4. Error handling and fallbacks

- The mobile app shows friendly error messages for API failures, timeouts, and missing Firebase setup.
- The server maps upstream model failures to `502` and timeouts to `504`.
- Firebase initialization in Flutter is wrapped in `try/catch`, so the app shell can still open before credentials are configured.

## Repository Root Files

### `README.md`

- Main project introduction and quick-start guide.
- Explains the monorepo layout, core product flow, how to run mobile and server locally, and where the docs live.

### `render.yaml`

- Render deployment configuration for the backend.
- Tells Render to deploy the `server/` directory as a Python web service, install `requirements.txt`, run Uvicorn, and define production env vars.

### `start.ps1`

- PowerShell helper that launches both apps for local development.
- It:
  - finds the repo root,
  - checks that the server virtual environment exists,
  - checks Flutter availability,
  - starts FastAPI in one terminal,
  - starts Flutter web in another terminal,
  - or optionally reuses the current window for the Flutter process.

### `start.bat`

- Small Windows batch wrapper around `start.ps1`.
- Lets the project be launched by double-clicking or from `cmd`.

### `.gitignore`

- Prevents generated, local, secret, and build files from being committed.
- Notably ignores:
  - Python virtual environments and caches,
  - Flutter build/tooling output,
  - `.env`,
  - `mobile/lib/firebase_options.dart`.

## Documentation Files

### `docs/architecture.md`

- High-level architecture note.
- Describes the stack, runtime data flow, major app components, and why the project satisfies the intended coursework goals.

### `docs/api.md`

- API contract for the backend.
- Defines the request body, response shape, validation rules, and expected error codes for `POST /api/excuses/generate`.

### `docs/development.md`

- Development workflow notes.
- Covers suggested Git usage, Render deployment setup, Firebase setup, and a short manual acceptance checklist.

## Server Files

### `server/requirements.txt`

- Python dependency list for the backend.
- Includes FastAPI, Uvicorn, HTTP client support, Pydantic settings, and test libraries.

### `server/app/__init__.py`

- Minimal package marker.
- Exposes `main` through `__all__`, making the app package cleaner to import from.

### `server/app/config.py`

- Centralized configuration loader.
- `Settings` extends `BaseSettings`, so values come from environment variables or `.env`.
- `get_settings()` uses `@lru_cache` so configuration is created once and reused.
- Main settings:
  - `APP_ENV`
  - `OPENROUTER_API_KEY`
  - `OPENROUTER_MODEL`
  - `OPENROUTER_TIMEOUT_SECONDS`

### `server/app/models.py`

- Pydantic models and the shared style enum for the API.
- `AlibiStyle` restricts style values to `goofy` or `serious`.
- `GenerateExcuseRequest`:
  - enforces `truth` length,
  - trims whitespace,
  - rejects empty-only input.
- `GenerateExcuseResponse` defines the success response.
- `ErrorResponse` defines the error payload shape.

### `server/app/openrouter.py`

- Core backend integration with OpenRouter.
- Important pieces:
  - `SYSTEM_PROMPT`: fixed behavior instructions sent to the model.
  - `LANGUAGE_HINTS`: simple rule-based detection hints for `hu`, `es`, `pl`, and `en`.
  - `_detect_language()`: scores the input text by character patterns and common words.
  - `_build_messages()`: creates the chat payload for the model, including retry guidance if language mismatches.
  - `OpenRouterClient.generate_excuse()`: public method that chooses or creates an `httpx.AsyncClient`.
  - `_generate_with_client()`: sends the request, checks returned language, and retries once if needed.
  - `_send_request()`: performs the HTTP POST, normalizes HTTP and timeout failures, and extracts the generated message text.
- This file contains most of the backend business logic.

### `server/app/main.py`

- FastAPI application entry point.
- Creates the app object, enables permissive CORS, and defines the HTTP routes.
- `get_openrouter_client()` wires settings into a client instance through FastAPI dependency injection.
- `/health` returns a simple status check.
- `/api/excuses/generate`:
  - accepts validated request data,
  - calls `OpenRouterClient.generate_excuse()`,
  - converts upstream errors into user-facing `502` or `504` responses.

## Server Tests

### `server/tests/test_main.py`

- API route tests for the FastAPI app.
- Uses `httpx.AsyncClient` with `ASGITransport` to test the app in memory without starting a real server.
- Replaces the OpenRouter dependency with a stub so tests can focus on endpoint behavior.
- Verifies:
  - successful generation,
  - empty input rejection,
  - timeout mapping to `504`,
  - upstream failure mapping to `502`.

### `server/tests/test_openrouter.py`

- Unit tests for `OpenRouterClient`.
- Uses a fake HTTP client to simulate OpenRouter responses.
- Verifies:
  - JSON response parsing,
  - empty model output rejection,
  - retry behavior when the first answer is in the wrong language.

## Mobile Files

### `mobile/pubspec.yaml`

- Flutter package manifest.
- Defines the app name, SDK range, runtime dependencies, and test/lint dependencies.
- Key packages:
  - `firebase_core`
  - `cloud_firestore`
  - `http`
  - `intl`
  - `google_fonts`

### `mobile/analysis_options.yaml`

- Flutter/Dart lint configuration.
- Imports the standard Flutter lint set and enforces single quotes.

### `mobile/firebase.json`

- FlutterFire metadata file.
- Points FlutterFire tooling to the expected generated file `lib/firebase_options.dart` and stores Firebase project/platform identifiers.
- This is configuration metadata, not runtime app logic.

### `mobile/lib/main.dart`

- Main Flutter application and most of the screen-level UI logic.
- Responsibilities:
  - initializes Firebase if config exists,
  - starts the app,
  - holds the selected visual theme,
  - builds the two-tab interface,
  - manages generator state,
  - handles API calls,
  - handles Firestore posting,
  - renders the wall stream.
- Important state fields:
  - `_selectedStyle`
  - `_response`
  - `_isGenerating`
  - `_isPosting`
  - `_error`
- Important methods:
  - `_generate()`: calls the backend and updates UI state.
  - `_postCurrent()`: writes the latest result to Firestore.
- The file also defines:
  - `ExcuseMeApp`
  - `ExcuseHomePage`
  - `_GeneratorTab`
  - `_WallTab`

### `mobile/lib/models/alibi_style.dart`

- Frontend enum for the two excuse styles.
- Adds convenience getters for:
  - `apiValue`: exact value sent to the backend,
  - `label`: UI label,
  - `description`: helper text shown in the UI.

### `mobile/lib/models/app_visual_theme.dart`

- Enum for visual theme modes.
- Provides display labels and short descriptions used by the theme switcher.

### `mobile/lib/models/excuse_response.dart`

- Lightweight data model for backend responses.
- `fromJson()` converts API JSON into a Dart object with fallback values.

### `mobile/lib/models/wall_post.dart`

- Data model for Firestore wall documents.
- `fromSnapshot()` converts a Firestore document snapshot into a strongly shaped Dart object, including timestamp conversion.

### `mobile/lib/services/excuse_api_service.dart`

- HTTP client layer for excuse generation.
- Reads the backend base URL from the `API_BASE_URL` compile-time define, with emulator-friendly fallback.
- `generateExcuse()`:
  - trims input,
  - rejects empty text locally,
  - posts JSON to the server,
  - applies a 15-second timeout,
  - converts error responses into `ExcuseApiException`,
  - converts success responses into `ExcuseResponse`.

### `mobile/lib/services/wall_service.dart`

- Firestore access layer.
- Encapsulates all wall database operations:
  - `streamPosts()`
  - `addPost()`
  - `incrementLol()`
- Also supports injected override handlers, which makes UI testing easier because tests can avoid real Firestore.

### `mobile/lib/theme/app_theme.dart`

- Centralized theme system for the Flutter app.
- Defines three `AppPalette` objects:
  - default neon mode,
  - dark mode,
  - apple-like light mode.
- `themeFor()` chooses the correct `ThemeData`.
- `_buildTheme()` applies typography, colors, cards, input styles, chips, buttons, and tab styling.
- `AppPalette` is a custom `ThemeExtension`, so custom colors can be accessed anywhere through `Theme.of(context)`.

## Mobile Widgets

### `mobile/lib/widgets/neon_button.dart`

- Reusable CTA button widget.
- Wraps `ElevatedButton.icon` inside a styled animated container.
- Adds gradient background, glow-like shadow, and a spinner when `isBusy` is true.

### `mobile/lib/widgets/result_card.dart`

- Displays the generated excuse result.
- Shows:
  - selected style,
  - detected language,
  - original truth,
  - generated alibi,
  - actions to regenerate or post to wall.

### `mobile/lib/widgets/style_switch.dart`

- Selector UI for `GOOFY` vs `SERIOUS`.
- Renders a row of option cards from the enum values and highlights the currently selected one.
- The private `_StyleOptionCard` handles tap interaction and animated visual state.

### `mobile/lib/widgets/theme_mode_switch.dart`

- Selector UI for visual themes.
- Builds one card per `AppVisualTheme` value and calls back when the user changes theme.
- The private `_ThemeOptionCard` handles the per-option visuals and interactions.

## Mobile Test

### `mobile/test/widget_test.dart`

- Widget tests for the main screen.
- Uses fake services instead of real backend and Firebase calls.
- Verifies:
  - the main button stays disabled for empty input,
  - generation shows returned text,
  - the wall tab displays streamed posts and LOL counts.

## Important Missing or Generated File

### `mobile/lib/firebase_options.dart`

- This file is referenced by `mobile/lib/main.dart` and by `mobile/firebase.json`, but it is not tracked in the repository.
- `.gitignore` excludes it, which suggests it must be generated locally with FlutterFire for each developer environment.
- The app is coded to tolerate that setup not being ready yet by catching Firebase initialization errors.

## How the Code Is Organized

- Validation and API contract live on the server in Pydantic models.
- AI prompt creation and upstream request handling are isolated in a dedicated OpenRouter client.
- Flutter keeps UI, models, services, theme, and reusable widgets in separate folders.
- Tests use dependency injection and fake services so most behavior can be verified without real network or database access.

## Practical Reading Order

If you want to understand the project quickly, read in this order:

1. `README.md`
2. `server/app/main.py`
3. `server/app/openrouter.py`
4. `mobile/lib/main.dart`
5. `mobile/lib/services/excuse_api_service.dart`
6. `mobile/lib/services/wall_service.dart`
7. `mobile/test/widget_test.dart`
8. `server/tests/test_main.py`
