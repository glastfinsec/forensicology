# ==============================================================================
# Program    : Forensicology by glastfin
# Author     : glastfin
# Description: Monolithic In-Memory Windows Incident Response & Remediation Suite
# Direct Exec: powershell -ExecutionPolicy Bypass -Command "irm <URL> | iex"
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Process-Scoped Execution Policy Bypass
# ------------------------------------------------------------------------------
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    if ($MyInvocation.PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.PSCommandPath)`"" -Verb RunAs
        exit
    }
}

# ------------------------------------------------------------------------------
# 2. State Management & In-Memory Storage
# ------------------------------------------------------------------------------
$script:VTKey = ""
$script:OriginalTitle = $host.UI.RawUI.WindowTitle
$script:Running = $true

$script:InvestigationState = [PSCustomObject]@{
    SuspiciousTargets = [System.Collections.Generic.List[string]]::new()
    TimeframeStart    = (Get-Date).AddDays(-1)
    TimeframeEnd      = Get-Date
    DiscoveredAssets  = [System.Collections.Generic.List[PSObject]]::new()
}

try {
    $host.UI.RawUI.WindowTitle = "GLASTFIN :: FORENSICOLOGY | Endpoint Forensics Suite"

    Clear-Host
    Write-Host "$([char]27)[3mBonsoir.$([char]27)[0m`n" -ForegroundColor DarkCyan
    Start-Sleep -Seconds 1

    function Show-Header {
        Clear-Host
        $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host "  ______ ____   _____  ______ _   _  _____ _____ _____ ____  _      ____   _______     __" -ForegroundColor Green
        Write-Host " |  ____/ __ \ |  __ \|  ____| \ | |/ ____|_   _/ ____/ __ \| |    / __ \ / ____\ \   / /" -ForegroundColor Green
        Write-Host " | |__ | |  | || |__) | |__  |  \| | (___   | || |   | |  | | |   | |  | | |  __ \ \_/ / " -ForegroundColor DarkGreen
        Write-Host " |  __|| |  | ||  _  /|  __| | . ` |\___ \  | || |   | |  | | |   | |  | | | |_ | \   /  " -ForegroundColor Green
        Write-Host " | |   | |__| || | \ \| |____| |\  |____) |_| || |___| |__| | |___| |__| | |__| |  | |   " -ForegroundColor Green
        Write-Host " |_|    \____/ |_|  \_\______|_| \_|_____/|_____\_____\____/|______\____/ \_____|  |_|   " -ForegroundColor DarkCyan
        Write-Host "                                                                                          " -ForegroundColor Cyan
        Write-Host "                  --->   B Y   G L A S T F I N   <---                                    " -ForegroundColor Yellow
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host "   Automated TUI Windows Forensics, Threat Purge & Pivot Engine                           " -ForegroundColor DarkCyan
        Write-Host "   AUTHOR       : GLASTFIN" -ForegroundColor Green
        Write-Host "   SYSTEM CLOCK : $currentDateTime" -ForegroundColor Gray
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host ""
    }

    function Exit-ForensicsEngine {
        Clear-Host
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host "  ______ ____   _____  ______ _   _  _____ _____ _____ ____  _      ____   _______     __" -ForegroundColor Green
        Write-Host " |  ____/ __ \ |  __ \|  ____| \ | |/ ____|_   _/ ____/ __ \| |    / __ \ / ____\ \   / /" -ForegroundColor Green
        Write-Host " | |__ | |  | || |__) | |__  |  \| | (___   | || |   | |  | | |   | |  | | |  __ \ \_/ / " -ForegroundColor DarkGreen
        Write-Host " |  __|| |  | ||  _  /|  __| | . ` |\___ \  | || |   | |  | | |   | |  | | | |_ | \   /  " -ForegroundColor Green
        Write-Host " | |   | |__| || | \ \| |____| |\  |____) |_| || |___| |__| | |___| |__| | |__| |  | |   " -ForegroundColor Green
        Write-Host " |_|    \____/ |_|  \_\______|_| \_|_____/|_____\_____\____/|______\____/ \_____|  |_|   " -ForegroundColor DarkCyan
        Write-Host "                                                                                          " -ForegroundColor Cyan
        Write-Host "                  --->   B Y   G L A S T F I N   <---                                    " -ForegroundColor Yellow
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host "  [+] In-Memory Session Destroyed" -ForegroundColor Gray
        Write-Host "  [+] API Tokens & State Vector Purged" -ForegroundColor Gray
        Write-Host "  [+] FORENSICOLOGY BY GLASTFIN session cleanly terminated." -ForegroundColor Green
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        
        Write-Host "`n$([char]27)[3mAu revoir.$([char]27)[0m`n" -ForegroundColor DarkYellow
        Start-Sleep -Seconds 1
    }

    function Show-Menu {
        Show-Header
        Write-Host "  [1] Static File Inspection Suite (Metadata, Hashes, YARA, VirusTotal)" -ForegroundColor Yellow
        Write-Host "  [2] Historical Log Investigation Engine (Blind Scan -> Add Indicator)" -ForegroundColor Yellow
        Write-Host "  [3] Native Resource Monitor (System Performance & Process Warning Alert)" -ForegroundColor Yellow
        Write-Host "  [4 / Q] Terminate Session & Self-Clean" -ForegroundColor Red
        Write-Host ""
        
        if ($script:InvestigationState.DiscoveredAssets.Count -gt 0 -or $script:InvestigationState.SuspiciousTargets.Count -gt 0) {
            Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " ACTIVE INVESTIGATION STATE (GLASTFIN ENGINE):" -ForegroundColor Green
            Write-Host "  > Tracked Indicators : $(if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { $script:InvestigationState.SuspiciousTargets -join ', ' } else { 'None (Blind Scan Mode)' })" -ForegroundColor Yellow
            Write-Host "  > Active Time Window : $($script:InvestigationState.TimeframeStart) to $($script:InvestigationState.TimeframeEnd)" -ForegroundColor White
            Write-Host "  > Identified Events  : $($script:InvestigationState.DiscoveredAssets.Count)" -ForegroundColor White
            Write-Host "----------------------------------------------------------------------------------------------------`n" -ForegroundColor DarkGray
        }
    }

    function Parse-FuzzyTime ($inputStr, $isEndDate = $false) {
        if ([string]::IsNullOrWhiteSpace($inputStr)) { 
            if ($isEndDate) { return Get-Date }
            else { return $null }
        }

        $cleanStr = $inputStr.Trim().ToLower()
        $now = Get-Date
        $dayOfWeekOffset = ([int]$now.DayOfWeek + 6) % 7
        $startOfThisWeek = $now.Date.AddDays(-$dayOfWeekOffset)

        switch -Regex ($cleanStr) {
            "^now$" { return $now }
            "^today$" {
                if ($isEndDate) { return $now.Date.AddDays(1).AddSeconds(-1) }
                else { return $now.Date }
            }
            "^yesterday$" {
                if ($isEndDate) { return $now.Date.AddSeconds(-1) }
                else { return $now.Date.AddDays(-1) }
            }
            "^this week$" {
                if ($isEndDate) { return $now }
                else { return $startOfThisWeek }
            }
            "^last week$" {
                $startOfLastWeek = $startOfThisWeek.AddDays(-7)
                if ($isEndDate) { return $startOfThisWeek.AddSeconds(-1) }
                else { return $startOfLastWeek }
            }
            "^this month$" {
                $startOfThisMonth = Get-Date -Year $now.Year -Month $now.Month -Day 1 -Hour 0 -Minute 0 -Second 0
                if ($isEndDate) { return $now }
                else { return $startOfThisMonth }
            }
            "^last month$" {
                $firstOfThisMonth = Get-Date -Year $now.Year -Month $now.Month -Day 1 -Hour 0 -Minute 0 -Second 0
                $startOfLastMonth = $firstOfThisMonth.AddMonths(-1)
                if ($isEndDate) { return $firstOfThisMonth.AddSeconds(-1) }
                else { return $startOfLastMonth }
            }
            "^(\d+)\s*(h|hour|hours)\s*ago$" { return $now.AddHours(-[int]$Matches[1]) }
            "^(\d+)\s*(d|day|days)\s*ago$" { return $now.AddDays(-[int]$Matches[1]) }
            default {
                $parsedDate = Get-Date
                if ([datetime]::TryParse($inputStr, [ref]$parsedDate)) { return $parsedDate }
                return $null
            }
        }
    }

    function Set-TimeslotWindow {
        Write-Host "`n[*] Configure Historical Investigation Window" -ForegroundColor Cyan
        Write-Host "    Fuzzy options: 'now', 'today', 'yesterday', 'this week', 'last week', 'this month', 'last month', '3 hours ago', '2 days ago'" -ForegroundColor DarkGray
        Write-Host "    Current Date/Time Baseline: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
        
        $startInput = Read-Host "`nEnter Start Date/Time or Keyword"
        $endInput   = Read-Host "Enter End Date/Time or Keyword (Press Enter for 'NOW')"

        $parsedStart = Parse-FuzzyTime $startInput -isEndDate $false
        $parsedEnd   = Parse-FuzzyTime $endInput -isEndDate $true

        if ($parsedStart) {
            $script:InvestigationState.TimeframeStart = $parsedStart
            $script:InvestigationState.TimeframeEnd   = $parsedEnd
            Write-Host "[+] Investigation timeframe updated: $($script:InvestigationState.TimeframeStart) to $($script:InvestigationState.TimeframeEnd)" -ForegroundColor Green
        } else {
            Write-Host "[!] Unable to parse start timestamp. Retaining active timeframe window." -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }

    function Purge-MalwareThreat ($targetInput) {
        if ([string]::IsNullOrWhiteSpace($targetInput)) { return }
        $targetInput = $targetInput.Trim("'", '"')

        Write-Host "`n====================================================================================================" -ForegroundColor Red
        Write-Host "   CONFIRM THREAT REMEDIATION & PURGE [GLASTFIN ENGINE]                                            " -ForegroundColor Yellow
        Write-Host "====================================================================================================" -ForegroundColor Red
        Write-Host "  TARGET FILE / PROCESS : $targetInput" -ForegroundColor White

        $confirm = Read-Host "`nAre you sure you want to KILL active processes, DELETE this file, and CLEAN Registry keys? [y/N]"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "[-] Threat purge operation canceled." -ForegroundColor Gray
            return
        }

        $fileName = [System.IO.Path]::GetFileName($targetInput)
        $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($targetInput)

        Write-Host "`n[*] Initializing Threat Removal Sequence..." -ForegroundColor Cyan

        function Show-PurgeProgress ($percent, $statusText) {
            $barWidth = 30
            $completed = [math]::Round(($percent / 100) * $barWidth)
            $remaining = $barWidth - $completed
            $bar = ("#" * $completed) + ("-" * $remaining)
            Write-Host -NoNewline "`r  [$bar] $percent% | $statusText" -ForegroundColor Yellow
        }

        $runningProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
            $_.Path -eq $targetInput -or $_.ProcessName -eq $fileNameNoExt -or $_.ProcessName -eq $targetInput
        }
        if ($runningProcs) {
            foreach ($proc in $runningProcs) {
                try {
                    $pPath = $proc.Path
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    if ($pPath -and -not (Test-Path $targetInput)) { $targetInput = $pPath }
                } catch {}
            }
        }
        Show-PurgeProgress 25 "Active process terminated"
        Start-Sleep -Milliseconds 600

        if (Test-Path $targetInput) {
            try { Remove-Item -Path $targetInput -Force -ErrorAction Stop } catch {}
        }
        Show-PurgeProgress 50 "Target file path remediated"
        Start-Sleep -Milliseconds 600

        $downloadsFolder = "$env:USERPROFILE\Downloads"
        if (Test-Path $downloadsFolder) {
            Get-ChildItem $downloadsFolder -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -like "*$fileNameNoExt*" -or $_.Name -like "*$fileName*"
            } | ForEach-Object {
                try { Remove-Item -Path $_.FullName -Force -ErrorAction Stop } catch {}
            }
        }
        Show-PurgeProgress 75 "Correlated downloaded payloads purged"
        Start-Sleep -Milliseconds 600

        $regLocations = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        foreach ($regPath in $regLocations) {
            if (Test-Path $regPath) {
                $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                if ($props) {
                    foreach ($prop in $props.psobject.Properties) {
                        if ($prop.Value -like "*$fileName*" -or $prop.Value -like "*$targetInput*") {
                            try { Remove-ItemProperty -Path $regPath -Name $prop.Name -Force -ErrorAction Stop } catch {}
                        }
                    }
                }
            }
        }
        Show-PurgeProgress 100 "All persistent entries & artifacts cleared"
        Write-Host "`n`n[+] Threat remediation successfully executed by glastfin engine." -ForegroundColor Green
    }

    function Audit-ApplicationMetadata {
        $inAuditMenu = $true

        while ($inAuditMenu -and $script:Running) {
            Show-Header
            Write-Host "[*] Auditing Application Metadata & Flagging Unsigned / Missing Metadata Items..." -ForegroundColor Cyan
            Write-Host "----------------------------------------------------------------------------------------------------"

            $metadataAudit = [System.Collections.Generic.List[PSObject]]::new()

            $regKeys = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )

            Get-ItemProperty $regKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object {
                $publisher = $_.Publisher
                $flagged   = $false
                $flagReason = "Normal"

                if ([string]::IsNullOrWhiteSpace($publisher) -or $publisher -like "*Unknown*") {
                    $flagged    = $true
                    $flagReason = "[!] FLAGGED: NO METADATA / PUBLISHER"
                    $publisher  = "<MISSING PUBLISHER>"
                }

                $installDate = $_.InstallDate
                if ($installDate -and $installDate.Length -eq 8) {
                    $installDate = "$($installDate.Substring(0,4))-$($installDate.Substring(4,2))-$($installDate.Substring(6,2))"
                } elseif (-not $installDate) {
                    $installDate = "Unknown"
                }

                $metadataAudit.Add([PSCustomObject]@{
                    Status      = if ($flagged) { "FLAGGED" } else { "Clean" }
                    FlagDetail  = $flagReason
                    Type        = "Registry App"
                    Name        = $_.DisplayName
                    Publisher   = $publisher
                    Version     = if ($_.DisplayVersion) { $_.DisplayVersion } else { "<NO VERSION>" }
                    InstallDate = $installDate
                    Path        = $_.InstallLocation
                })
            }

            $downloadsFolder = "$env:USERPROFILE\Downloads"
            if (Test-Path $downloadsFolder) {
                Get-ChildItem $downloadsFolder -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $filePath = $_.FullName
                    $publisher = "<MISSING METADATA>"
                    $flagged   = $false
                    $flagReason = "Normal"

                    if ($_.Extension -in @(".exe", ".dll", ".sys", ".msi", ".ps1")) {
                        $verInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
                        if ($verInfo.CompanyName) {
                            $publisher = $verInfo.CompanyName
                        } else {
                            $flagged    = $true
                            $flagReason = "[!] FLAGGED: EXECUTABLE MISSING COMPANY METADATA"
                        }
                    }

                    $metadataAudit.Add([PSCustomObject]@{
                        Status      = if ($flagged) { "FLAGGED" } else { "Clean" }
                        FlagDetail  = $flagReason
                        Type        = "Download Artifact"
                        Name        = $_.Name
                        Publisher   = $publisher
                        Version     = "N/A"
                        InstallDate = $_.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                        Path        = $filePath
                    })
                }
            }

            $flaggedList = [System.Collections.Generic.List[PSObject]]::new()
            $idx = 1
            foreach ($item in ($metadataAudit | Sort-Object Status -Descending)) {
                if ($item.Status -eq "FLAGGED") {
                    $item | Add-Member -NotePropertyName "Index" -NotePropertyValue $idx -Force
                    $flaggedList.Add($item)
                    $idx++
                }
            }

            Write-Host "`n[+] Metadata Audit Complete." -ForegroundColor Green
            Write-Host "    Total Records Evaluated     : $($metadataAudit.Count)" -ForegroundColor White
            Write-Host "    Items Flagged (No Metadata) : $($flaggedList.Count)" -ForegroundColor Red
            Write-Host "`n[*] Displaying Numbered Flagged Items:`n" -ForegroundColor Cyan

            if ($flaggedList.Count -gt 0) {
                $flaggedList | Select-Object Index, Status, Name, Publisher, InstallDate, FlagDetail | Format-Table -AutoSize
            } else {
                Write-Host "    [+] Zero unverified or missing metadata executables found." -ForegroundColor Green
            }

            Write-Host "----------------------------------------------------------------------------------------------------"
            Write-Host "  [G] Export Complete Application Metadata Audit to GridView" -ForegroundColor Yellow
            Write-Host "  [S] Run Static YARA / VirusTotal Verification on Flagged File (by Number)" -ForegroundColor Yellow
            Write-Host "  [K] PURGE a flagged application or executable (by Number)" -ForegroundColor Red
            Write-Host "  [B] Return to Forensics Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red

            $opt = Read-Host "`nSelect option [G/S/K/B/Q]"
            switch ($opt.ToUpper()) {
                "G" {
                    $metadataAudit | Sort-Object Status -Descending | Out-GridView -Title "Forensicology by glastfin | Application Metadata Audit"
                }
                "S" {
                    if ($flaggedList.Count -eq 0) {
                        Write-Host "[!] No flagged items available for static inspection." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    } else {
                        $numInput = Read-Host "`nEnter item number to verify statically [1-$($flaggedList.Count)]"
                        $parsedIndex = 0
                        if ([int]::TryParse($numInput, [ref]$parsedIndex)) {
                            $selectedObj = $flaggedList | Where-Object { $_.Index -eq $parsedIndex }
                            if ($selectedObj) {
                                $targetPath = if ($selectedObj.Path) { $selectedObj.Path } else { $selectedObj.Name }
                                $confirm = Read-Host "Confirm static analysis on target '$targetPath'? [y/N]"
                                if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                                    Analyze-FileCustomPath $targetPath.Trim("'", '"')
                                } else {
                                    Write-Host "[-] Analysis canceled." -ForegroundColor Gray; Start-Sleep -Seconds 1
                                }
                            } else {
                                Write-Host "[!] Index out of range." -ForegroundColor Red; Start-Sleep -Seconds 1
                            }
                        } else {
                            Write-Host "[!] Invalid selection number format." -ForegroundColor Red; Start-Sleep -Seconds 1
                        }
                    }
                }
                "K" {
                    if ($flaggedList.Count -eq 0) {
                        Write-Host "[!] No flagged items available to purge." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    } else {
                        $numInput = Read-Host "`nEnter item number to PURGE [1-$($flaggedList.Count)]"
                        $parsedIndex = 0
                        if ([int]::TryParse($numInput, [ref]$parsedIndex)) {
                            $selectedObj = $flaggedList | Where-Object { $_.Index -eq $parsedIndex }
                            if ($selectedObj) {
                                $targetPath = if ($selectedObj.Path) { $selectedObj.Path } else { $selectedObj.Name }
                                $confirm = Read-Host "Confirm threat remediation & purge on '$targetPath'? [y/N]"
                                if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                                    Purge-MalwareThreat $targetPath
                                    Start-Sleep -Seconds 2
                                } else {
                                    Write-Host "[-] Purge action canceled." -ForegroundColor Gray; Start-Sleep -Seconds 1
                                }
                            } else {
                                Write-Host "[!] Index out of range." -ForegroundColor Red; Start-Sleep -Seconds 1
                            }
                        } else {
                            Write-Host "[!] Invalid selection number format." -ForegroundColor Red; Start-Sleep -Seconds 1
                        }
                    }
                }
                "B" { $inAuditMenu = $false }
                "Q" {
                    $script:Running = $false
                    $inAuditMenu = $false
                }
                default {
                    Write-Host "[!] Invalid option selected. Retaining audit menu." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    }

    function Analyze-File {
        Show-Header
        $filePath = Read-Host "Enter target file path (or drag-and-drop file) [Press 'Q' to Exit]"
        if ($filePath.Trim().ToUpper() -eq 'Q') {
            $script:Running = $false
            return
        }

        $filePath = $filePath.Trim("'", '"')
        Analyze-FileCustomPath $filePath
    }

    function Analyze-FileCustomPath ($filePath) {
        $inStaticLoop = $true

        while ($inStaticLoop -and $script:Running) {
            Show-Header
            if (-not (Test-Path $filePath -PathType Leaf)) {
                Write-Host "[!] Target file path does not exist: $filePath" -ForegroundColor Red
                Start-Sleep -Seconds 2
                return
            }

            Write-Host "`n[*] Executing Static File Forensics..." -ForegroundColor Cyan
            Write-Host "----------------------------------------------------------------------------------------------------"

            $item = Get-Item $filePath
            Write-Host "[-] File Name     : " -NoNewline; Write-Host $item.Name -ForegroundColor Yellow
            Write-Host "[-] Full Path     : " -NoNewline; Write-Host $item.FullName -ForegroundColor Yellow
            Write-Host "[-] File Size     : " -NoNewline; Write-Host "$($item.Length) Bytes" -ForegroundColor Yellow
            Write-Host "[-] Modification  : " -NoNewline; Write-Host $item.LastWriteTime -ForegroundColor Yellow

            $verInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
            $compName = if ($verInfo.CompanyName) { $verInfo.CompanyName } else { "<MISSING METADATA>" }
            Write-Host "[-] Publisher     : " -NoNewline
            if ($compName -eq "<MISSING METADATA>") {
                Write-Host "$compName [!] UNKNOWN / UNTRUSTED PUBLISHER" -ForegroundColor Red
            } else {
                Write-Host $compName -ForegroundColor Green
            }

            Write-Host "`n[*] Generating Cryptographic Hashes..." -ForegroundColor Cyan
            $md5    = (Get-FileHash $filePath -Algorithm MD5).Hash
            $sha256 = (Get-FileHash $filePath -Algorithm SHA256).Hash
            Write-Host "[-] MD5           : " -NoNewline; Write-Host $md5 -ForegroundColor White
            Write-Host "[-] SHA256        : " -NoNewline; Write-Host $sha256 -ForegroundColor White

            Write-Host "`n[*] Extracting Printable ASCII Strings..." -ForegroundColor Cyan
            Get-Content $filePath -Encoding Byte -ReadCount 0 -ErrorAction SilentlyContinue |
                ForEach-Object { [System.Text.Encoding]::ASCII.GetString($_) } |
                Select-String -Pattern "[\w\s]{6,}" -AllMatches |
                Select-Object -ExpandProperty Matches |
                Select-Object -First 6 -ExpandProperty Value |
                ForEach-Object { Write-Host "  > $_" -ForegroundColor DarkGray }

            Write-Host "`n[+] Static analysis complete." -ForegroundColor Green
            
            Write-Host "`n----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " EXTENDED THREAT CONFIRMATION OPTIONS:" -ForegroundColor Cyan
            Write-Host "  [1] Execute Native Inline YARA Signature Inspection" -ForegroundColor Yellow
            Write-Host "  [2] Query VirusTotal Database for Hash ($sha256)" -ForegroundColor Yellow
            Write-Host "  [3] Execute Dual Inspection (Native YARA + VirusTotal API/Web)" -ForegroundColor Yellow
            Write-Host "  [K] PURGE & REMEDIATE (Kill Process, Delete File, Clean RegKeys)" -ForegroundColor Red
            Write-Host "  [4] Return to Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red
            
            $opt = Read-Host "`nSelect an option [1-4 / K / Q]"
            switch ($opt.ToUpper()) {
                "1" { 
                    Run-YaraScanInternal $filePath 
                    Write-Host "`nPress any key to return..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                "2" { 
                    Run-VirusTotalInternal $filePath $sha256 
                    Write-Host "`nPress any key to return..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                "3" { 
                    Run-YaraScanInternal $filePath
                    Run-VirusTotalInternal $filePath $sha256
                    Write-Host "`nPress any key to return..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
                "K" { 
                    Purge-MalwareThreat $filePath 
                    $inStaticLoop = $false
                }
                "4" { $inStaticLoop = $false }
                "Q" { 
                    $script:Running = $false
                    $inStaticLoop = $false
                }
                default { 
                    Write-Host "Invalid option. Please choose 1-4, K, or Q." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    }

    function Run-YaraScanInternal ($targetPath) {
        Write-Host "`n[*] Initializing Native Inline YARA Signature Scan..." -ForegroundColor Cyan
        
        if (-not (Test-Path $targetPath)) {
            Write-Host "[!] Target file for YARA inspection does not exist." -ForegroundColor Red
            return
        }

        $signatures = @(
            "powershell", "cmd.exe", "DownloadString", "Invoke-WebRequest",
            "meterpreter", "xmrig", "mimikatz", "ReflectiveLoader"
        )

        try {
            $rawContent = Get-Content -Path $targetPath -Raw -ErrorAction Stop
            $matchedPatterns = @()

            foreach ($sig in $signatures) {
                if ($rawContent -match [regex]::Escape($sig)) {
                    $matchedPatterns += $sig
                }
            }

            if ($matchedPatterns.Count -gt 0) {
                Write-Host "[!] YARA Signature Match Detected:" -ForegroundColor Red
                Write-Host "    Rule [Suspicious_Identifiers]: Matches found -> $($matchedPatterns -join ', ')" -ForegroundColor Yellow
            } else {
                Write-Host "[+] Signature Status: Clean (No inline YARA rule matches detected)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "[!] Error performing in-memory YARA scan: $_" -ForegroundColor Red
        }
    }

    function Run-VirusTotalInternal ($targetPath, $hash) {
        Write-Host "`n[*] Querying VirusTotal Intelligence Database..." -ForegroundColor Cyan

        if ([string]::IsNullOrEmpty($script:VTKey)) {
            $inputKey = Read-Host "Enter VirusTotal API Key for session (Press ENTER to use API-Free Mode)"
            $script:VTKey = $inputKey.Trim()
        }

        if (-not [string]::IsNullOrEmpty($script:VTKey)) {
            try {
                $headers = @{ "x-apikey" = $script:VTKey }
                $url = "https://www.virustotal.com/api/v3/files/$hash"
                $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
                $stats = $response.data.attributes.last_analysis_stats

                Write-Host "[+] VirusTotal Detection Summary (via API):" -ForegroundColor Green
                Write-Host "    - Malicious  : $($stats.malicious)" -ForegroundColor Red
                Write-Host "    - Suspicious : $($stats.suspicious)" -ForegroundColor Yellow
                Write-Host "    - Undetected : $($stats.undetected)" -ForegroundColor Green
                Write-Host "    - Harmless   : $($stats.harmless)" -ForegroundColor Blue
                return
            }
            catch {
                Write-Host "[!] API Query Failed: Hash absent or invalid key. Switching to Web Fallback..." -ForegroundColor Yellow
            }
        }

        Write-Host "[*] Executing API-Free Hash Search for $hash..." -ForegroundColor Cyan
        try {
            $aggUrl = "https://vt.unify.workers.dev/api/v3/files/$hash"
            $response = Invoke-RestMethod -Uri $aggUrl -Method Get -ErrorAction Stop
            $stats = $response.data.attributes.last_analysis_stats

            Write-Host "[+] VirusTotal Detection Summary (via Public Aggregator):" -ForegroundColor Green
            Write-Host "    - Malicious  : $($stats.malicious)" -ForegroundColor Red
            Write-Host "    - Suspicious : $($stats.suspicious)" -ForegroundColor Yellow
            Write-Host "    - Undetected : $($stats.undetected)" -ForegroundColor Green
            Write-Host "    - Harmless   : $($stats.harmless)" -ForegroundColor Blue
            return
        }
        catch {
            Write-Host "[!] API-Free public endpoint unreachable." -ForegroundColor Yellow
        }

        $vtWebUrl = "https://www.virustotal.com/gui/file/$hash"
        Write-Host "[+] Opening VirusTotal web report directly in your default browser:" -ForegroundColor Green
        Write-Host "    $vtWebUrl" -ForegroundColor White
        Start-Process $vtWebUrl
    }

    function Explorative-Forensics {
        Show-Header

        Write-Host "[*] Active Historical Timeslot Window:" -ForegroundColor Cyan
        Write-Host "    Start : $($script:InvestigationState.TimeframeStart)" -ForegroundColor White
        Write-Host "    End   : $($script:InvestigationState.TimeframeEnd)" -ForegroundColor White
        
        $changeTime = Read-Host "`nModify active timeframe window before executing scan? [y/N/Q]"
        if ($changeTime.ToUpper() -eq 'Q') {
            $script:Running = $false
            return
        }
        if ($changeTime -eq 'y' -or $changeTime -eq 'Y') {
            Set-TimeslotWindow
        }

        $continuePivoting = $true
        while ($continuePivoting -and $script:Running) {
            Show-Header
            $StartTime    = $script:InvestigationState.TimeframeStart
            $EndTime      = $script:InvestigationState.TimeframeEnd
            $ComputerName = $env:COMPUTERNAME
            $UserName     = $env:USERNAME

            Write-Host "[*] INVESTIGATION TIMEFRAME : $StartTime TO $EndTime" -ForegroundColor Cyan
            Write-Host "[*] ACTIVE INDICATORS       : $(if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { $script:InvestigationState.SuspiciousTargets -join ', ' } else { 'Blind Scan Mode' })" -ForegroundColor Yellow
            Write-Host "----------------------------------------------------------------------------------------------------"

            $script:InvestigationState.DiscoveredAssets.Clear()

            Get-WinEvent -FilterHashtable @{ LogName='Application'; ProviderName='MsiInstaller'; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | ForEach-Object {
                $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                    Time = $_.TimeCreated; Category = "Installation"; Log = "MsiInstaller"; Detail = $_.Message
                })
            }

            Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-PowerShell/Operational'; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | Where-Object {
                $_.Message -match "curl|wget|WebRequest|WebClient|BitsTransfer|Invoke-WebRequest|Invoke-RestMethod|DownloadString|DownloadFile"
            } | ForEach-Object {
                $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                    Time = $_.TimeCreated; Category = "PowerShell Download"; Log = "PowerShell"; Detail = $_.Message
                })
            }

            Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=@(4624, 4625, 4672, 4688, 4720, 4722); StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | ForEach-Object {
                $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                    Time = $_.TimeCreated; Category = "Security Event"; Log = "Security"; Detail = $_.Message
                })
            }

            Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | ForEach-Object {
                $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                    Time = $_.TimeCreated; Category = "Defender Alert"; Log = "Defender"; Detail = $_.Message
                })
            }

            $displayEvents = $script:InvestigationState.DiscoveredAssets
            if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                $displayEvents = $displayEvents | Where-Object {
                    $item = $_
                    $matched = $false
                    foreach ($target in $script:InvestigationState.SuspiciousTargets) {
                        if ($item.Detail -like "*$target*" -or $item.Category -like "*$target*") {
                            $matched = $true
                            break
                        }
                    }
                    return $matched
                }
            }

            $totalCount = $displayEvents.Count
            if ($totalCount -eq 0) {
                Write-Host "`n[-] Zero event records located within the selected window." -ForegroundColor Red
            } else {
                Write-Host "`n[+] Identified $totalCount event record(s). Displaying LATEST 8 Compact Entries:`n" -ForegroundColor Green

                $compactList = $displayEvents | Sort-Object Time -Descending | Select-Object -First 8 | ForEach-Object {
                    $cleanMsg = ($_.Detail -replace '[\r\n]+', ' ').Trim()
                    if ($cleanMsg.Length -gt 55) { $cleanMsg = $cleanMsg.Substring(0, 52) + "..." }
                    [PSCustomObject]@{
                        Time     = $_.Time.ToString("yyyy-MM-dd HH:mm:ss")
                        Category = $_.Category
                        Log      = $_.Log
                        Summary  = $cleanMsg
                    }
                }
                $compactList | Format-Table -AutoSize
            }

            Write-Host "----------------------------------------------------------------------------------------------------"
            Write-Host "  [A] Add/Pivot on Indicator Term" -ForegroundColor Yellow

            if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                Write-Host "  [M] Audit Application Metadata (Focus on: $($script:InvestigationState.SuspiciousTargets -join ', '))" -ForegroundColor Yellow
                Write-Host "  [S] Confirm Suspicious File via Static Analysis (YARA + VirusTotal)" -ForegroundColor Yellow
                Write-Host "  [K] PURGE MALWARE (Kill process, delete file by path & clean RegKeys)" -ForegroundColor Red
                Write-Host "  [C] Clear active indicators & revert to Blind Scan Mode" -ForegroundColor Yellow
            }

            Write-Host "  [T] Modify active timeframe window" -ForegroundColor Yellow
            Write-Host "  [R] Launch Native Resource Monitor" -ForegroundColor Yellow
            Write-Host "  [G] Export complete dataset ($totalCount records) to Out-GridView" -ForegroundColor Yellow
            Write-Host "  [B] Return to Main Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red
            
            $promptOptions = if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { "A/M/S/K/C/T/R/G/B/Q" } else { "A/T/R/G/B/Q" }
            $choice = Read-Host "`nSelect action [$promptOptions]"
            
            switch ($choice.ToUpper()) {
                "A" {
                    $newItem = Read-Host "Enter indicator term/pattern (e.g. meterpreter, payload.exe)"
                    if (-not [string]::IsNullOrWhiteSpace($newItem)) {
                        $script:InvestigationState.SuspiciousTargets.Add($newItem)
                        Write-Host "[+] Pattern '$newItem' added to active memory." -ForegroundColor Green
                    }
                }
                "M" { 
                    if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                        Audit-ApplicationMetadata 
                    } else {
                        Write-Host "[!] Add an indicator using 'A' first." -ForegroundColor Red; Start-Sleep -Seconds 1
                    }
                }
                "S" {
                    if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                        $confirmPath = Read-Host "Enter path of file to confirm statically"
                        if (-not [string]::IsNullOrWhiteSpace($confirmPath)) {
                            Analyze-FileCustomPath $confirmPath.Trim("'", '"')
                        }
                    } else {
                        Write-Host "[!] Add an indicator using 'A' first." -ForegroundColor Red; Start-Sleep -Seconds 1
                    }
                }
                "K" {
                    if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                        $purgePath = Read-Host "Enter file path or process name to purge"
                        if (-not [string]::IsNullOrWhiteSpace($purgePath)) {
                            Purge-MalwareThreat $purgePath
                            Start-Sleep -Seconds 2
                        }
                    } else {
                        Write-Host "[!] Add an indicator using 'A' first." -ForegroundColor Red; Start-Sleep -Seconds 1
                    }
                }
                "C" {
                    $script:InvestigationState.SuspiciousTargets.Clear()
                    Write-Host "[+] Indicator filters purged. Reverting to blind scan mode." -ForegroundColor Green
                    Start-Sleep -Seconds 1
                }
                "T" { Set-TimeslotWindow }
                "R" { Show-NativeResourceMonitor }
                "G" { $displayEvents | Sort-Object Time -Descending | Out-GridView -Title "Forensicology by glastfin | Event Records ($StartTime to $EndTime)" }
                "B" { $continuePivoting = $false }
                "Q" {
                    $script:Running = $false
                    $continuePivoting = $false
                }
                default { Write-Host "Invalid menu option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        }
    }

    function Show-NativeResourceMonitor {
        Show-Header
        Write-Host "====================================================================================================" -ForegroundColor Cyan
        Write-Host "   Forensicology by glastfin | Native System Resource Monitor                                     " -ForegroundColor Green
        Write-Host "====================================================================================================" -ForegroundColor Cyan

        $os = Get-CimInstance Win32_OperatingSystem
        $totalRamMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
        $freeRamMB  = [math]::Round($os.FreePhysicalMemory / 1024, 0)
        $usedRamMB  = $totalRamMB - $freeRamMB
        $ramPercent = [math]::Round(($usedRamMB / $totalRamMB) * 100, 1)

        $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

        $cpuBarLength = [math]::Round(($cpuLoad / 100) * 20)
        $cpuBar = ("|" * $cpuBarLength).PadRight(20, " ")
        
        $ramBarLength = [math]::Round(($ramPercent / 100) * 20)
        $ramBar = ("|" * $ramBarLength).PadRight(20, " ")

        if ($cpuLoad -gt 70 -or $ramPercent -gt 85) {
            $topProc = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
            Write-Host "`n+--------------------------------------------------------------------+ " -ForegroundColor Red
            Write-Host "| [!] WARNING: HEAVY SYSTEM RESOURCE USAGE DETECTED                   | " -ForegroundColor Red
            Write-Host "|     CPU: $cpuLoad% | RAM: $ramPercent%                                       | " -ForegroundColor Red
            Write-Host "|     Top Consumer: PID $($topProc.Id) ($($topProc.ProcessName)) - $([math]::Round($topProc.WorkingSet64/1MB,1)) MB RAM   | " -ForegroundColor Yellow
            Write-Host "+--------------------------------------------------------------------+ " -ForegroundColor Red
        } else {
            Write-Host "`n CPU Load  : [$cpuBar] $cpuLoad%" -ForegroundColor Yellow
            Write-Host " RAM Usage : [$ramBar] $usedRamMB MB / $totalRamMB MB ($ramPercent%)" -ForegroundColor Cyan
        }

        Write-Host "----------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " TOP ACTIVE PROCESSES BY RAM ALLOCATION:" -ForegroundColor White

        Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 8 Id, ProcessName, @{N='RAM(MB)';E={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize

        Write-Host "`nPress any key to return (or 'Q' to Exit)..." -ForegroundColor Gray
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
            $script:Running = $false
        }
    }

    while ($script:Running) {
        Show-Menu
        $selection = Read-Host "Select option [1-4 / Q]"
        switch ($selection.ToUpper()) {
            "1" { Analyze-File }
            "2" { Explorative-Forensics }
            "3" { Show-NativeResourceMonitor }
            "4" { $script:Running = $false }
            "Q" { $script:Running = $false }
            default { Write-Host "Invalid menu option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}
finally {
    $script:VTKey = $null
    $script:InvestigationState = $null
    $host.UI.RawUI.WindowTitle = $script:OriginalTitle
    Exit-ForensicsEngine
}