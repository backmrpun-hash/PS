$ErrorActionPreference = "SilentlyContinue"

# --- [ CONFIGURATION & PATHS ] ---
$DbUrl        = "https://project-8a76e-default-rtdb.asia-southeast1.firebasedatabase.app/licenses"
$GithubDllUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/OmniBoostX.dll"

# กำหนดเส้นทางจัดเก็บข้อมูลตามมาตรฐานโปรแกรมทั่วไป
$AppDataDir   = "$env:LOCALAPPDATA\Microsoft_Office"
$LocalDllPath = "$AppDataDir\FvSDK_x64.dll"
$RegPath      = "HKCU:\Software\StackX_Systems"

# สร้างโฟลเดอร์สำหรับเก็บข้อมูลหากยังไม่ถูกสร้าง
if (-not (Test-Path $AppDataDir)) {
    New-Item -Path $AppDataDir -ItemType Directory -Force | Out-Null
}

function Get-HWID {
    return (Get-CimInstance Win32_ComputerSystemProduct).UUID
}

# --- [ STATE CHECK & AUTOLOGIN ] ---
Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "          S T A C K X   A U T H   S Y S T E M         " -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

$key = $null
$myHwid = Get-HWID

# ตรวจสอบว่าเคยมีการบันทึก Key ไว้ใน Registry หรือไม่
if (Test-Path $RegPath) {
    $key = (Get-ItemProperty -Path $RegPath -Name "LicenseKey" -ErrorAction SilentlyContinue).LicenseKey
    if ($key) {
        Write-Host "[+] Found saved license key. Attempting auto-login..." -ForegroundColor Green
    }
}

# หากไม่มี Key ใน Registry ให้ผู้ใช้ป้อนข้อมูลใหม่
if (-not $key) {
    $key = Read-Host "[?] Enter License Key"
    if ([string]::IsNullOrEmpty($key)) {
        Write-Host "[-] Invalid Key input. Exiting." -ForegroundColor Red
        Start-Sleep 2 ; exit
    }
}

# --- [ LICENSE VERIFICATION ] ---
Write-Host "[*] Connecting to Authentication Server..." -ForegroundColor Cyan

try {
    $data = Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Get

    if ($null -eq $data) {
        Write-Host "[-] Error: Key not found in database!" -ForegroundColor Red
        # ล้างค่าใน Registry หากคีย์นั้นไม่ถูกต้อง
        if (Test-Path $RegPath) { Remove-ItemProperty -Path $RegPath -Name "LicenseKey" }
        Start-Sleep 2 ; exit
    }

    if ($data.status -ne "active") {
        Write-Host "[-] Error: This key has been disabled or expired." -ForegroundColor Red
        Start-Sleep 2 ; exit
    }

    # ตรวจสอบและลงทะเบียน HWID
    if ([string]::IsNullOrEmpty($data.hwid)) {
        $payload = @{ hwid = $myHwid } | ConvertTo-Json
        Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Patch -Body $payload
        Write-Host "[+] Success: HWID registered to this PC!" -ForegroundColor Green
    } 
    elseif ($data.hwid -ne $myHwid) {
        Write-Host "[-] Error: HWID Mismatch! Key is locked to another PC." -ForegroundColor Red
        Start-Sleep 3 ; exit
    }

    # บันทึกคีย์ที่ยืนยันผ่านแล้วลง Registry เพื่อใช้ในครั้งถัดไป
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    New-ItemProperty -Path $RegPath -Name "LicenseKey" -Value $key -PropertyType String -Force | Out-Null

    Write-Host "[+] Access Granted! Welcome back." -ForegroundColor Green
    Start-Sleep 1

} catch {
    Write-Host "[-] Connection Error! Please check your network backend." -ForegroundColor Red
    Start-Sleep 3 ; exit
}

# --- [ FILE INTEGRITY & DEPLOYMENT ] ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "          F I L E   I N T E G R I T Y   C H E C K       " -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

# ตรวจสอบว่าไฟล์เคยติดตั้งไว้แล้วหรือไม่
if (Test-Path $LocalDllPath) {
    Write-Host "[+] Core components detected at: $LocalDllPath" -ForegroundColor Green
    Write-Host "[*] Verifying integrity with server repo..." -ForegroundColor VisualStudio
    # ในอนาคตสามารถเพิ่มการเช็ค Hash (Get-FileHash) ตรงนี้ได้
} else {
    Write-Host "[-] Core components missing. Downloading from secure repository..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $GithubDllUrl -OutFile $LocalDllPath -ErrorAction Stop
        Write-Host "[+] Download Complete: $LocalDllPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Critical Error: Failed to download repository assets." -ForegroundColor Red
        return
    }
}

# --- [ PROCESS INTERACTION ] ---
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "          P R O C E S S   M A N A G E M E N T         " -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

Write-Host "[*] Fetching active process landscape..." -ForegroundColor Cyan
$Processes = Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Name, Id, MainWindowTitle
$SelectedProcess = $Processes | Out-GridView -Title "Select Target Process to Initialize Component" -OutputMode Single

if (-not $SelectedProcess) {
    Write-Host "[-] No process selected. Operations suspended." -ForegroundColor Yellow
    return
}

$ProcessName = $SelectedProcess.Name
$ProcessId = $SelectedProcess.Id
Write-Host "[*] Injecting Runtime Environment -> $ProcessName (PID: $ProcessId)" -ForegroundColor Magenta

# --- [ WIN32 API LINKAGE ] ---
$Win32Functions = @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetModuleHandle(string lpModuleName);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out uint lpNumberOfBytesWritten);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
'@

$Kernel32 = Add-Type -MemberDefinition $Win32Functions -Name "Win32RuntimeInject" -PassThru -ErrorAction SilentlyContinue

$hProcess = $Kernel32::OpenProcess(0x1F0FFF, $false, $ProcessId)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Host "[-] Unable to establish handle. Elevate to Administrator privileges." -ForegroundColor Red
    return
}

$DllPathBytes = [System.Text.Encoding]::ASCII.GetBytes($LocalDllPath + "`0")
$AllocMem = $Kernel32::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$DllPathBytes.Length, 0x3000, 0x04)
$Kernel32::WriteProcessMemory($hProcess, $AllocMem, $DllPathBytes, [uint32]$DllPathBytes.Length, [ref]0)
$LoadLib = $Kernel32::GetProcAddress($Kernel32::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
$hThread = $Kernel32::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $LoadLib, $AllocMem, 0, [IntPtr]::Zero)

if ($hThread -ne [IntPtr]::Zero) {
    Write-Host "`n[+++] RUNTIME COMPONENT DEPLOYED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor DarkGreen
} else {
    Write-Host "[-] Deployment phase failed inside target thread context." -ForegroundColor Red
}
