# ==============================================================================
# KHANG CLOUD - WINDOWS RDP ULTRA NODE
# Auto-Login | Pre-loaded Profile (Khong can doi load profile) | Golden Pack 8.5GB
# ==============================================================================

# 1. Setup Windows RDP, Tat NLA & Cho phep SSL/TLS (SecurityLayer = 1 Negotiate)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'SecurityLayer' -Value 1

reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server' /v 'fDenyTSConnections' /t REG_DWORD /d 0 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server' /v 'fSingleSessionPerUser' /t REG_DWORD /d 0 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' /v 'UserAuthentication' /t REG_DWORD /d 0 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' /v 'SecurityLayer' /t REG_DWORD /d 1 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' /v 'fPromptForPassword' /t REG_DWORD /d 0 /f
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' /v 'fPromptForPassword' /t REG_DWORD /d 0 /f

# Firewall: Cho phep RDP tren tat ca profile (ke ca mang ao Tailscale)
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
netsh advfirewall firewall add rule name="Allow-RDP-3389" dir=in action=allow protocol=TCP localport=3389 profile=any

# 2. Toi uu hoa toc do & 60 FPS
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' /v 'ColorDepth' /t REG_DWORD /d 3 /f
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' /v 'ColorDepth' /t REG_DWORD /d 3 /f
reg add 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations' /v 'DWMFRAMEINTERVAL' /t REG_DWORD /d 15 /f

# 3. Tao User khangmc, runneradmin va dong bo mat khau
$user = 'khangmc'
$defaultPass = 'KhangSMP@2026'
$pass = if ($env:INPUT_RDP_PASS -and $env:INPUT_RDP_PASS.Trim() -ne '') { 
    $env:INPUT_RDP_PASS.Trim() 
} elseif ($env:SECRET_RDP_PASS -and $env:SECRET_RDP_PASS.Trim() -ne '') { 
    $env:SECRET_RDP_PASS.Trim() 
} elseif ($env:RDP_PASS -and $env:RDP_PASS.Trim() -ne '') { 
    $env:RDP_PASS.Trim() 
} else { 
    $defaultPass 
}
$secPass = ConvertTo-SecureString $pass -AsPlainText -Force

foreach ($u in @($user, 'runneradmin')) {
    $existingUser = Get-LocalUser -Name $u -ErrorAction SilentlyContinue
    if ($existingUser) {
        Set-LocalUser -Name $u -Password $secPass -ErrorAction SilentlyContinue
    } else {
        New-LocalUser -Name $u -Password $secPass -PasswordNeverExpires $true -AccountNeverExpires $true -ErrorAction SilentlyContinue
    }
    Set-LocalUser -Name $u -PasswordNeverExpires $true -AccountNeverExpires $true -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group 'Administrators' -Member $u -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $u -ErrorAction SilentlyContinue
    Enable-LocalUser -Name $u -ErrorAction SilentlyContinue

    # Set dong thoi bang net user bao boc boi dau ngoac kep
    net user $u "$pass" /add /expires:never /active:yes *>$null
    net user $u "$pass" /expires:never /active:yes *>$null
    net localgroup administrators $u /add *>$null
    net localgroup "Remote Desktop Users" $u /add *>$null
}

# 3.1. HÀM AUTO LOGIN WINDOWS (AutoAdminLogon)
# Tu dong dang nhap san khangmc vao he thong ngay khi boot de khong can load profile
function Enable-AutoLogin($u, $p) {
    Write-Host ">>> Kich hoat Auto-Login cho user: $u..." -ForegroundColor Cyan
    $winlogon = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    reg add $winlogon /v 'AutoAdminLogon' /t REG_SZ /d '1' /f
    reg add $winlogon /v 'DefaultUserName' /t REG_SZ /d $u /f
    reg add $winlogon /v 'DefaultPassword' /t REG_SZ /d $p /f
    reg add $winlogon /v 'DefaultDomainName' /t REG_SZ /d '.' /f
    reg add $winlogon /v 'ForceAutoLogon' /t REG_SZ /d '1' /f
}
Enable-AutoLogin $user $pass

Restart-Service TermService -Force
Write-Host 'User setup, Auto-Login & RDP service thanh cong!' -ForegroundColor Green

