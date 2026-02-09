Write-Host "=== FINAL FIX PI VISION UI - WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

Import-Module WebAdministration

# 1. STOP IIS
Write-Host "Stopping IIS..."
iisreset /stop

# 2. CLEAR IIS CACHE (INI KRUSIAL)
Write-Host "Clearing IIS cache..."
Stop-Service WAS -Force
Stop-Service W3SVC -Force

Remove-Item "C:\Windows\System32\inetsrv\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\inetpub\temp\IIS Temporary Compressed Files\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. ENSURE MIME TYPES (PNG / SVG / JSON / WOFF)
Write-Host "Fixing MIME types..."
$mimeList = @{
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".json" = "application/json"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}

foreach ($ext in $mimeList.Keys) {
    Remove-WebConfigurationProperty -Filter /system.webServer/staticContent `
        -Name "." -AtElement @{fileExtension=$ext} -ErrorAction SilentlyContinue

    Add-WebConfigurationProperty -Filter /system.webServer/staticContent `
        -Name "." -Value @{fileExtension=$ext; mimeType=$mimeList[$ext]}
}

# 4. DISABLE STATIC + DYNAMIC COMPRESSION (INI PENYEBAB ICON PECAH)
Write-Host "Disabling IIS compression..."
Set-WebConfigurationProperty `
  -Filter /system.webServer/urlCompression `
  -Name doStaticCompression -Value False

Set-WebConfigurationProperty `
  -Filter /system.webServer/urlCompression `
  -Name doDynamicCompression -Value False

# 5. ENSURE STATIC CONTENT HANDLER
Write-Host "Ensuring StaticFile handler..."
Set-WebConfigurationProperty `
 -Filter /system.webServer/handlers/add[@name='StaticFile'] `
 -Name path -Value '*'

# 6. RESET APP POOL
Write-Host "Resetting PI Vision AppPool..."
Restart-WebAppPool "DefaultAppPool"

# 7. START IIS
Write-Host "Starting IIS..."
iisreset /start

Write-Host "=== DONE. REBOOT SERVER AFTER THIS ===" -ForegroundColor Green
