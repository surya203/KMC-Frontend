# Run Flutter web dev server and show host links in the terminal.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = "Stop"
$FrontendRoot = $PSScriptRoot | Split-Path -Parent
$Port = if ($env:KMC_WEB_PORT) { $env:KMC_WEB_PORT } else { "5173" }
$HostIp = "200.141.2.90"

Set-Location $FrontendRoot

Write-Host ""
Write-Host "KMC Alumni Connect — Frontend" -ForegroundColor Cyan
Write-Host "  App:           http://${HostIp}:$Port" -ForegroundColor Green
Write-Host "  Registration:  http://${HostIp}:$Port#/membership" -ForegroundColor Green
Write-Host "  Login:         http://${HostIp}:$Port#/auth" -ForegroundColor Green
Write-Host "  Dashboard:     http://${HostIp}:$Port#/dashboard" -ForegroundColor Green
Write-Host "  My Profile:    http://${HostIp}:$Port#/my-profile" -ForegroundColor Green
Write-Host "  My Membership: http://${HostIp}:$Port#/my-membership" -ForegroundColor Green
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
} -ArgumentList $Port, "http://${HostIp}:$Port"

try {
    flutter run -d web-server --web-hostname=0.0.0.0 --web-port $Port
} finally {
    Stop-Job $openBrowser -ErrorAction SilentlyContinue
    Remove-Job $openBrowser -Force -ErrorAction SilentlyContinue
}
