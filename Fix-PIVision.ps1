Write-Host "=== FIXING PI VISION ON WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

# 1. Install IIS + Required Features
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
    "Web-Request-Monitor",
    "Web-Performance",
    "Web-Stat-Compression",
    "Web-Security",
    "Web-Windows-Auth",
    "Web-App-Dev",
    "Web-Net-Ext45",
    "Web-Asp-Net45",
    "NET-Framework-45-Core"
)

Install-WindowsFeature -Name $features -IncludeManagementTools

# 2. IIS Static Content & Default Document
Import-Module WebAdministration

Set-WebConfigurationProperty `
 -filter system.webServer/staticContent `
 -name enabled `
 -value True `
 -PSPath IIS:\

# 3. Fix PI Vision Folder Permissions
$paths = @(
    "C:\Program Files\PIPC\PIVision",
    "C:\Program Files\PIPC\PIVision\Content",
    "C:\Program Files\PIPC\PIVision\Images"
)

foreach ($path in $paths) {
    icacls $path /grant "IIS_IUSRS:(OI)(CI)RX" /T /C
}

# 4. Restart IIS
iisreset

Write-Host "=== PI VISION FIX COMPLETE. REBOOT SERVER ===" -ForegroundColor Green
