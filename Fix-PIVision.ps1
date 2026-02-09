Write-Host "=== PI VISION UI VALIDATION (SAFE MODE) ===" -ForegroundColor Cyan

# 1. OS Check
Write-Host "`n[1] OS Version"
Get-ComputerInfo | Select-Object OsName, OsVersion

# 2. IIS Installed?
Write-Host "`n[2] IIS Installed?"
Get-WindowsFeature Web-Server | Select Name, InstallState

# 3. Static Content Feature
Write-Host "`n[3] Static Content Feature"
Get-WindowsFeature Web-Static-Content | Select Name, InstallState

# 4. MIME Types Validation (READ ONLY)
Write-Host "`n[4] MIME Types Check"
Import-Module WebAdministration

$mimeList = @("image/svg+xml","application/json","application/font-woff","application/font-woff2")

Get-WebConfigurationProperty `
  -Filter system.webServer/staticContent/mimeMap `
  -Name "." |
Where-Object { $mimeList -contains $_.mimeType } |
Select fileExtension, mimeType

# 5. Check PI Vision Image Folder
$imgPath = "C:\Program Files\PIPC\PIVision\Images"
Write-Host "`n[5] PI Vision Images Folder"
if (Test-Path $imgPath) {
    Write-Host "FOUND: $imgPath" -ForegroundColor Green
    Get-ChildItem $imgPath -Filter *.svg | Select-Object -First 5
} else {
    Write-Host "NOT FOUND: $imgPath" -ForegroundColor Red
}

# 6. Permission Check (READ ONLY)
Write-Host "`n[6] Folder Permission Check"
icacls $imgPath

# 7. IIS App Pool Identity
Write-Host "`n[7] Application Pool Identity"
Get-Item IIS:\AppPools\PIVisionAppPool | Select-Object name, state

# 8. Test SVG via IIS (HEAD request)
Write-Host "`n[8] HTTP SVG Test"
try {
    $r = Invoke-WebRequest `
        -Uri "http://localhost/PIVision/Images/icon.svg" `
        -Method Head `
        -UseBasicParsing
    Write-Host "HTTP STATUS: $($r.StatusCode)" -ForegroundColor Green
}
catch {
    Write-Host "HTTP ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "`n=== VALIDATION DONE (NO SYSTEM CHANGES) ===" -ForegroundColor Cyan
