# 1. Setup Windows RDP & Tat NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'SecurityLayer' -Value 0

# 2. Toi uu hoa toc do & 60 FPS
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' /v 'ColorDepth' /t REG_DWORD /d 3 /f
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' /v 'ColorDepth' /t REG_DWORD /d 3 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations' /v 'DWMFRAMEINTERVAL' /t REG_DWORD /d 15 /f

# 3. Tao User khangmc
$user = 'khangmc'
$pass = 'KhangSMP@VN2026!'
New-LocalUser -Name $user -Password (ConvertTo-SecureString $pass -AsPlainText -Force) *>$null
Add-LocalGroupMember -Group 'Administrators' -Member $user
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $user
Enable-LocalUser -Name $user
Restart-Service TermService -Force
Write-Host 'User setup thanh cong!' -ForegroundColor Green

# 4. Tai Bore TCP Tunnel
Invoke-WebRequest -Uri 'https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-pc-windows-msvc.zip' -OutFile 'bore.zip'
Expand-Archive bore.zip -DestinationPath . -Force
Write-Host 'Bore downloaded OK!' -ForegroundColor Green

# 5. Khoi chay Tunnel & lay dia chi
Remove-Item 'bore.log' -ErrorAction SilentlyContinue
$process = Start-Process -FilePath '.\bore.exe' -ArgumentList 'local 3389 --to bore.pub' -RedirectStandardOutput 'bore.log' -RedirectStandardError 'bore.err' -PassThru -NoNewWindow
$assignedPort = $null
for ($i = 0; $i -lt 30; $i++) {
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
Write-Host ('DIA CHI PC NAME: bore.pub:' + $assignedPort) -ForegroundColor Yellow
Write-Host ('USERNAME: ' + $user) -ForegroundColor Yellow
Write-Host ('PASSWORD: ' + $pass) -ForegroundColor Yellow
Write-Host '==========================================================' -ForegroundColor Green
Write-Host ''

Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value '## MAY AO WINDOWS RDP DANG HOAT DONG'
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ('### PC NAME: bore.pub:' + $assignedPort)
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ('- Username: ' + $user)
Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ('- Password: ' + $pass)

# 5.1 Auto publish connection info to GitHub Repo
$token = if ($env:PAT_TOKEN) { $env:PAT_TOKEN } else { $env:GITHUB_TOKEN }
$repo = if ($env:REPO_NAME) { $env:REPO_NAME } else { 'khang26042012/windows-rdp-free' }
if ($token) {
    try {
        $ghHeaders = @{
            Authorization = 'Bearer ' + $token
            Accept = 'application/vnd.github.v3+json'
            'User-Agent' = 'RDP-Runner'
        }
        $infoText = "PC_NAME=bore.pub:$assignedPort`nUSER=$user`nPASS=$pass`nPORT=$assignedPort`nTIME=" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($infoText)
        $b64Content = [Convert]::ToBase64String($bytes)
        
        $sha = $null
        try {
            $getReq = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/contents/RDP_ACTIVE.txt" -Headers $ghHeaders -Method Get
            $sha = $getReq.sha
        } catch {}

        $putPayload = @{
            message = "Update live RDP connection: bore.pub:$assignedPort"
            content = $b64Content
        }
        if ($sha) {
            $putPayload["sha"] = $sha
        }
        $jsonPayload = $putPayload | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/contents/RDP_ACTIVE.txt" -Headers $ghHeaders -Method Put -Body $jsonPayload -ContentType 'application/json'
        Write-Host 'Da publish RDP_ACTIVE.txt len GitHub thanh cong!' -ForegroundColor Green
    } catch {
        Write-Host "Loi khi publish len GitHub: $_" -ForegroundColor Yellow
    }
}

# 6. Duy tri may ao & tu dong hoi sinh neu rot mang
$duration = 21600
$interval = 30
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
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait -and $client.Connected) {
            $client.EndConnect($asyncResult)
            $client.Close()
        }
    } catch {}
    Start-Sleep -Seconds $interval
}
