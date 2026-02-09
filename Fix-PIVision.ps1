Write-Host "=== FINAL FIX PI VISION UI - WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

Import-Module WebAdministration

# 1. Stop IIS
Write-Host "Stopping IIS..."
iisreset /stop

# 2. Disable IIS Compression (SVG MUSUH COMPRESSION)
Write-Host "Disabling IIS Compression..."
Set-WebConfigurationProperty -Filter system.webServer/urlCompression `
    -Name doStaticCompression -Value false
Set-WebConfigurationProperty -Filter system.webServer/urlCompression `
    -Name doDynamicCompression -Value false

# 3. Remove ALL existing MIME mappings that break PI Vision
Write-Host "Cleaning existing MIME mappings..."
$mimePath = "MACHINE/WEBROOT/APPHOST"
$mimeFilter = "system.webServer/staticContent/mimeMap"

Get-WebConfigurationProperty -pspath $mimePath -filter $mimeFilter -name "." |
Where-Object { $_.fileExtension -in ".svg",".json",".woff",".woff2",".ttf",".eot" } |
ForEach-Object {
    Remove-WebConfigurationProperty -pspath $mimePath `
        -filter "system.webServer/staticContent" `
        -name "." `
        -AtElement @{fileExtension=$_.fileExtension}
}

# 4. Re-add MIME types (SAFE & CLEAN)
Write-Host "Adding correct MIME types..."
Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".svg"; mimeType="image/svg+xml"}

Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".json"; mimeType="application/json"}

Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".woff"; mimeType="font/woff"}

Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".woff2"; mimeType="font/woff2"}

Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".ttf"; mimeType="font/ttf"}

Add-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/staticContent" -name "." `
  -value @{fileExtension=".eot"; mimeType="application/vnd.ms-fontobject"}

# 5. Allow SVG in Request Filtering
Write-Host "Fixing RequestFiltering..."
Set-WebConfigurationProperty -pspath $mimePath `
  -filter "system.webServer/security/requestFiltering/fileExtensions/add[@fileExtension='.svg']" `
  -name allowed -value true -ErrorAction SilentlyContinue

# 6. Fix Folder Permission
Write-Host "Fixing folder permissions..."
$paths = @(
 "C:\Program Files\PIPC\PIVision",
 "C:\inetpub\wwwroot\PIVision"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        icacls $p /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null
    }
}

# 7. Start IIS
Write-Host "Starting IIS..."
iisreset /start

Write-Host "=== DONE. REBOOT SERVER SEKARANG (WAJIB) ===" -ForegroundColor Green
