# Backup script for Khang Cloud Windows
$ErrorActionPreference = 'SilentlyContinue'

$dest = "$env:USERPROFILE\Desktop\Backup_Temp"
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Path $dest | Out-Null

Write-Host "1. Sao chep hinh nen va Theme..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$dest\Themes" | Out-Null
Copy-Item "$env:APPDATA\Microsoft\Windows\Themes\*" -Destination "$dest\Themes" -Recurse -Force
Copy-Item "$env:LOCALAPPDATA\Microsoft\Windows\Themes\*" -Destination "$dest\Themes" -Recurse -Force

Write-Host "2. Sao chep icon Taskbar..." -ForegroundColor Cyan
$tb = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
if (Test-Path $tb) {
    New-Item -ItemType Directory -Path "$dest\TaskBar" | Out-Null
    Copy-Item "$tb\*" -Destination "$dest\TaskBar" -Recurse -Force
}

Write-Host "3. Sao chep Desktop, Downloads, Documents..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path "$dest\Desktop" | Out-Null
Get-ChildItem "$env:USERPROFILE\Desktop" -Exclude "Backup_Temp*","*.zip" | Copy-Item -Destination "$dest\Desktop" -Recurse -Force
Copy-Item "$env:USERPROFILE\Downloads" -Destination "$dest\Downloads" -Recurse -Force
Copy-Item "$env:USERPROFILE\Documents" -Destination "$dest\Documents" -Recurse -Force

Write-Host "4. Xuat Registry Theme, Personalize va Taskbar..." -ForegroundColor Cyan
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes" "$dest\themes.reg" /y
reg export "HKCU\Control Panel\Desktop" "$dest\desktop.reg" /y
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" "$dest\accent.reg" /y
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" "$dest\taskband.reg" /y

Write-Host "5. Dong goi thanh file ZIP..." -ForegroundColor Cyan
$zipFile = "$env:USERPROFILE\Desktop\KHANG_CLOUD_BACKUP.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
Compress-Archive -Path "$dest\*" -DestinationPath $zipFile -Force
Remove-Item $dest -Recurse -Force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "🎉 DA TAO THANH CONG TEP: KHANG_CLOUD_BACKUP.zip" -ForegroundColor Green
Write-Host "👉 TEP NAM NGAY NGOAI MAN HINH DESKTOP!" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