# 4. Cai dat & Khoi dong Tailscale (Uu tien ket noi truoc de co IP ngay lap tuc)
$tsKey = if ($env:INPUT_TS_KEY) { $env:INPUT_TS_KEY } elseif ($env:SECRET_TS_KEY) { $env:SECRET_TS_KEY } else { $env:TAILSCALE_KEY }
$tsIp = "Chua ket noi"
$tsHostname = if ($env:TS_HOSTNAME) { $env:TS_HOSTNAME } else { 'windows-khang' }

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
            Write-Host "Dang ket noi vao mang Tailscale voi hostname: $tsHostname..." -ForegroundColor Cyan
            & $tsExe up --authkey=$tsKey --hostname=$tsHostname --unattended --accept-routes --reset
            for ($i = 0; $i -lt 15; $i++) {
                Start-Sleep -Seconds 2
                try {
                    $out = (& $tsExe ip -4 2>$null)
                    if ($out -and $out.Trim() -match '^\d+\.\d+\.\d+\.\d+$') {
                        $tsIp = $out.Trim()
                        break
                    }
                } catch {}
            }
            try {
                $tsStatus = (& $tsExe status --json 2>$null | ConvertFrom-Json)
                if ($tsStatus -and $tsStatus.Self -and $tsStatus.Self.HostName) {
                    $tsHostname = $tsStatus.Self.HostName
                }
            } catch {}
            Write-Host "==========================================================" -ForegroundColor Green
            Write-Host "🎉 TAILSCALE DA KET NOI THANH CONG!" -ForegroundColor Green
            Write-Host "IP NOI BO TAILSCALE: $tsIp" -ForegroundColor Yellow
            Write-Host "HOSTNAME THAT SU: $tsHostname" -ForegroundColor Yellow
            Write-Host "==========================================================" -ForegroundColor Green
        } else {
            Write-Host "Khong tim thay tailscale.exe!" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Loi cai dat Tailscale: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Chua cau hinh TAILSCALE_KEY. Chay qua Bore TCP..." -ForegroundColor Yellow
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
Write-Host "   PC Name: $tsIp  (hoac: $tsHostname)" -ForegroundColor Yellow
Write-Host "2. KET NOI DU PHONG QUA BORE:" -ForegroundColor Green
Write-Host "   PC Name: bore.pub:$assignedPort" -ForegroundColor Yellow
Write-Host "USERNAME: $user (hoac .\$user)" -ForegroundColor Yellow
Write-Host "PASSWORD: $pass" -ForegroundColor Yellow
Write-Host '==========================================================' -ForegroundColor Green
Write-Host ''

# 6. Auto publish connection info to GitHub Repo (Ngay lap tuc de nguoi dung lay IP)
$token = $env:GITHUB_TOKEN
$repo = if ($env:REPO_NAME) { $env:REPO_NAME } else { 'khang26042012/windows-rdp-free' }
if ($token) {
    try {
        $ghHeaders = @{
            Authorization = 'Bearer ' + $token
            Accept = 'application/vnd.github.v3+json'
            'User-Agent' = 'RDP-Runner'
        }
        $infoText = "TAILSCALE_IP=$tsIp`nHOSTNAME=$tsHostname`nBORE=bore.pub:$assignedPort`nUSER=$user`nALT_USER=runneradmin`nPASS=$pass`nTIME=" + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
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

# 7. TU DONG TAI VA PRE-LOAD GOLDEN PACK 8.5 GB TU GITHUB RELEASE v1.0.0 (KHONG DUNG GDRIVE 2.7GB CU)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ">>> BAT DAU TAI & PRE-LOAD GOLDEN PACK 8.5 GB (CO SS ANTIGRAVITY)..." -ForegroundColor Cyan

$fastDrive = if (Test-Path "D:\") { "D:\" } else { "C:\" }
$workDir = Join-Path $fastDrive "KHANG_TEMP_RESTORE"
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$releaseDir = Join-Path $workDir "ReleaseParts"
$stagingDir = Join-Path $workDir "Staging"
$zipPath = Join-Path $workDir "KHANG_GOLDEN_PACK.zip"

try {
    $env:GH_TOKEN = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $token }
    Write-Host "Dang tai cac phan Golden Pack tu GitHub Release v1.0.0 (toc do cao)..." -ForegroundColor Cyan
    
    # Uu tien tai tu repo hien tai, neu khong co fallback sang windows-rdp-test
    $dlSuccess = $false
    try {
        gh release download v1.0.0 --repo $repo --dir $releaseDir
        $dlSuccess = $true
    } catch {
        Write-Host "Thu tai tu repo khang26042012/windows-rdp-test..." -ForegroundColor Gray
        gh release download v1.0.0 --repo khang26042012/windows-rdp-test --dir $releaseDir
        $dlSuccess = $true
    }

    if (Test-Path $releaseDir) {
        Write-Host "Ghep cac phan thanh file zip hoan chinh..." -ForegroundColor Cyan
        cmd.exe /c "copy /b `"$releaseDir\KHANG_GOLDEN_PACK.part1`" + `"$releaseDir\KHANG_GOLDEN_PACK.part2`" + `"$releaseDir\KHANG_GOLDEN_PACK.part3`" `"$zipPath`"" | Out-Null
        Remove-Item $releaseDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $zipPath) {
        Write-Host "Giai nen Golden Pack (8.5 GB, 76.500 tep)..." -ForegroundColor Cyan
        $7z = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $7z) {
            & $7z x "$zipPath" -o"$stagingDir" -y | Out-Null
        } else {
            Expand-Archive -Path "$zipPath" -DestinationPath "$stagingDir" -Force
        }

        # Xoa ngay file zip sau khi giai nen de tiet kiem dung luong
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        Write-Host ">>> DANG PRE-LOAD PROFILE KHONG CAN CHO DOI KHI DANG NHAP..." -ForegroundColor Cyan
        
        # 1. Trien khai Program Files & ProgramData
        if (Test-Path "$stagingDir\ProgramFiles") {
            Copy-Item "$stagingDir\ProgramFiles\*" -Destination "C:\Program Files" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$stagingDir\ProgramFiles_x86") {
            Copy-Item "$stagingDir\ProgramFiles_x86\*" -Destination "C:\Program Files (x86)" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$stagingDir\ProgramData") {
            Copy-Item "$stagingDir\ProgramData\*" -Destination "C:\ProgramData" -Recurse -Force -ErrorAction SilentlyContinue
        }

        # 2. Trien khai Desktop (Public, khangmc va runneradmin)
        if (Test-Path "$stagingDir\PublicDesktop") {
            Copy-Item "$stagingDir\PublicDesktop\*" -Destination "C:\Users\Public\Desktop" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$stagingDir\Desktop") {
            Copy-Item "$stagingDir\Desktop\*" -Destination "C:\Users\Public\Desktop" -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item "$stagingDir\Desktop\*" -Destination "$env:USERPROFILE\Desktop" -Recurse -Force -ErrorAction SilentlyContinue
        }

        # 3. Pre-load AppData (Default template & User profiles)
        $targets = @("C:\Users\Default", "$env:USERPROFILE")
        if (Test-Path "C:\Users\$user") { $targets += "C:\Users\$user" }

        foreach ($t in $targets) {
            if (Test-Path "$stagingDir\AppData_Roaming") {
                $roamPath = Join-Path $t "AppData\Roaming"
                if (-not (Test-Path $roamPath)) { New-Item -ItemType Directory -Path $roamPath -Force | Out-Null }
                Copy-Item "$stagingDir\AppData_Roaming\*" -Destination $roamPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$stagingDir\AppData_Local") {
                $localPath = Join-Path $t "AppData\Local"
                if (-not (Test-Path $localPath)) { New-Item -ItemType Directory -Path $localPath -Force | Out-Null }
                Copy-Item "$stagingDir\AppData_Local\*" -Destination $localPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # 4. Nap truc tiep toan bo Registry (Software, Desktop, Themes, Accent, Taskband, Windhawk)
        if (Test-Path "$stagingDir\Registry") {
            Get-ChildItem "$stagingDir\Registry\*.reg" | ForEach-Object {
                reg import $_.FullName *>$null
            }
        }

        # 5. Khoi dong Windhawk & Explorer
        if (Test-Path "C:\Program Files\Windhawk\windhawk.exe") {
            Start-Process "C:\Program Files\Windhawk\windhawk.exe" -ArgumentList "-tray" -ErrorAction SilentlyContinue
        }

        # Xoa bo script startup khang_first_login.cmd cu (neu co) de khong bao gio bi load de nua
        $oldStartup = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\khang_first_login.cmd"
        if (Test-Path $oldStartup) { Remove-Item $oldStartup -Force -ErrorAction SilentlyContinue }

        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host "🎉 PRE-LOAD GOLDEN PACK 8.5 GB & AUTO-LOGIN HOAN TAT 100%!" -ForegroundColor Green
        Write-Host "👉 Khong can load profile - RDP ket noi la dung ngay lap tuc!" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
    }
} catch {
    Write-Host "Loi restore Golden Pack: $_" -ForegroundColor Yellow
}

# 8. Duy tri may ao & tu dong hoi sinh bore neu rot mang (6 tieng)
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
