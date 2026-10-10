# 1. Setup Windows RDP & Tat NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'SecurityLayer' -Value 0

# 2. Create User khangmc
$user = $env:RDP_USER
$pass = $env:RDP_PASS
New-LocalUser -Name $user -Password (ConvertTo-SecureString $pass -AsPlainText -Force) *>$null
Add-LocalGroupMember -Group 'Administrators' -Member $user
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $user
Enable-LocalUser -Name $user
Restart-Service TermService -Force
Write-Host "User $user setup thanh cong va da tat NLA!" -ForegroundColor Green

# 3. Download Bore
Invoke-WebRequest -Uri 'https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-pc-windows-msvc.zip' -OutFile 'bore.zip'
Expand-Archive bore.zip -DestinationPath . -Force
Write-Host 'Bore downloaded OK!' -ForegroundColor Green

# 4. Start Tunnel
Remove-Item 'bore.log' -ErrorAction SilentlyContinue
$process = Start-Process -FilePath '.\bore.exe' -ArgumentList 'local 3389 --to bore.pub' -RedirectStandardOutput 'bore.log' -RedirectStandardError 'bore.err' -PassThru -NoNewWindow
$assignedPort = $null
for ($i = 0; $i -lt 25; $i++) {
    Start-Sleep -Seconds 2
    if (Test-Path 'bore.log') {
        $content = Get-Content 'bore.log' -Raw
        if ($content -match 'bore\.pub:(\d+)') {
            $assignedPort = $matches[1]
            break
        }
    }
}

if (-not $assignedPort) {
    if (Test-Path 'bore.err') { Get-Content 'bore.err' }
    throw 'Khong lay duoc port bore.pub!'
}

Write-Host ''
Write-Host '==========================================================' -ForegroundColor Green
Write-Host 'MAY AO WINDOWS RDP DA SAN SANG KET NOI!' -ForegroundColor Cyan
Write-Host "DIA CHI PC NAME: bore.pub:$assignedPort" -ForegroundColor Yellow
Write-Host "USERNAME: $user" -ForegroundColor Yellow
Write-Host "PASSWORD: $pass" -ForegroundColor Yellow
Write-Host '==========================================================' -ForegroundColor Green
Write-Host ''

Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '## MAY AO WINDOWS RDP DANG HOAT DONG (6 TIENG)'
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "### PC NAME: bore.pub:$assignedPort"
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- **Username:** $user"
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value "- **Password:** $pass"

# 5. Duy tri may ao 6 tieng
$duration = 21600
$interval = 40
$endTime = (Get-Date).AddSeconds($duration)
while ((Get-Date) -lt $endTime) {
    if ($process.HasExited) {
        Write-Host 'Bore dropped. Reconnecting on same port...' -ForegroundColor Yellow
        $args = 'local 3389 --to bore.pub --port ' + $assignedPort
        $process = Start-Process -FilePath '.\bore.exe' -ArgumentList $args -RedirectStandardOutput 'bore.log' -RedirectStandardError 'bore.err' -PassThru -NoNewWindow
        Start-Sleep -Seconds 3
    }
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $client.BeginConnect('bore.pub', [int]$assignedPort, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(3000, $false)
        if ($wait -and $client.Connected) {
            $client.EndConnect($asyncResult)
            $client.Close()
        }
    } catch {}
    Write-Host 'Windows RDP dang hoat dong binh thuong...'
    Start-Sleep -Seconds $interval
}
