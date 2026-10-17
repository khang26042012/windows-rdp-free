# ==============================================================================
# KHANG CLOUD - GOLDEN PACK BUILDER (V1.0)
# Dong goi toan bo Ung dung, AppData, Registry, Theme & Cau hinh ca nhan
# ==============================================================================
$ErrorActionPreference = 'SilentlyContinue'

$stage = "C:\KHANG_GOLDEN_STAGING"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path "$stage\Desktop" | Out-Null
New-Item -ItemType Directory -Path "$stage\PublicDesktop" | Out-Null
New-Item -ItemType Directory -Path "$stage\AppData_Roaming" | Out-Null
New-Item -ItemType Directory -Path "$stage\AppData_Local" | Out-Null
New-Item -ItemType Directory -Path "$stage\ProgramFiles" | Out-Null
New-Item -ItemType Directory -Path "$stage\ProgramFiles_x86" | Out-Null
New-Item -ItemType Directory -Path "$stage\ProgramData" | Out-Null
New-Item -ItemType Directory -Path "$stage\Registry" | Out-Null

Write-Host ">>> 1. DANG SAO CHEP DESKTOP VA SHORTCUTS..." -ForegroundColor Cyan
Get-ChildItem "$env:USERPROFILE\Desktop" -Exclude "*.zip","KHANG_*" | Copy-Item -Destination "$stage\Desktop" -Recurse -Force
if (Test-Path "C:\Users\Public\Desktop") {
    Copy-Item "C:\Users\Public\Desktop\*" -Destination "$stage\PublicDesktop" -Recurse -Force
}

Write-Host ">>> 2. DANG SAO CHEP APPDATA (ROAMING & LOCAL CONFIGS)..." -ForegroundColor Cyan
# Roaming
Copy-Item "$env:APPDATA\*" -Destination "$stage\AppData_Roaming" -Recurse -Force -Exclude "Microsoft"
New-Item -ItemType Directory -Path "$stage\AppData_Roaming\Microsoft\Windows" | Out-Null
Copy-Item "$env:APPDATA\Microsoft\Windows\Themes" -Destination "$stage\AppData_Roaming\Microsoft\Windows" -Recurse -Force
Copy-Item "$env:APPDATA\Microsoft\Internet Explorer" -Destination "$stage\AppData_Roaming\Microsoft" -Recurse -Force

# Local (Lay cac thu muc ung dung chu yeu)
$targetLocal = @("Discord", "Kingsoft", "Lively Wallpaper", "Windhawk", "Programs", "UnityHub", "Google", "Mozilla")
foreach ($app in $targetLocal) {
    $p = "$env:LOCALAPPDATA\$app"
    if (Test-Path $p) {
        Write-Host "   -> Sao chep Local\$app..." -ForegroundColor Gray
        Copy-Item $p -Destination "$stage\AppData_Local" -Recurse -Force
    }
}

Write-Host ">>> 3. DANG SAO CHEP CAC PHAN MEM DA CAI DAT (PROGRAM FILES)..." -ForegroundColor Cyan
$targetPF = @("Windhawk", "Lively Wallpaper", "Unity Hub", "Mozilla Firefox", "Google", "Kingsoft", "R")
foreach ($app in $targetPF) {
    $p1 = "C:\Program Files\$app"
    if (Test-Path $p1) {
        Write-Host "   -> Program Files\$app..." -ForegroundColor Gray
        Copy-Item $p1 -Destination "$stage\ProgramFiles" -Recurse -Force
    }
    $p2 = "C:\Program Files (x86)\$app"
    if (Test-Path $p2) {
        Write-Host "   -> Program Files (x86)\$app..." -ForegroundColor Gray
        Copy-Item $p2 -Destination "$stage\ProgramFiles_x86" -Recurse -Force
    }
}

# ProgramData (Windhawk, etc.)
if (Test-Path "C:\ProgramData\Windhawk") {
    Copy-Item "C:\ProgramData\Windhawk" -Destination "$stage\ProgramData" -Recurse -Force
}

