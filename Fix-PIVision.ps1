Write-Host "=== FINAL FIX PI VISION UI - WS2022 ===" -ForegroundColor Cyan

Import-Module WebAdministration

# Stop IIS
iisreset /stop | Out-Null

# Paths
$sitePath = "IIS:\Sites\Default Web Site\PIVision"
$mimePath = "IIS:\MimeTypes"

# 1. REMOVE ALL PROBLEMATIC MIME TYPES (clean slate)
$badExt = ".svg",".json",".woff",".woff2",".ttf",".eot"
Get-ChildItem $mimePath | Where-Object { $badExt -contains $_.Extension } | Remove-Item -Force

# 2. ADD CORRECT MIME TYPES (ONCE)
New-ItemProperty $mimePath -Name "." -Force | Out-Null
New-ItemProperty $mimePath -Name ".svg"   -Value @{mimeType="image/svg+xml"} | Out-Null
New-ItemProperty $mimePath -Name ".json"  -Value @{mimeType="application/json"} | Out-Null
New-ItemProperty $mimePath -Name ".woff"  -Value @{mimeType="font/woff"} | Out-Null
New-ItemProperty $mimePath -Name ".woff2" -Value @{mimeType="font/woff2"} | Out-Null
New-ItemProperty $mimePath -Name ".ttf"   -Value @{mimeType="font/ttf"} | Out-Null
New-ItemProperty $mimePath -Name ".eot"   -Value @{mimeType="application/vnd.ms-fontobject"} | Out-Null

# 3. DISABLE IIS COMPRESSION (SVG MUSUH BESAR)
Set-WebConfigurationProperty -Filter system.webServer/httpCompression `
  -Name enabled -Value false -PSPath 'MACHINE/WEBROOT/APPHOST'

# 4. REQUEST FILTERING - ALLOW EVERYTHING PI VISION NEEDS
$rf = "system.webServer/security/requestFiltering/fileExtensions"
Get-WebConfigurationProperty -PSPath $sitePath -Filter $rf -Name "." | Remove-WebConfigurationProperty -Name "." -AtElement @{fileExtension="*"}

Add-WebConfigurationProperty -PSPath $sitePath -Filter $rf -Name "." `
  -Value @{fileExtension="*"; allowed="true"}

# 5. STATIC CONTENT HANDLER (ENSURE ENABLED)
Set-WebConfigurationProperty -PSPath $sitePath `
 -Filter "system.webServer/staticContent" -Name "." -Value ""

# 6. CLEAR IIS CACHE
Remove-Item "C:\inetpub\temp\IIS Temporary Compressed Files\*" -Recurse -Force -ErrorAction SilentlyContinue

# Start IIS
iisreset /start | Out-Null

Write-Host "DONE. REBOOT SERVER SEKARANG." -ForegroundColor Green
