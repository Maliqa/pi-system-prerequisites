Write-Host "===== FINAL FIX PI VISION ICONS - Windows Server 2022 =====" -ForegroundColor Cyan

Import-Module WebAdministration

# ===============================
# 1. ENSURE IIS FEATURES (SAFE)
# ===============================
Write-Host "Checking IIS core features..."

$features = @(
    "Web-Static-Content",
    "Web-Default-Doc",
    "Web-Http-Errors",
    "Web-Http-Redirect"
)

foreach ($f in $features) {
    if ((Get-WindowsFeature $f).InstallState -ne "Installed") {
        Install-WindowsFeature $f
    }
}

# ===============================
# 2. ENABLE STATIC CONTENT
# ===============================
Write-Host "Enabling Static Content..."
Set-WebConfigurationProperty `
 -filter system.webServer/staticContent `
 -name enabled `
 -value True `
 -PSPath IIS:\

# ===============================
# 3. FIX MIME TYPES (CRITICAL)
# ===============================
Write-Host "Fixing MIME Types..."

$mimes = @{
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}

foreach ($ext in $mimes.Keys) {
    if (-not (Get-WebConfiguration "//staticContent/mimeMap[@fileExtension='$ext']")) {
        Add-WebConfiguration `
          -filter system.webServer/staticContent `
          -PSPath IIS:\ `
          -Value @{fileExtension=$ext; mimeType=$mimes[$ext]}
    }
}

# ===============================
# 4. AUTHENTICATION FIX
# ===============================
Write-Host "Fixing Authentication..."

Set-WebConfigurationProperty `
 -filter system.webServer/security/authentication/anonymousAuthentication `
 -name enabled `
 -value True `
 -PSPath "IIS:\Sites\PIVision"

Set-WebConfigurationProperty `
 -filter system.webServer/security/authentication/windowsAuthentication `
 -name enabled `
 -value False `
 -PSPath "IIS:\Sites\PIVision"

# ===============================
# 5. SSL CONTENT FIX (NO MIXED)
# ===============================
Write-Host "Fixing SSL flags..."

Set-WebConfigurationProperty `
 -filter system.webServer/security/access `
 -name sslFlags `
 -value None `
 -PSPath "IIS:\Sites\PIVision"

# ===============================
# 6. PERMISSIONS FIX
# ===============================
Write-Host "Fixing Folder Permissions..."

$paths = @(
 "C:\Program Files\PIPC\PIVision",
 "C:\Program Files\PIPC\PIVision\Content",
 "C:\Program Files\PIPC\PIVision\Images"
)

foreach ($p in $paths) {
    icacls $p /grant "IIS_IUSRS:(OI)(CI)RX" /T
}

# ===============================
# 7. CLEAR IIS CACHE
# ===============================
Write-Host "Clearing IIS cache..."
Stop-Service W3SVC -Force
Remove-Item "C:\inetpub\temp\IIS Temporary Compressed Files\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service W3SVC

# ===============================
# 8. IIS RESET
# ===============================
Write-Host "Restarting IIS..."
iisreset /noforce

Write-Host "===== DONE. REBOOT SERVER RECOMMENDED =====" -ForegroundColor Green