Write-Host ">>> 4. XUAT TOAN BO REGISTRY HE THONG & GIAO DIEN..." -ForegroundColor Cyan
reg export "HKCU\Software" "$stage\Registry\hkcu_software.reg" /y
reg export "HKCU\Control Panel\Desktop" "$stage\Registry\desktop.reg" /y
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes" "$stage\Registry\themes.reg" /y
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "$stage\Registry\accent.reg" /y
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" "$stage\Registry\taskband.reg" /y
reg export "HKLM\Software\Windhawk" "$stage\Registry\hklm_windhawk.reg" /y

Write-Host ">>> 5. TAO KICH BAN KHOI PHUC TU DONG (RESTORE.PS1)..." -ForegroundColor Cyan
$restoreContent = @'
# RESTORE SCRIPT FOR GOLDEN PACK
$ErrorActionPreference = 'SilentlyContinue'
$src = $PSScriptRoot

Write-Host "Dang phuc hoi Desktop & Shortcuts..." -ForegroundColor Cyan
Copy-Item "$srcDesktop*" -Destination "$env:USERPROFILEDesktop" -Recurse -Force
if (Test-Path "$srcPublicDesktop") {
    Copy-Item "$srcPublicDesktop*" -Destination "C:UsersPublicDesktop" -Recurse -Force
}

Write-Host "Dang phuc hoi Program Files..." -ForegroundColor Cyan
Copy-Item "$srcProgramFiles*" -Destination "C:Program Files" -Recurse -Force
Copy-Item "$srcProgramFiles_x86*" -Destination "C:Program Files (x86)" -Recurse -Force
if (Test-Path "$srcProgramDataWindhawk") {
    Copy-Item "$srcProgramDataWindhawk" -Destination "C:ProgramData" -Recurse -Force
}

Write-Host "Dang phuc hoi AppData..." -ForegroundColor Cyan
Copy-Item "$srcAppData_Roaming*" -Destination "$env:APPDATA" -Recurse -Force
Copy-Item "$srcAppData_Local*" -Destination "$env:LOCALAPPDATA" -Recurse -Force

Write-Host "Dang nap Registry..." -ForegroundColor Cyan
Get-ChildItem "$srcRegistry*.reg" | ForEach-Object {
    reg import $_.FullName
}

Write-Host "Khoi dong lai Explorer & Windhawk..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer.exe

if (Test-Path "C:Program FilesWindhawkwindhawk.exe") {
    Start-Process "C:Program FilesWindhawkwindhawk.exe" -ArgumentList "-tray"
}
Write-Host "🎉 PHUC HOI THANH CONG 100%!" -ForegroundColor Green
'@
Set-Content -Path "$stage\restore.ps1" -Value $restoreContent -Encoding UTF8

Write-Host ">>> 6. DANG NEN THANH TEP GOLDEN PACK..." -ForegroundColor Cyan
$zipOutput = "$env:USERPROFILE\Desktop\KHANG_GOLDEN_PACK.zip"
if (Test-Path $zipOutput) { Remove-Item $zipOutput -Force }

# Uu tien dung 7z neu co de nen nhanh va chat luong hon
$7z = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $7z)) { $7z = "C:\ProgramData\chocolatey\bin\7z.exe" }

if (Test-Path $7z) {
    Write-Host "   (Nen bang 7-Zip toc do cao...)" -ForegroundColor Gray
    & $7z a -tzip -mx=3 "$zipOutput" "$stage\*"
} else {
    Write-Host "   (Nen bang Compress-Archive...)" -ForegroundColor Gray
    Compress-Archive -Path "$stage\*" -DestinationPath "$zipOutput" -Force
}

Remove-Item $stage -Recurse -Force

$fileSizeMB = [math]::Round((Get-Item $zipOutput).Length / 1MB, 2)

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "🎉 DA DONG GOI XONG GOLDEN PACK THANH CONG!" -ForegroundColor Green
Write-Host "👉 TEP LUU TAI: $zipOutput" -ForegroundColor Yellow
Write-Host "📊 DUNG LUONG: $fileSizeMB MB" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
