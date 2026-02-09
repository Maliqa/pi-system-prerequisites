Write-Host "=== FINAL FIX PI VISION UI - WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

# -----------------------------
# 1. Pastikan IIS & Role Feature (SERVER WAY)
# -----------------------------
Write-Host "Installing IIS Features (Server method)..." -ForegroundColor Yellow

$features = @(
    "Web-Server",
    "Web-WebServer",
    "Web-Common-Http",
    "Web-Default-Doc",
    "Web-Static-Content",
    "Web-Http-Errors",
    "Web-Http-Redirect",
    "Web-Health",
    "Web-Http-Logging",
    "Web-Log-Libraries",
    "Web-Request-Monitor",
    "Web-Performance",
    "Web-Stat-Compression",
    "Web-Dyn-Compression",
    "Web-Security",
    "Web-Filtering",
    "Web-Windows-Auth",
    "Web-App-Dev",
    "Web-Net-Ext45",
    "Web-Asp-Net45",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Mgmt-Tools",
    "Web-Mgmt-Console"
)

foreach ($f in $features) {
    Install-WindowsFeature $f -ErrorAction SilentlyContinue | Out-Null
}

# -----------------------------
# 2. Stop IIS
# -----------------------------
Write-Host "Stopping IIS..." -ForegroundColor Yellow
iisreset /stop

# -----------------------------
# 3. Fix MIME TYPES (CRITICAL)
# -----------------------------
Write-Host "Fixing MIME Types..." -ForegroundColor Yellow
Import-Module WebAdministration

$mimeTypes = @{
    ".svg"  = "image/svg+xml"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
    ".eot"  = "application/vnd.ms-fontobject"
    ".json" = "application/json"
}

foreach ($ext in $mimeTypes.Keys) {
    Remove-WebConfigurationProperty `
        -pspath 'MACHINE/WEBROOT/APPHOST' `
        -filter "system.webServer/staticContent/mimeMap[@fileExtension='$ext']" `
        -name "." `
        -ErrorAction SilentlyContinue

    Add-WebConfigurationProperty `
        -pspath 'MACHINE/WEBROOT/APPHOST' `
        -filter "system.webServer/staticContent" `
        -name "." `
        -value @{ fileExtension=$ext; mimeType=$mimeTypes[$ext] }
}

# -----------------------------
# 4. MATIKAN IIS COMPRESSION (BIANG KELADI UI RUSAK)
# -----------------------------
Write-Host "Disabling IIS Compression..." -ForegroundColor Yellow
Set-WebConfigurationProperty `
  -filter "system.webServer/httpCompression" `
  -name "doStaticCompression" `
  -value "false"

Set-WebConfigurationProperty `
  -filter "system.webServer/httpCompression" `
  -name "doDynamicCompression" `
  -value "false"

# -----------------------------
# 5. Pastikan Static Content Handler
# -----------------------------
Write-Host "Ensuring Static Content Handler..." -ForegroundColor Yellow
Set-WebConfigurationProperty `
  -filter "system.webServer/modules/add[@name='StaticFileModule']" `
  -name "preCondition" `
  -value ""

# -----------------------------
# 6. Permission Folder PI Vision (INI WAJIB)
# -----------------------------
Write-Host "Fixing Folder Permissions..." -ForegroundColor Yellow

$paths = @(
 "C:\Program Files\PIPC\PIVision",
 "C:\Program Files\PIPC\PIVision\Content",
 "C:\Program Files\PIPC\PIVision\Images"
)

foreach ($p in $paths) {
    icacls $p /grant "IIS_IUSRS:(OI)(CI)RX" /T /C | Out-Null
}

# -----------------------------
# 7. AppPool Identity (INI KRUSIAL)
# -----------------------------
Write-Host "Fixing AppPool Identity..." -ForegroundColor Yellow

Set-ItemProperty IIS:\AppPools\DefaultAppPool `
 -name processModel.identityType `
 -value ApplicationPoolIdentity

# -----------------------------
# 8. Clear IIS Cache
# -----------------------------
Write-Host "Clearing IIS Cache..." -ForegroundColor Yellow
Remove-Item "C:\inetpub\temp\IIS Temporary Compressed Files" -Recurse -Force -ErrorAction SilentlyContinue

# -----------------------------
# 9. Start IIS
# -----------------------------
Write-Host "Starting IIS..." -ForegroundColor Green
iisreset /start

Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "REBOOT SERVER SEKARANG (WAJIB)" -ForegroundColor Red
