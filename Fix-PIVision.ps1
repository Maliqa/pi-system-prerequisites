Write-Host "=== FIXING PI VISION IIS ON WINDOWS SERVER 2022 ===" -ForegroundColor Cyan

# Import Server Manager
Import-Module ServerManager

# IIS Core
$features = @(
    "Web-Server",
    "Web-WebServer",

    # Common HTTP
    "Web-Common-Http",
    "Web-Default-Doc",
    "Web-Static-Content",
    "Web-Http-Errors",
    "Web-Http-Redirect",

    # Health & Diagnostics
    "Web-Health",
    "Web-Http-Logging",
    "Web-Request-Monitor",
    "Web-Http-Tracing",

    # Performance
    "Web-Performance",
    "Web-Stat-Compression",

    # Security
    "Web-Security",
    "Web-Windows-Auth",
    "Web-Filtering",

    # App Development (WAJIB PI Vision)
    "Web-App-Dev",
    "Web-Net-Ext45",
    "Web-Asp-Net45",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",

    # Management
    "Web-Mgmt-Tools",
    "Web-Mgmt-Console"
)

foreach ($feature in $features) {
    Write-Host "Installing $feature ..." -ForegroundColor Yellow
    Install-WindowsFeature $feature -IncludeManagementTools -ErrorAction SilentlyContinue
}

# Enable IIS Services
Write-Host "Restarting IIS..." -ForegroundColor Cyan
iisreset

Write-Host "=== IIS & PI Vision PREREQUISITES DONE ===" -ForegroundColor Green
