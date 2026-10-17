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
$pass = $env:RDP_PASS
New-LocalUser -Name $user -Password (ConvertTo-SecureString $pass -AsPlainText -Force) *>$null
Add-LocalGroupMember -Group 'Administrators' -Member $user
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $user
Enable-LocalUser -Name $user
Restart-Service TermService -Force
Write-Host 'User setup thanh cong!' -ForegroundColor Green

# 3.5. TU DONG TAI VA KHOI PHUC GOLDEN PACK TU GOOGLE DRIVE
$gdriveId = "1MmWF4PcpjKh4V2UDielgOFJfgiJPtP8D"
if ($gdriveId) {
    try {
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host ">>> DANG TAI GOLDEN PACK TU GOOGLE DRIVE (2.7 GB)..." -ForegroundColor Cyan
        $cookieFile = "$env:TEMP\gdrive_cookie.txt"
        $initHtml = curl.exe -c $cookieFile -s -L "https://drive.google.com/uc?export=download&id=$gdriveId"
        $confirm = ""
        $uuid = ""
        if ($initHtml -match 'name="confirm"\s+value="([^"]+)"') { $confirm = $matches[1] }
        if ($initHtml -match 'name="uuid"\s+value="([^"]+)"') { $uuid = $matches[1] }

        if ($confirm -and $uuid) {
            $downloadUrl = "https://drive.usercontent.google.com/download?id=$gdriveId&export=download&confirm=$confirm&uuid=$uuid"
        } else {
            $downloadUrl = "https://drive.google.com/uc?export=download&id=$gdriveId"
        }

        $zipPath = "C:\KHANG_GOLDEN_PACK.zip"
        $stagingDir = "C:\KHANG_STAGING"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }

        Write-Host "Dang download file zip tu CDN Google..." -ForegroundColor Cyan
        curl.exe -b $cookieFile -L "$downloadUrl" -o "$zipPath"

        if (Test-Path $zipPath) {
            Write-Host "Giai nen Golden Pack..." -ForegroundColor Cyan
            $7z = "C:\Program Files\7-Zip\7z.exe"
            if (Test-Path $7z) {
                & $7z x "$zipPath" -o"$stagingDir" -y | Out-Null
            } else {
                Expand-Archive -Path "$zipPath" -DestinationPath "$stagingDir" -Force
            }

            Write-Host "Trien khai Program Files & ProgramData..." -ForegroundColor Cyan
            if (Test-Path "$stagingDir\ProgramFiles") {
                Copy-Item "$stagingDir\ProgramFiles\*" -Destination "C:\Program Files" -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$stagingDir\ProgramFiles_x86") {
                Copy-Item "$stagingDir\ProgramFiles_x86\*" -Destination "C:\Program Files (x86)" -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$stagingDir\ProgramData") {
                Copy-Item "$stagingDir\ProgramData\*" -Destination "C:\ProgramData" -Recurse -Force -ErrorAction SilentlyContinue
            }

            Write-Host "Trien khai Public Desktop..." -ForegroundColor Cyan
            if (Test-Path "$stagingDir\PublicDesktop") {
                Copy-Item "$stagingDir\PublicDesktop\*" -Destination "C:\Users\Public\Desktop" -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$stagingDir\Desktop") {
                Copy-Item "$stagingDir\Desktop\*" -Destination "C:\Users\Public\Desktop" -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Import HKLM registry
            if (Test-Path "$stagingDir\Registry\hklm_windhawk.reg") {
                reg import "$stagingDir\Registry\hklm_windhawk.reg"
            }

            # Tao script tu dong nap cho khangmc khi dang nhap lan dau
            $startupDir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
            if (-not (Test-Path $startupDir)) { New-Item -ItemType Directory -Path $startupDir -Force | Out-Null }
            $startupCmd = @"
@echo off
if exist "C:\KHANG_STAGING" (
    echo [Khang Cloud] Dang phuc hoi giao dien va cau hinh ca nhan...
    reg import "C:\KHANG_STAGING\Registry\hkcu_software.reg" >nul 2>&1
    reg import "C:\KHANG_STAGING\Registry\desktop.reg" >nul 2>&1
    reg import "C:\KHANG_STAGING\Registry\themes.reg" >nul 2>&1
    reg import "C:\KHANG_STAGING\Registry\accent.reg" >nul 2>&1
    reg import "C:\KHANG_STAGING\Registry\taskband.reg" >nul 2>&1
    if exist "C:\KHANG_STAGING\AppData_Roaming" xcopy "C:\KHANG_STAGING\AppData_Roaming" "%APPDATA%" /E /I /H /Y /Q >nul 2>&1
    if exist "C:\KHANG_STAGING\AppData_Local" xcopy "C:\KHANG_STAGING\AppData_Local" "%LOCALAPPDATA%" /E /I /H /Y /Q >nul 2>&1
    if exist "C:\KHANG_STAGING\Desktop" xcopy "C:\KHANG_STAGING\Desktop" "%USERPROFILE%\Desktop" /E /I /H /Y /Q >nul 2>&1
    taskkill /f /im explorer.exe >nul 2>&1
    start explorer.exe
    if exist "C:\Program Files\Windhawk\windhawk.exe" start "" "C:\Program Files\Windhawk\windhawk.exe" -tray
    del "%~f0"
)
"@
            Set-Content -Path "$startupDir\khang_first_login.cmd" -Value $startupCmd -Encoding ASCII

            # Xoa file zip de tiet kiem dung luong
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Write-Host "🎉 NHOI GOLDEN PACK THANH CONG 100%!" -ForegroundColor Green
            Write-Host "==========================================================" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Loi restore Golden Pack: $_" -ForegroundColor Yellow
    }
}

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
