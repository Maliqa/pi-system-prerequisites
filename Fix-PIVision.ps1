# =========================================================
# FIX PI VISION IIS + SSL + FEATURES (WINDOWS SERVER)
# =========================================================

Write-Host "=== FIXING PI VISION ENVIRONMENT (SERVER MODE) ===" -ForegroundColor Cyan

# 1. Pastikan ini Windows Server
$os = (Get-CimInstance Win32_OperatingSystem).Caption
if ($os -notmatch "Server") {
    Write-Host "ERROR: Script ini hanya untuk Windows Server!" -ForegroundColor Red
    exit 1
}

Write-Host "Detected OS: $os" -ForegroundColor Green

# 2. Install IIS + Required Features
Write-Host "Installing IIS & required features..." -ForegroundColor Yellow

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
    "Web-Basic-Auth",
    "Web-Windows-Auth",
    "Web-App-Dev",
    "Web-Net-Ext45",
    "Web-Asp-Net45",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Mgmt-Tools",
    "Web-Mgmt-Console"
)

Install-WindowsFeature -Name $features -IncludeManagementTools

# 3. Enable IIS Services
Write-Host "Restarting IIS services..." -ForegroundColor Yellow
iisreset

# 4. Fix SSL Binding (PI Vision WAJIB HTTPS)
Write-Host "Checking HTTPS binding..." -ForegroundColor Yellow

Import-Module WebAdministration

$httpsBinding = Get-WebBinding -Protocol https -ErrorAction SilentlyContinue
if (-not $httpsBinding) {
    Write-Host "Creating self-signed certificate..." -ForegroundColor Yellow

    $cert = New-SelfSignedCertificate `
        -DnsName "localhost" `
        -CertStoreLocation "cert:\LocalMachine\My"

    New-WebBinding -Name "Default Web Site" -Protocol https -Port 443
    Get-WebBinding -Name "Default Web Site" -Protocol https |
        Set-WebBinding -CertificateThumbprint $cert.Thumbprint -CertificateStoreName "My"
}

# 5. Pastikan Default Document
Write-Host "Fixing Default Document..." -ForegroundColor Yellow
Add-WebConfigurationProperty `
  -Filter "system.webServer/defaultDocument/files" `
  -Name "." `
  -Value @{value="index.html"} `
  -PSPath "IIS:\"

# 6. Folder Permission (WAJIB)
Write-Host "Fixing PI Vision folder permissions..." -ForegroundColor Yellow

$piPath = "C:\Program Files\PIPC\PIVision"
icacls $piPath /grant "IIS_IUSRS:(OI)(CI)RX" /T
icacls $piPath /grant "IUSR:(OI)(CI)RX" /T

# 7. Final IIS Reset
iisreset

Write-Host "=== PI VISION IIS FIX COMPLETED ===" -ForegroundColor Green
Write-Host "Access PI Vision via: https://localhost/PIVision" -ForegroundColor Cyan
