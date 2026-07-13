# Run Flutter web dev server and show localhost links in the terminal.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = "Stop"
$FrontendRoot = $PSScriptRoot | Split-Path -Parent
$Port = if ($env:KMC_WEB_PORT) { $env:KMC_WEB_PORT } else { "5173" }

Set-Location $FrontendRoot

Write-Host ""
Write-Host "KMC Alumni Connect — Frontend" -ForegroundColor Cyan
Write-Host "  App:           http://localhost:$Port" -ForegroundColor Green
Write-Host "  Registration:  http://localhost:$Port/#/membership" -ForegroundColor Green
Write-Host "  Login:         http://localhost:$Port/#/auth" -ForegroundColor Green
Write-Host "  Dashboard:     http://localhost:$Port/#/dashboard" -ForegroundColor Green
Write-Host "  My Profile:    http://localhost:$Port/#/my-profile" -ForegroundColor Green
Write-Host "  My Membership: http://localhost:$Port/#/my-membership" -ForegroundColor Green
Write-Host "  (Browser opens automatically when ready)" -ForegroundColor DarkGray
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
        } catch {}
    }
} -ArgumentList $Port, "http://localhost:$Port"

try {
    flutter run -d web-server --web-port $Port
} finally {
    Stop-Job $openBrowser -ErrorAction SilentlyContinue
    Remove-Job $openBrowser -Force -ErrorAction SilentlyContinue
}
