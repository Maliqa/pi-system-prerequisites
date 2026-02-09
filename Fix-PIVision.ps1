# =========================================================
# FINAL FIX PI VISION UI (ICON BROKEN)
# Windows Server 2022
# =========================================================

Write-Host "=== FINAL FIX PI VISION UI - WS2022 ===" -ForegroundColor Cyan

Import-Module WebAdministration

# 1. Stop IIS
Write-Host "Stopping IIS..."
iisreset /stop

# 2. Disable IIS Compression (INI PENTING BANGET)
Write-Host "Disabling IIS Compression..."

Set-WebConfigurationProperty `
  -Filter /system.webServer/httpCompression `
  -Name dynamicCompressionEnabled `
  -Value false

Set-WebConfigurationProperty `
  -Filter /system.webServer/httpCompression `
  -Name staticCompressionEnabled `
  -Value false

# 3. Ensure Static Content handler
Write-Host "Ensuring Static Content handler..."

if (-not (Get-WebConfiguration "//handlers/add[@name='StaticFile']" -ErrorAction SilentlyContinue)) {
    Add-WebConfiguration `
      -Filter /system.webServer/handlers `
      -Value @{
        name="StaticFile";
        path="*";
        verb="*";
        modules="StaticFileModule";
        resourceType="Either";
        requireAccess="Read"
      }
}

# 4. Fix MIME types (SVG & Fonts)
Write-Host "Fixing MIME Types..."

$mimeTypes = @{
    ".svg"   = "image/svg+xml"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
    ".eot"   = "application/vnd.ms-fontobject"
}

foreach ($ext in $mimeTypes.Keys) {
    if (-not (Get-WebConfiguration "//staticContent/mimeMap[@fileExtension='$ext']" -ErrorAction SilentlyContinue)) {
        Add-WebConfiguration `
          -Filter /system.webServer/staticContent `
          -Value @{ fileExtension=$ext; mimeType=$mimeTypes[$ext] }
    }
}

# 5. Reset PI Vision cache (Angular)
Write-Host "Clearing PI Vision cache..."

$cachePaths = @(
  "C:\Program Files\PIPC\PIVision\wwwroot\dist",
  "C:\Program Files\PIPC\PIVision\Temp",
  "C:\Windows\Temp"
)

foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# 6. Fix App Pool
Write-Host "Fixing PI Vision AppPool..."

Set-ItemProperty IIS:\AppPools\PIVision `
  -Name managedPipelineMode `
  -Value Integrated

Set-ItemProperty IIS:\AppPools\PIVision `
  -Name processModel.identityType `
  -Value ApplicationPoolIdentity

# 7. Start IIS
Write-Host "Starting IIS..."
iisreset /start

Write-Host "=== DONE. CLEAR BROWSER CACHE & OPEN AGAIN ===" -ForegroundColor Green
