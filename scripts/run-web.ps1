# Run Flutter web dev server and show host links in the terminal.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = "Stop"
$FrontendRoot = $PSScriptRoot | Split-Path -Parent
$Port = if ($env:KMC_WEB_PORT) { $env:KMC_WEB_PORT } else { "5173" }
$HostIp = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -like '192.168.*' -or $_.IPAddress -like '10.*' } |
    Select-Object -First 1 -ExpandProperty IPAddress)
if (-not $HostIp) { $HostIp = "127.0.0.1" }
$Url = "http://${HostIp}:${Port}"

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

Set-Location $FrontendRoot

Write-Host ""
Write-Host "KMC Alumni Connect - Frontend" -ForegroundColor Cyan
Write-Host "  App:           $Url" -ForegroundColor Green
Write-Host "  Registration:  $Url#/membership" -ForegroundColor Green
Write-Host "  Login:         $Url#/auth" -ForegroundColor Green
Write-Host "  Dashboard:     $Url#/dashboard" -ForegroundColor Green
Write-Host "  My Profile:    $Url#/my-profile" -ForegroundColor Green
Write-Host "  My Membership: $Url#/my-membership" -ForegroundColor Green
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
        } catch {
            # Server not ready yet.
        }
    }
} -ArgumentList $Port, $Url

try {
    flutter run -d web-server --web-hostname=0.0.0.0 --web-port $Port
} finally {
    Stop-Job $openBrowser -ErrorAction SilentlyContinue
    Remove-Job $openBrowser -Force -ErrorAction SilentlyContinue
}
