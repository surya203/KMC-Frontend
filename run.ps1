# Run KMC Flutter web - keeps server running and opens browser automatically.
# Usage: .\run.ps1

$ErrorActionPreference = "Stop"
$Port = if ($env:KMC_WEB_PORT) { $env:KMC_WEB_PORT } else { "5173" }
$Url = "http://localhost:$Port"

# Ensure Flutter is on PATH (Cursor/old terminals may not have refreshed user PATH yet)
$flutterCandidates = @(
    (Join-Path $env:USERPROFILE "develop\flutter\bin"),
    "C:\Users\DELL\develop\flutter\bin",
    "C:\flutter\bin"
)
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($bin in $flutterCandidates) {
        if (Test-Path (Join-Path $bin "flutter.bat")) {
            $env:Path = "$bin;" + $env:Path
            break
        }
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found. Install it or add flutter\bin to PATH, then open a new terminal." -ForegroundColor Red
    exit 1
}

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "KMC Alumni Connect - Frontend" -ForegroundColor Cyan
Write-Host "  Opening: $Url" -ForegroundColor Green
Write-Host "  (Browser opens when the server is ready - first run may take ~30s)" -ForegroundColor DarkGray
Write-Host "  Keep this terminal open. Press q to stop." -ForegroundColor DarkGray
Write-Host ""

$openBrowser = Start-Job -ScriptBlock {
    param($port, $url)
    for ($i = 0; $i -lt 90; $i++) {
        Start-Sleep -Seconds 2
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.Connect("127.0.0.1", [int]$port)
            $client.Close()
            Start-Process $url
            return
        } catch {
            # Server not ready yet.
        }
    }
} -ArgumentList $Port, $Url

try {
    flutter run -d web-server --web-port $Port
} finally {
    Stop-Job $openBrowser -ErrorAction SilentlyContinue
    Remove-Job $openBrowser -Force -ErrorAction SilentlyContinue
}
