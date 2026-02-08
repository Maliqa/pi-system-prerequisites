# =========================================================
# PI SYSTEM FULL PREREQUISITE INSTALLER
# Target : Windows Server 2019 / 2022
# Use    : PI Data Archive, PI AF, PI Vision (LAB / Training)
# =========================================================

# ---------- ADMIN CHECK ----------
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Run this script as Administrator!" -ForegroundColor Red
    exit 1
}

$LogFile = "C:\PI_Prerequisite_Install.log"
Start-Transcript -Path $LogFile -Append

Write-Host "=== PI SYSTEM FULL PREREQUISITE INSTALL ===" -ForegroundColor Cyan

# ---------- TIMEZONE ----------
Write-Host "Setting Timezone to UTC+7 (Jakarta)..."
tzutil /s "SE Asia Standard Time"

# ---------- IE ENHANCED SECURITY ----------
Write-Host "Disabling IE Enhanced Security..."
$IEAdmin = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$IEUser  = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty $IEAdmin -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty $IEUser  -Name "IsInstalled" -Value 0 -Force

# ---------- IIS + WEB FEATURES ----------
Write-Host "Installing IIS & Web Components..."
Install-WindowsFeature `
Web-Server, `
Web-WebServer, `
Web-Common-Http, `
Web-Default-Doc, `
Web-Static-Content, `
Web-Http-Errors, `
Web-App-Dev, `
Web-Net-Ext45, `
Web-Asp-Net45, `
Web-ISAPI-Ext, `
Web-ISAPI-Filter, `
Web-Security, `
Web-Windows-Auth, `
Web-Basic-Auth, `
Web-Performance, `
Web-Stat-Compression, `
Web-Dyn-Compression, `
Web-Mgmt-Tools, `
Web-Mgmt-Console, `
Web-Mgmt-Compat `
-IncludeManagementTools

# ---------- .NET FRAMEWORK ----------
Write-Host "Enabling .NET Framework 4.8..."
Install-WindowsFeature NET-Framework-45-Core
Install-WindowsFeature NET-Framework-45-ASPNET

# ---------- WINDOWS TIME SERVICE ----------
Write-Host "Configuring Windows Time Service..."
Set-Service w32time -StartupType Automatic
w32tm /resync | Out-Null

# ---------- FIREWALL BASIC RULES ----------
Write-Host "Configuring basic firewall rules..."
New-NetFirewallRule -DisplayName "PI HTTP"  -Direction Inbound -Protocol TCP -LocalPort 80   -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "PI HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443  -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "PI AF SDK" -Direction Inbound -Protocol TCP -LocalPort 5450 -Action Allow -ErrorAction SilentlyContinue

# ---------- FINAL CHECK ----------
Write-Host "Validating IIS..."
iisreset | Out-Null

Write-Host "=== PREREQUISITE INSTALL COMPLETED ===" -ForegroundColor Green
Write-Host "Log saved at: $LogFile"

Stop-Transcript

Write-Host ""
Write-Host "IMPORTANT: Reboot server BEFORE installing PI System!" -ForegroundColor Yellow
