$ErrorActionPreference = "SilentlyContinue"

# --- [ CONFIGURATION & PATHS ] ---
$DbUrl        = "https://project-8a76e-default-rtdb.asia-southeast1.firebasedatabase.app/licenses"
$GithubDllUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/STACKX.dll"

# เส้นทางจัดเก็บข้อมูลแอปพลิเคชัน
$AppDataDir   = "$env:LOCALAPPDATA\Microsoft_Office"
$LocalDllPath = "$AppDataDir\FvSDK_x64.dll"
$LocalDllPathh = "STACKX"

# ระบบตรวจสอบและเตรียมความพร้อมของโฟลเดอร์ปลายทาง
if (-not (Test-Path $AppDataDir)) {
    New-Item -Path $AppDataDir -ItemType Directory -Force | Out-Null
}

function Get-HWID {
    return (Get-CimInstance Win32_ComputerSystemProduct).UUID
}

# --- [ LOGIN SYSTEM ] ---
Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "          S T A C K X   A U T H   S Y S T E M         " -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

# (นำระบบจำจาก Registry ออกแล้ว) บังคับให้ผู้ใช้งานป้อนคีย์ใหม่ทุกรอบการเปิดใช้งาน
$key = Read-Host "[?] Enter License Key"
if ([string]::IsNullOrEmpty($key)) {
    Write-Host "[-] Invalid Key input. Exiting." -ForegroundColor Red
    Start-Sleep 2 ; exit
}

$myHwid = Get-HWID

Write-Host "[*] Connecting to Authentication Server..." -ForegroundColor Cyan

try {
    $data = Invoke-RestMethod -Uri "$DbUrl/$key.json" -Method Get

    if ($null -eq $data) {
        Write-Host "[-] Error: Key not found in database!" -ForegroundColor Red
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

# ตรวจสอบโครงสร้างโฟลเดอร์และไฟล์: ถ้าไม่มีติดตั้ง ถ้ามีทำการ Run ต่อทันที
if (Test-Path $LocalDllPath) {
    Write-Host "[+] Core components detected at: $LocalDllPath" -ForegroundColor Green
    Write-Host "[*] System Ready. Proceeding to execution stage..." -ForegroundColor Cyan
} else {
    Write-Host "[-] Core components missing. Downloading from secure repository..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $GithubDllUrl -OutFile $LocalDllPath -ErrorAction Stop
        Write-Host "[+] Download Complete: $LocalDllPathh" -ForegroundColor Green
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

# สั่งระบุเป้าหมายไปที่กระบวนการโปรแกรมปลายทางโดยอัตโนมัติ
$TargetProcessName = "notepad"
$TargetProcess = Get-Process -Name $TargetProcessName -ErrorAction SilentlyContinue

if (-not $TargetProcess) {
    Write-Host "[-] Target process '$TargetProcessName' is not running." -ForegroundColor Yellow
    Write-Host "[*] Launching a new instance of $TargetProcessName..." -ForegroundColor Cyan
    $NewProc = Start-Process -FilePath "$TargetProcessName.exe" -PassThru
    Start-Sleep -Milliseconds 500
    $ProcessId = $NewProc.Id
} else {
    # เลือกตัวแรกที่พบล่าสุดในกรณีที่มีการเปิดค้างไว้หลายหน้าต่าง
    $ProcessId = $TargetProcess[0].Id
}

Write-Host "[*] Target identified: $TargetProcessName.exe (PID: $ProcessId)" -ForegroundColor Magenta

# --- [ WIN32 API LINKAGE ] ---
# ส่วนโครงสร้าง Logic ของการจัดการ Memory และสิทธิ์ของเธรด (คงไว้เดิม ไม่แก้ไข)
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
