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
$pass = if ($env:RDP_PASS) { $env:RDP_PASS } else { 'KhangSMP@VN2026!' }
New-LocalUser -Name $user -Password (ConvertTo-SecureString $pass -AsPlainText -Force) *>$null
Add-LocalGroupMember -Group 'Administrators' -Member $user
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $user
Enable-LocalUser -Name $user
Restart-Service TermService -Force
Write-Host 'User setup thanh cong!' -ForegroundColor Green

# 4. Cai dat & Khoi dong Tailscale
$tsKey = $env:TAILSCALE_KEY
$tsIp = "Chua ket noi"
if ($tsKey) {
    try {
        Write-Host 'Dang tai Tailscale MSI...' -ForegroundColor Cyan
        Invoke-WebRequest -Uri 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi' -OutFile 'tailscale.msi'
        Write-Host 'Dang cai dat Tailscale MSI...' -ForegroundColor Cyan
        Start-Process msiexec.exe -ArgumentList '/i tailscale.msi /qn /norestart' -Wait
        Start-Sleep -Seconds 6
        
        $tsExe = "${Env:ProgramFiles}\Tailscale\tailscale.exe"
        if (-not (Test-Path $tsExe)) {
            $tsExe = "${Env:ProgramFiles(x86)}\Tailscale\tailscale.exe"
        }
        
        if (Test-Path $tsExe) {
            Write-Host "Dang ket noi vao mang Tailscale..." -ForegroundColor Cyan
            & $tsExe up --authkey=$tsKey --hostname='windows-khang' --unattended --accept-routes --reset
            Start-Sleep -Seconds 4
            $tsIp = (& $tsExe ip -4).Trim()
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "🎉 TAILSCALE DA KET NOI THANH CONG!" -ForegroundColor Green
            Write-Host "IP NOI BO TAILSCALE: $tsIp" -ForegroundColor Yellow
            Write-Host "HOSTNAME: windows-khang" -ForegroundColor Yellow
            Write-Host "==========================================================" -ForegroundColor Green
        } else {
            Write-Host "Khong tim thay tailscale.exe!" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Loi cai dat Tailscale: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Chua cau hinh TAILSCALE_KEY trong GitHub Secrets. Chay qua Bore TCP..." -ForegroundColor Yellow
}

# 5. Tai Bore TCP Tunnel (Du phong song song)
Invoke-WebRequest -Uri 'https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-x86_64-pc-windows-msvc.zip' -OutFile 'bore.zip'
Expand-Archive bore.zip -DestinationPath . -Force
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

Write-Host ''
Write-Host '==========================================================' -ForegroundColor Green
Write-Host 'MAY AO WINDOWS RDP DA SAN SANG KET NOI!' -ForegroundColor Cyan
Write-Host "1. KET NOI SIEU TOC QUA TAILSCALE:" -ForegroundColor Green
Write-Host "   PC Name: $tsIp  (hoac: windows-khang)" -ForegroundColor Yellow
Write-Host "2. KET NOI DU PHONG QUA BORE:" -ForegroundColor Green
Write-Host "   PC Name: bore.pub:$assignedPort" -ForegroundColor Yellow
Write-Host "USERNAME: $user" -ForegroundColor Yellow
Write-Host '==========================================================' -ForegroundColor Green
Write-Host ''

# 6. Auto publish connection info to GitHub Repo
$token = $env:GITHUB_TOKEN
$repo = if ($env:REPO_NAME) { $env:REPO_NAME } else { 'khang26042012/windows-rdp-free' }
if ($token) {
    try {
        $ghHeaders = @{
            Authorization = 'Bearer ' + $token
            Accept = 'application/vnd.github.v3+json'
            'User-Agent' = 'RDP-Runner'
        }
        $infoText = "TAILSCALE_IP=$tsIp`nHOSTNAME=windows-khang`nBORE=bore.pub:$assignedPort`nUSER=$user`nTIME=" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($infoText)
        $b64Content = [Convert]::ToBase64String($bytes)
        
        $sha = $null
        try {
            $getReq = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/contents/RDP_ACTIVE.txt" -Headers $ghHeaders -Method Get
            $sha = $getReq.sha
        } catch {}

        $putPayload = @{
            message = "Update live RDP connection: Tailscale $tsIp | bore.pub:$assignedPort"
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

# 7. Duy tri may ao & tu dong hoi sinh bore neu rot mang
$duration = 21600
$interval = 30
$endTime = (Get-Date).AddSeconds($duration)
while ((Get-Date) -lt $endTime) {
    if ($process -and $process.HasExited -and $assignedPort) {
        Write-Host 'Bore dropped. Reconnecting on same port...' -ForegroundColor Yellow
        $args = 'local 3389 --to bore.pub --port ' + $assignedPort
        $process = Start-Process -FilePath '.\bore.exe' -ArgumentList $args -RedirectStandardOutput 'bore.log' -RedirectStandardError 'bore.err' -PassThru -NoNewWindow
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds $interval
}
