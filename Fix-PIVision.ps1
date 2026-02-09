Write-Host "=== PI VISION VALIDATION (SAFE MODE) - WINDOWS SERVER 2022 ===" -ForegroundColor Cyan
Write-Host "NO SYSTEM CHANGES WILL BE MADE" -ForegroundColor Yellow
Write-Host ""

Import-Module WebAdministration

# -------------------------------
# 1. OS Check
# -------------------------------
$os = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Host "[OS]" $os
if ($os -notmatch "Windows Server 2022") {
    Write-Host "⚠️  This script is intended for Windows Server 2022" -ForegroundColor Yellow
}

# -------------------------------
# 2. IIS Role
# -------------------------------
Write-Host "`n[IIS]"
if (Get-Service W3SVC -ErrorAction SilentlyContinue) {
    Write-Host "✔ IIS Service exists"
} else {
    Write-Host "❌ IIS NOT INSTALLED" -ForegroundColor Red
}

# -------------------------------
# 3. PI Vision App Exists
# -------------------------------
Write-Host "`n[PI Vision Application]"
$app = Get-WebApplication | Where-Object { $_.Path -eq "/PIVision" }
if ($app) {
    Write-Host "✔ /PIVision application exists"
    Write-Host "  Physical Path:" $app.PhysicalPath
} else {
    Write-Host "❌ /PIVision application NOT FOUND" -ForegroundColor Red
}

# -------------------------------
# 4. AppPool Check
# -------------------------------
Write-Host "`n[Application Pool]"
$pool = Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -match "PIVision" }
if ($pool) {
    Write-Host "✔ AppPool:" $pool.Name
    Write-Host "  Identity:" $pool.processModel.identityType
} else {
    Write-Host "⚠️  PIVision AppPool not found (might be using DefaultAppPool)" -ForegroundColor Yellow
}

# -------------------------------
# 5. Static Content Role
# -------------------------------
Write-Host "`n[Static Content Feature]"
$static = Get-WindowsFeature Web-Static-Content
if ($static.Installed) {
    Write-Host "✔ Static Content installed"
} else {
    Write-Host "❌ Static Content NOT installed" -ForegroundColor Red
}

# -------------------------------
# 6. MIME Types (SERVER LEVEL ONLY)
# -------------------------------
Write-Host "`n[MIME Types - Server Level]"
$mimePath = "IIS:\MimeTypes"
$needed = @("svg","png","woff","woff2","json")

foreach ($ext in $needed) {
    $found = Get-ChildItem $mimePath | Where-Object { $_.fileExtension -eq ".$ext" }
    if ($found) {
        Write-Host "✔ .$ext -> $($found.mimeType)"
    } else {
        Write-Host "❌ .$ext MISSING" -ForegroundColor Red
    }
}

# -------------------------------
# 7. Static File Test (NO MODIFY)
# -------------------------------
Write-Host "`n[SVG HTTP TEST]"
try {
    $test = Invoke-WebRequest "http://localhost/PIVision/images/icons/save.svg" -UseBasicParsing
    Write-Host "✔ SVG reachable (HTTP $($test.StatusCode))"
}
catch {
    Write-Host "❌ SVG FAILED:" $_.Exception.Message -ForegroundColor Red
}

# -------------------------------
# 8. Verdict
# -------------------------------
Write-Host "`n=== VERDICT ===" -ForegroundColor Cyan
Write-Host "Jika:"
Write-Host "- IIS OK"
Write-Host "- Static Content OK"
Write-Host "- SVG bisa dibuka langsung"
Write-Host "- TAPI ICON DI UI MASIH RUSAK"
Write-Host ""
Write-Host "➡️ MASALAH ADA DI:" -ForegroundColor Yellow
Write-Host "   ❗ IIS Configuration INHERITANCE di level /PIVision"
Write-Host ""
Write-Host "VALIDATION DONE (NO SYSTEM CHANGES)" -ForegroundColor Green
