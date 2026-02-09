# ===============================
# FIX PI VISION IIS & SSL ISSUES
# ===============================

Write-Host "=== FIXING PI VISION ENVIRONMENT ===" -ForegroundColor Cyan

# -------------------------------
# 1. Enable IIS Required Features
# -------------------------------
Write-Host "Enabling IIS Features..."

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
    Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction SilentlyContinue
}

# -------------------------------
# 2. Generate Self-Signed SSL Cert
# -------------------------------
Write-Host "Creating Self-Signed Certificate..."

$cert = New-SelfSignedCertificate `
    -DnsName "localhost" `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "PI Vision SSL"

# -------------------------------
# 3. Bind HTTPS to IIS Default Site
# -------------------------------
Import-Module WebAdministration

Write-Host "Configuring HTTPS binding..."

Remove-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction SilentlyContinue

New-WebBinding -Name "Default Web Site" -Protocol https -Port 443

$binding = Get-WebBinding -Name "Default Web Site" -Protocol https
$binding.AddSslCertificate($cert.Thumbprint, "my")

# -------------------------------
# 4. Disable SSL Requirement for Content Folder
# -------------------------------
Write-Host "Fixing SSL requirement on PI Vision Content..."

Set-WebConfigurationProperty `
    -Filter "/system.webServer/security/access" `
    -Name sslFlags `
    -Value "None" `
    -PSPath "IIS:\Sites\Default Web Site\PIVision"

# -------------------------------
# 5. Enable Static Content & Directory Browsing (Images fix)
# -------------------------------
Write-Host "Fixing Static Content..."

Set-WebConfigurationProperty `
    -Filter "/system.webServer/directoryBrowse" `
    -Name enabled `
    -Value true `
    -PSPath "IIS:\Sites\Default Web Site\PIVision"

# -------------------------------
# 6. Restart IIS & PI Vision Services
# -------------------------------
Write-Host "Restarting IIS & PI Vision services..."

iisreset

Get-Service | Where-Object {
    $_.Name -match "PIVision|PI-Web|PIWebAPI"
} | Restart-Service -Force -ErrorAction SilentlyContinue

# -------------------------------
# DONE
# -------------------------------
Write-Host "=== PI VISION FIX COMPLETE ===" -ForegroundColor Green
Write-Host "Access via: https://localhost/PIVision"
