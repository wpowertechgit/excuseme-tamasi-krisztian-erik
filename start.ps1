[CmdletBinding()]
param(
    [switch]$ReuseCurrentWindow
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverDir = Join-Path $root 'server'
$mobileDir = Join-Path $root 'mobile'
$venvPython = Join-Path $serverDir '.venv\Scripts\python.exe'
$firebaseCredentials = 'C:\Users\karol\OneDrive\Dokumentumok\Android\excuse-me-36401-firebase-adminsdk-fbsvc-97cf1f55d1.json'
$firebaseProjectId = 'excuse-me-36401'

if (-not (Test-Path $venvPython)) {
    throw "Python virtual environment not found at '$venvPython'."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not available on PATH.'
}

if (-not (Test-Path $firebaseCredentials)) {
    throw "Firebase service account JSON not found at '$firebaseCredentials'."
}

$serverCommand = @"
Set-Location '$serverDir'
`$env:GOOGLE_APPLICATION_CREDENTIALS = '$firebaseCredentials'
`$env:FIREBASE_PROJECT_ID = '$firebaseProjectId'
& '$venvPython' -m uvicorn app.main:app --reload --port 8000
"@

$flutterCommand = @"
Set-Location '$mobileDir'
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
"@

if ($ReuseCurrentWindow) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = $firebaseCredentials
    $env:FIREBASE_PROJECT_ID = $firebaseProjectId
    Start-Process -FilePath $venvPython -ArgumentList '-m', 'uvicorn', 'app.main:app', '--reload', '--port', '8000' -WorkingDirectory $serverDir
    Set-Location $mobileDir
    flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
    exit $LASTEXITCODE
}

$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) {
    $pwsh = (Get-Command powershell).Source
}

Start-Process -FilePath $pwsh -ArgumentList '-NoExit', '-Command', $serverCommand -WorkingDirectory $serverDir
Start-Sleep -Seconds 2
Start-Process -FilePath $pwsh -ArgumentList '-NoExit', '-Command', $flutterCommand -WorkingDirectory $mobileDir
