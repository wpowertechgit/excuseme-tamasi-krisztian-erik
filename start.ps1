[CmdletBinding()]
param(
    [switch]$ReuseCurrentWindow
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverDir = Join-Path $root 'server'
$mobileDir = Join-Path $root 'mobile'
$venvPython = Join-Path $serverDir '.venv\Scripts\python.exe'

if (-not (Test-Path $venvPython)) {
    throw "Python virtual environment not found at '$venvPython'."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not available on PATH.'
}

$serverCommand = @"
Set-Location '$serverDir'
& '$venvPython' -m uvicorn app.main:app --reload --port 8000
"@

$flutterCommand = @"
Set-Location '$mobileDir'
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
"@

if ($ReuseCurrentWindow) {
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
