# ==============================================================================
# Program    : FORENSICOLOGY
# Author     : GlaStFiN
# Description: Monolithic In-Memory Windows Incident Response & Remediation Suite
# Mission    : "I endeavor to make this cyber world easier and 'safer' to live in"
# Execution  : Global IEX / Local PowerShell Compatible
# ==============================================================================

try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
}
catch {
    if ($MyInvocation.PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.PSCommandPath)`"" -Verb RunAs
        exit
    }
}

$script:VTKey = ""
$script:OriginalTitle = $host.UI.RawUI.WindowTitle
$script:Running = $true
$script:HostIdentifier = $env:COMPUTERNAME

# Session Memory State
$script:InvestigationState = [PSCustomObject]@{
    SuspiciousTargets = [System.Collections.Generic.List[string]]::new()
    IgnoredCategories = [System.Collections.Generic.List[string]]::new()
    TimeframeStart    = (Get-Date).AddDays(-1)
    TimeframeEnd      = Get-Date
    DiscoveredAssets  = [System.Collections.Generic.List[PSObject]]::new()
    AuditHistory      = [System.Collections.Generic.List[PSObject]]::new()
    DiscoveredIPs     = [System.Collections.Generic.HashSet[string]]::new()
}

function Read-CustomInput ($promptText) {
    Write-Host -NoNewline $promptText
    $inputStr = ""
    while ($script:Running) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ([int]$key.KeyChar -eq 3 -or ($key.Key -eq "C" -and $key.Modifiers -match "Control")) {
                Write-Host "`n [!] ^C Interrupt Captured - Triggering Termination Engine..." -ForegroundColor Magenta
                $confirm = Show-CenteredExitBox -titleMessage "SESSION TERMINATION AND PURGE ENGINE"
                if ($confirm) {
                    $script:Running = $false
                    return "Q"
                } else {
                    Write-Host "`n [*] Resuming session..." -ForegroundColor Green
                    return ""
                }
            }
            elseif ($key.Key -eq "Enter") {
                Write-Host ""
                return $inputStr
            }
            elseif ($key.Key -eq "Backspace") {
                if ($inputStr.Length -gt 0) {
                    $inputStr = $inputStr.Substring(0, $inputStr.Length - 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            else {
                $inputStr += $key.KeyChar
                Write-Host -NoNewline $key.KeyChar
            }
        }
        Start-Sleep -Milliseconds 20
    }
    return "Q"
}

[Console]::TreatControlCAsInput = $true
$cancelHandler = [ConsoleCancelEventHandler]{
    param($sender, $eventArgs)
    $eventArgs.Cancel = $true
    $script:Running = $false
}
[Console]::add_CancelKeyPress($cancelHandler)

try {
    if ($host.Name -eq "ConsoleHost") {
        $host.UI.RawUI.WindowTitle = "GLASTFIN :: FORENSICOLOGY | Endpoint Forensics Suite"
    }

    Clear-Host
    Write-Host "`n  $([char]27)[3mBonsoir, GlaStFiN~$([char]27)[0m`n" -ForegroundColor DarkMagenta
    Start-Sleep -Seconds 1

    function Show-Header ($catMood = "home") {
        Clear-Host
        $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"

        Write-Host " +-------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host " |  ___ ___  ___ ___ _  _ ___ ___ ___  ___  _    ___   ___  __   __   |    .-'''-.                     |" -ForegroundColor DarkMagenta
        Write-Host " | | __/ _ \| _ \ __| \| / __|_ _| __/ _ \| |  / _ \ / \ \ \ / /   |   /   _   \  Glory to         |" -ForegroundColor DarkMagenta
        Write-Host " | | _| (_) |   / _|| .` \__ \| || _| (_) | |_| (_) | () \ V /    |  | =|=====|= | Mankind.         |" -ForegroundColor Magenta
        Write-Host " | |_| \___/|_|_\___|_|\_|___/___|___\___/|____\___/ \__/ |_|     |   \  \___/  /                  |" -ForegroundColor Magenta
        Write-Host " +-------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host " |  FSOCIETY :: CONTROL IS AN ILLUSION. LEAVE NO TRACE IN MEMORY.                                  |" -ForegroundColor Red
        Write-Host " +-------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host ("|		LEAD : {0,-35} | TIME : {1,-28} |" -f $script:HostIdentifier, $currentDateTime) -ForegroundColor Cyan
        Write-Host " +-------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host ""
    }

    function Show-CenteredExitBox ($titleMessage = "SESSION TERMINATION AND PURGE ENGINE") {
        Clear-Host
        $rawUI = $host.UI.RawUI
        $width = 80
        if ($rawUI -and $rawUI.WindowSize.Width -gt 60) { $width = $rawUI.WindowSize.Width }

        $boxWidth = 58
        $padLeft = [math]::Max(0, [math]::Floor(($width - $boxWidth) / 2))
        $indent = " " * $padLeft

        $formattedTitle = $titleMessage.PadRight(52).Substring(0, 52)

        Write-Host "`n`n"
        Write-Host ("{0}+----------------------------------------------------------+" -f $indent) -ForegroundColor Magenta
        Write-Host ("{0}| {1} |" -f $indent, $formattedTitle) -ForegroundColor Red
        Write-Host ("{0}+----------------------------------------------------------+" -f $indent) -ForegroundColor Magenta
        Write-Host ("{0}|    /\_/\                                                 |" -f $indent) -ForegroundColor DarkMagenta
        Write-Host ("{0}|  ( u.u )  [ENTER] Confirm Termination & Purge Memory     |" -f $indent) -ForegroundColor Yellow
        Write-Host ("{0}|    > ^ <  [ B ]   Cancel & Stay in Forensics Suite       |" -f $indent) -ForegroundColor Cyan
        Write-Host ("{0}+----------------------------------------------------------+" -f $indent) -ForegroundColor Magenta
        
        $choice = Read-CustomInput ("`n{0} Select Choice [ENTER/B]: " -f $indent)
        if ($choice.Trim().ToUpper() -eq 'B') {
            $script:Running = $true
            return $false
        }
        $script:Running = $false
        return $true
    }

    function Exit-ForensicsEngine {
        Clear-Host
        Write-Host "+--------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        Write-Host "|    /\_/\                                                                                         |" -ForegroundColor DarkMagenta
        Write-Host "|   ( u.u )  [*] In-Memory Session Destroyed Safely                                               |" -ForegroundColor Gray
        Write-Host "|    > ^ <   [*] API Tokens & State Vector Purged                                                 |" -ForegroundColor Gray
        Write-Host "|            [*] FORENSICOLOGY by GlaStFiN session cleanly terminated.                            |" -ForegroundColor Green
        Write-Host "+--------------------------------------------------------------------------------------------------+" -ForegroundColor Magenta
        
        Write-Host "`n  $([char]27)[3mGlory to Mankind, GlaStFiN~$([char]27)[0m`n" -ForegroundColor DarkYellow
        Start-Sleep -Seconds 1
    }

    function Get-FastReverseDNS ($ipAddress) {
        try {
            $task = [System.Net.Dns]::GetHostEntryAsync($ipAddress)
            if ($task.Wait(200)) { return $task.Result.HostName }
        } catch {}
        return "Unresolved"
    }

    function Clear-SessionMemoryState {
        $script:InvestigationState.SuspiciousTargets.Clear()
        $script:InvestigationState.IgnoredCategories.Clear()
        $script:InvestigationState.DiscoveredAssets.Clear()
        $script:InvestigationState.AuditHistory.Clear()
        $script:InvestigationState.DiscoveredIPs.Clear()
        [System.GC]::Collect()
        Write-Host "`n  [+] In-Memory investigation state successfully flushed." -ForegroundColor Green
        Start-Sleep -Seconds 1
    }

    function Set-InvestigationTimeframe {
        Write-Host "`n  +--- ADJUST INVESTIGATION TIMEFRAME (FUZZY & RELATIVE) -----------------------------------------+" -ForegroundColor Cyan
        Write-Host "  | Current Window: " -NoNewline
        Write-Host ("{0} TO {1}" -f $script:InvestigationState.TimeframeStart, $script:InvestigationState.TimeframeEnd) -ForegroundColor Yellow
        Write-Host "  +-----------------------------------------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  [1] Last 1 Hour" -ForegroundColor Yellow
        Write-Host "  [2] Last 24 Hours (Default)" -ForegroundColor Yellow
        Write-Host "  [3] Last 7 Days" -ForegroundColor Yellow
        Write-Host "  [4] Custom Range (Specify Days)" -ForegroundColor Yellow
        Write-Host "  [5] Last Month (~30 Days / Fuzzy)" -ForegroundColor Yellow
        Write-Host "  [6] Last Year (~365 Days / Fuzzy)" -ForegroundColor Yellow
        Write-Host "  [B] Keep Current Timeframe" -ForegroundColor Gray

        $tChoice = Read-CustomInput "`n  Select Timeframe Option [1-6 / B]: "
        $cleanChoice = $tChoice.Trim().ToLower()

        switch -Wildcard ($cleanChoice) {
            { $_ -eq "1" -or $_ -like "*hour*" } {
                $script:InvestigationState.TimeframeStart = (Get-Date).AddHours(-1)
                $script:InvestigationState.TimeframeEnd   = Get-Date
                $script:InvestigationState.DiscoveredAssets.Clear()
                Write-Host "  [+] Timeframe set to Last 1 Hour." -ForegroundColor Green
            }
            { $_ -eq "2" -or $_ -like "*24*" -or $_ -like "*day*" } {
                $script:InvestigationState.TimeframeStart = (Get-Date).AddDays(-1)
                $script:InvestigationState.TimeframeEnd   = Get-Date
                $script:InvestigationState.DiscoveredAssets.Clear()
                Write-Host "  [+] Timeframe set to Last 24 Hours." -ForegroundColor Green
            }
            { $_ -eq "3" -or $_ -like "*7*" } {
                $script:InvestigationState.TimeframeStart = (Get-Date).AddDays(-7)
                $script:InvestigationState.TimeframeEnd   = Get-Date
                $script:InvestigationState.DiscoveredAssets.Clear()
                Write-Host "  [+] Timeframe set to Last 7 Days." -ForegroundColor Green
            }
            { $_ -eq "4" -or $_ -like "*custom*" } {
                $daysInput = Read-CustomInput "  Enter number of past days to query (e.g. 3, 14, 30): "
                $parsedDays = 0
                if ([int]::TryParse($daysInput, [ref]$parsedDays) -and $parsedDays -gt 0) {
                    $script:InvestigationState.TimeframeStart = (Get-Date).AddDays(-$parsedDays)
                    $script:InvestigationState.TimeframeEnd   = Get-Date
                    $script:InvestigationState.DiscoveredAssets.Clear()
                    Write-Host ("  [+] Timeframe set to Last {0} Days." -f $parsedDays) -ForegroundColor Green
                } else {
                    Write-Host "  [!] Invalid number entered. Timeframe unmodified." -ForegroundColor Red
                }
            }
            { $_ -eq "5" -or $_ -like "*month*" } {
                $script:InvestigationState.TimeframeStart = (Get-Date).AddDays(-30)
                $script:InvestigationState.TimeframeEnd   = Get-Date
                $script:InvestigationState.DiscoveredAssets.Clear()
                Write-Host "  [+] Timeframe set to Last Month (~30 Days Fuzzy Range)." -ForegroundColor Green
            }
            { $_ -eq "6" -or $_ -like "*year*" } {
                $script:InvestigationState.TimeframeStart = (Get-Date).AddDays(-365)
                $script:InvestigationState.TimeframeEnd   = Get-Date
                $script:InvestigationState.DiscoveredAssets.Clear()
                Write-Host "  [+] Timeframe set to Last Year (~365 Days Fuzzy Range)." -ForegroundColor Green
            }
            default {
                Write-Host "  [!] Selection not recognized. Timeframe unmodified." -ForegroundColor Yellow
            }
        }
        Start-Sleep -Seconds 1
    }

    # ==============================================================================
    # CONSCOPE: Live Endpoint Connections, Sockets, Ports & Routing Suite
    # ==============================================================================
    function Show-ConScopeMenu {
        $inConScope = $true
        while ($inConScope -and $script:Running) {
            Show-Header -catMood "conscope"
            Write-Host "  +--- CONSCOPE: LIVE ENDPOINT CONNECTIONS, PORTS & ROUTING SUITE -----------------------------+" -ForegroundColor Cyan
            Write-Host "  |" -ForegroundColor Cyan
            Write-Host "  +---> [1] Active Socket Correlation Scan" -ForegroundColor Yellow
            Write-Host "  +---> [2] Active Listening Ports & Owning Process Map" -ForegroundColor Yellow
            Write-Host "  +---> [3] ARP Cache & Gateway Integrity Check" -ForegroundColor Yellow
            Write-Host "  +---> [4] Active IPv4 Routing Table Inspection" -ForegroundColor Yellow
            Write-Host "  +---> [5] Socket Traffic Filter" -ForegroundColor Yellow
            Write-Host "  |" -ForegroundColor Cyan
            Write-Host "  +---> [B] Return to Main Menu" -ForegroundColor Gray
            Write-Host "  +---> [Q] Exit Application" -ForegroundColor Red
            Write-Host ""

            $opt = Read-CustomInput "  Select ConScope Option [1-5 / B / Q]: "
            switch ($opt.ToUpper()) {
                "1" { Invoke-ConScopeScan }
                "2" {
                    Write-Host "`n  [*] ConScope Active Listener Matrix:`n" -ForegroundColor Cyan
                    $procMap = @{}
                    Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $procMap[$_.Id] = $_.ProcessName }
                    
                    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
                        $pName = if ($procMap.ContainsKey($_.OwningProcess)) { $procMap[$_.OwningProcess] } else { "Unknown" }
                        [PSCustomObject]@{
                            LocalAddress = $_.LocalAddress
                            LocalPort    = $_.LocalPort
                            PID          = $_.OwningProcess
                            Process      = $pName
                        }
                    } | Format-Table -AutoSize
                    Read-CustomInput "`n  Press Enter to continue..." | Out-Null
                }
                "3" {
                    Write-Host "`n  [*] ConScope ARP Neighbor Cache:`n" -ForegroundColor Cyan
                    Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
                        Select-Object IPAddress, LinkLayerAddress, State, InterfaceAlias | 
                        Format-Table -AutoSize
                    Read-CustomInput "`n  Press Enter to continue..." | Out-Null
                }
                "4" {
                    Write-Host "`n  [*] ConScope IPv4 Routing Table:`n" -ForegroundColor Cyan
                    Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
                        Select-Object DestinationPrefix, NextHop, RouteMetric, InterfaceAlias | 
                        Format-Table -AutoSize
                    Read-CustomInput "`n  Press Enter to continue..." | Out-Null
                }
                "5" {
                    $filterVal = Read-CustomInput "  Enter Port Number or PID to filter sockets: "
                    if (-not [string]::IsNullOrWhiteSpace($filterVal)) {
                        Write-Host ("`n  [*] Filtering Sockets for Term '{0}':`n" -f $filterVal) -ForegroundColor Cyan
                        Get-NetTCPConnection -ErrorAction SilentlyContinue | 
                            Where-Object { $_.LocalPort -eq $filterVal -or $_.RemotePort -eq $filterVal -or $_.OwningProcess -eq $filterVal } |
                            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
                            Format-Table -AutoSize
                    }
                    Read-CustomInput "`n  Press Enter to continue..." | Out-Null
                }
                "B" { $inConScope = $false }
                "Q" { $script:Running = $false; $inConScope = $false }
                default { Write-Host "  [!] Invalid choice. Please select [1-5 / B / Q]." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        }
    }

    function Invoke-ConScopeScan {
        Show-Header -catMood "conscope"
        Write-Host "  [*] Executing ConScope Pipeline (Netstat -> PID -> Reverse DNS)..." -ForegroundColor Cyan
        Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

        $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        if (-not $conns) {
            Write-Host "  [-] No active ESTABLISHED connections found on host." -ForegroundColor Yellow
            Start-Sleep -Seconds 1.5
            return
        }

        $procMap = @{}
        Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $procMap[$_.Id] = $_.ProcessName }

        $results = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($c in $conns) {
            $rIP   = $c.RemoteAddress
            $pidN  = $c.OwningProcess
            $pName = if ($procMap.ContainsKey($pidN)) { $procMap[$pidN] } else { "Unknown" }

            if ($rIP -notmatch "^(127\.|169\.254\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.|::1|fe80:)") {
                [void]$script:InvestigationState.DiscoveredIPs.Add($rIP)
            }

            $hostName = Get-FastReverseDNS $rIP

            $results.Add([PSCustomObject]@{
                Process      = $pName
                PID          = $pidN
                LocalPort    = $c.LocalPort
                RemoteIP     = $rIP
                RemotePort   = $c.RemotePort
                ResolvedHost = $hostName
            })
        }

        Write-Host "`n  [+] Active Socket Correlation Matrix:`n" -ForegroundColor Green
        $results | Format-Table Process, PID, LocalPort, RemoteIP, RemotePort, ResolvedHost -AutoSize

        Write-Host ("  [+] Unique External Public IPs Saved in Memory ({0} found):" -f $script:InvestigationState.DiscoveredIPs.Count) -ForegroundColor Green
        foreach ($ip in $script:InvestigationState.DiscoveredIPs) {
            Write-Host ("      - IP: {0}" -f $ip) -ForegroundColor White
        }

        $inConScopePivot = $true
        while ($inConScopePivot -and $script:Running) {
            Write-Host "`n  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkMagenta
            Write-Host "  [1] Generate VirusTotal Lookup Links for Saved Public IPs" -ForegroundColor Yellow
            Write-Host "  [2] Pivot Process / Application Name directly to Historical Log Engine" -ForegroundColor Yellow
            Write-Host "  [3] Pivot Process / Executable Path to Static File Inspection Engine" -ForegroundColor Yellow
            Write-Host "  [B] Return to ConScope Menu" -ForegroundColor Gray

            $opt = Read-CustomInput "`n  Select ConScope Action [1-3 / B]: "
            switch ($opt.Trim().ToUpper()) {
                '1' { Invoke-VirusTotalIPLookup }
                '2' {
                    $targetProc = Read-CustomInput "  Enter Application/Process Name to pivot into logs: "
                    if (-not [string]::IsNullOrWhiteSpace($targetProc)) {
                        $cleanProc = $targetProc.Trim()
                        if (-not $script:InvestigationState.SuspiciousTargets.Contains($cleanProc)) {
                            $script:InvestigationState.SuspiciousTargets.Add($cleanProc)
                        }
                        Explorative-Forensics
                    }
                }
                '3' {
                    $targetPath = Read-CustomInput "  Enter Process Path or Executable Name to analyze statically: "
                    if (-not [string]::IsNullOrWhiteSpace($targetPath)) {
                        Analyze-FileCustomPath $targetPath.Trim("'", '"')
                    }
                }
                'B' { $inConScopePivot = $false }
                default { Write-Host "  [!] Option unrecognized. Returning to ConScope scope." -ForegroundColor Yellow }
            }
        }
    }

    # ==============================================================================
    # NETSCOPE: Deep Forensics, Timeframe & Artifact Engine
    # ==============================================================================
    function Show-NetScopeMenu {
        $inNetScope = $true
        while ($inNetScope -and $script:Running) {
            Show-Header -catMood "netscope"
            Write-Host "  +--- NETSCOPE: DEEP FORENSICS & HISTORICAL LOG ENGINE -------------------------------------------+" -ForegroundColor Cyan
            Write-Host "  |" -ForegroundColor Cyan
            Write-Host ("  |   Active Timeframe: {0} TO {1}" -f $script:InvestigationState.TimeframeStart.ToString("MM/dd HH:mm"), $script:InvestigationState.TimeframeEnd.ToString("MM/dd HH:mm")) -ForegroundColor DarkGray
            Write-Host "  |" -ForegroundColor Cyan
            Write-Host "  +---> [1] Static File Inspection Suite" -ForegroundColor Yellow
            Write-Host "  +---> [2] Historical Log Investigation Engine" -ForegroundColor Yellow
            Write-Host "  +---> [3] Audit Downloads & Artifact Metadata" -ForegroundColor Yellow
            Write-Host "  +---> [T] Configure Investigation Timeframe Window" -ForegroundColor Cyan
            Write-Host "  |" -ForegroundColor Cyan
            Write-Host "  +---> [B] Return to Main Menu" -ForegroundColor Gray
            Write-Host "  +---> [Q] Exit Application" -ForegroundColor Red
            Write-Host ""

            $opt = Read-CustomInput "  Select NetScope Option [1-3 / T / B / Q]: "
            switch ($opt.ToUpper()) {
                "1" { Analyze-File }
                "2" { Explorative-Forensics }
                "3" { Audit-ApplicationMetadata }
                "T" { Set-InvestigationTimeframe }
                "B" { $inNetScope = $false }
                "Q" { $script:Running = $false; $inNetScope = $false }
                default { Write-Host "  [!] Invalid choice. Please select [1-3 / T / B / Q]." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        }
    }

    # ==============================================================================
    # THREAT INTEL & SUPPORT FUNCTIONS
    # ==============================================================================
    function Invoke-VirusTotalIPLookup {
        if ($script:InvestigationState.DiscoveredIPs.Count -eq 0) {
            Write-Host "`n  [-] No external public IPs currently stored in memory." -ForegroundColor Yellow
            Start-Sleep -Seconds 1.5
            return
        }

        Write-Host "`n  [*] Generated VirusTotal GUI Links for Saved Public IPs (Ctrl + Click to Open):`n" -ForegroundColor Cyan
        foreach ($ip in $script:InvestigationState.DiscoveredIPs) {
            $vtUrl = "https://www.virustotal.com/gui/ip-address/{0}" -f $ip
            Write-Host ("      • IP: {0,-16} -> " -f $ip) -NoNewline -ForegroundColor White
            Write-Host $vtUrl -ForegroundColor Yellow
        }
    }

    function Purge-MalwareThreat ($targetInput) {
        if ([string]::IsNullOrWhiteSpace($targetInput)) { return }
        $targetInput = $targetInput.Trim("'", '"')

        Write-Host "`n  +--- CONFIRM THREAT REMEDIATION OPTIONS [GLASTFIN ENGINE] ---------------------------------------+" -ForegroundColor Red
        Write-Host ("  | TARGET FILE / PROCESS : {0}" -f $targetInput) -ForegroundColor White

        Write-Host "`n  | Select Remediation Mode:" -ForegroundColor Cyan
        Write-Host "  +---> [1] Send File to RECYCLE BIN (Soft Delete)" -ForegroundColor Yellow
        Write-Host "  +---> [2] Permanent Delete ONLY (Bypass Recycle Bin)" -ForegroundColor Yellow
        Write-Host "  +---> [3] FULL PURGE (Kill Process, Permanent Delete & Wipe Persistence RegKeys)" -ForegroundColor Red
        Write-Host "  +---> [C] Cancel Operation" -ForegroundColor Gray

        $mode = Read-CustomInput "`n Select option [1 / 2 / 3 / C]: "
        if ($mode.ToUpper() -eq 'C' -or ($mode -ne '1' -and $mode -ne '2' -and $mode -ne '3')) {
            Write-Host "  [-] Threat remediation canceled." -ForegroundColor Gray
            return
        }

        $fileName = [System.IO.Path]::GetFileName($targetInput)
        $fileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($targetInput)

        Write-Host "`n  [*] Initializing Threat Removal Sequence..." -ForegroundColor Cyan

        $runningProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
            $_.Path -eq $targetInput -or $_.ProcessName -eq $fileNameNoExt -or $_.ProcessName -eq $targetInput
        }
        if ($runningProcs) {
            foreach ($proc in $runningProcs) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Write-Host ("      [+] Process Terminated: PID {0}" -f $proc.Id) -ForegroundColor Green
                } catch {}
            }
        }

        if (Test-Path $targetInput) {
            if ($mode -eq '1') {
                try {
                    Add-Type -AssemblyName Microsoft.VisualBasic
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                        $targetInput, 
                        'OnlyErrorDialogs', 
                        'SendToRecycleBin'
                    )
                    Write-Host ("      [+] File successfully sent to RECYCLE BIN: {0}" -f $targetInput) -ForegroundColor Green
                } catch {
                    Write-Host ("      [!] Error moving file to Recycle Bin: {0}" -f $_) -ForegroundColor Red
                }
            } else {
                try { 
                    Remove-Item -Path $targetInput -Force -ErrorAction Stop 
                    Write-Host ("      [+] File Permanently Deleted: {0}" -f $targetInput) -ForegroundColor Green
                } catch {
                    Write-Host ("      [!] Error deleting file: {0}" -f $_) -ForegroundColor Red
                }
            }
        } else {
            Write-Host ("      [-] File path does not exist on disk: {0}" -f $targetInput) -ForegroundColor Gray
        }

        if ($mode -eq '3') {
            Write-Host "`n  [*] Cleaning Persistence Registry Keys..." -ForegroundColor Cyan
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
                                try { 
                                    Remove-ItemProperty -Path $regPath -Name $prop.Name -Force -ErrorAction Stop 
                                    Write-Host ("      [+] Persistence Registry Key Cleared: {0}" -f $prop.Name) -ForegroundColor Green
                                } catch {}
                            }
                        }
                    }
                }
            }
        } else {
            Write-Host "      [*] Registry cleanup skipped by user selection." -ForegroundColor Yellow
        }

        Write-Host "`n  [+] Targeted threat remediation sequence completed~" -ForegroundColor Green
        Start-Sleep -Seconds 1

        [void](Show-CenteredExitBox -titleMessage "REMEDIATION COMPLETE - THREAT PURGED")
    }

    function Invoke-YaraScan ($filePath) {
        Write-Host "`n  [*] Executing Inline YARA Signature Inspection..." -ForegroundColor Cyan
        $rules = @(
            @{ Name = "Suspicious_PowerShell_Execution"; Pattern = "powershell|-enc|DownloadString|Invoke-Expression|IEX" },
            @{ Name = "Shellcode_Stager_Pattern";        Pattern = "VirtualProtect|WriteProcessMemory|CreateRemoteThread" },
            @{ Name = "CobaltStrike_Beacon_String";      Pattern = "ReflectiveLoader|meterpreter|mimikatz" },
            @{ Name = "CryptoMiner_Artifact";            Pattern = "xmrig|stratum\+tcp|monero" }
        )

        $content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
        $matched = $false

        foreach ($rule in $rules) {
            if ($content -match $rule.Pattern) {
                Write-Host ("      [!] YARA MATCH DETECTED: {0}" -f $rule.Name) -ForegroundColor Red
                $matched = $true
            }
        }
        if (-not $matched) {
            Write-Host "      [+] Zero YARA signature matches detected." -ForegroundColor Green
        }
    }

    function Invoke-VirusTotalQuery ($sha256) {
        Write-Host "`n  [*] Executing VirusTotal Intelligence Lookup..." -ForegroundColor Cyan
        if ([string]::IsNullOrWhiteSpace($script:VTKey)) {
            $script:VTKey = Read-CustomInput "  Enter VirusTotal API Key (Press ENTER to generate Web Browser link instead): "
        }

        if (-not [string]::IsNullOrWhiteSpace($script:VTKey)) {
            try {
                $headers = @{ "x-apikey" = $script:VTKey }
                $response = Invoke-RestMethod -Uri ("https://www.virustotal.com/api/v3/files/{0}" -f $sha256) -Headers $headers -Method Get -ErrorAction Stop
                $stats = $response.data.attributes.last_analysis_stats
                Write-Host ("      [+] VirusTotal Detections: Malicious {0} / Suspicious {1} / Harmless {2}" -f $stats.malicious, $stats.suspicious, $stats.harmless) -ForegroundColor Yellow
            } catch {
                Write-Host ("      [!] VirusTotal API Error: {0}" -f $_) -ForegroundColor Red
            }
        } else {
            $vtSearchUrl = "https://www.virustotal.com/gui/file/{0}/detection" -f $sha256
            Write-Host ("      [*] VirusTotal Inspection Link (Ctrl + Click to Open):`n          " + $vtSearchUrl) -ForegroundColor Yellow
        }
    }

    function Audit-ApplicationMetadata {
        $inAudit = $true
        while ($inAudit -and $script:Running) {
            Write-Host "`n  [*] Auditing Downloads & Artifacts Created During Active Timeframe Window..." -ForegroundColor Cyan
            Write-Host ("      Target Timeframe: {0} to {1}" -f $script:InvestigationState.TimeframeStart, $script:InvestigationState.TimeframeEnd) -ForegroundColor DarkGray
            Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

            if ($script:InvestigationState.AuditHistory.Count -eq 0) {
                $downloadsFolder = "$env:USERPROFILE\Downloads"
                if (Test-Path $downloadsFolder) {
                    Get-ChildItem $downloadsFolder -File -ErrorAction SilentlyContinue | Where-Object {
                        $_.CreationTime -ge $script:InvestigationState.TimeframeStart -and $_.CreationTime -le $script:InvestigationState.TimeframeEnd
                    } | ForEach-Object {
                        $filePath = $_.FullName
                        $publisher = "<MISSING METADATA>"

                        if ($_.Extension -in @(".exe", ".dll", ".sys", ".msi", ".ps1")) {
                            $verInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
                            if ($verInfo.CompanyName) { $publisher = $verInfo.CompanyName }
                        }

                        $script:InvestigationState.AuditHistory.Add([PSCustomObject]@{
                            CreatedDate = $_.CreationTime
                            Status      = if ($publisher -eq "<MISSING METADATA>") { "FLAGGED" } else { "Clean" }
                            Name        = $_.Name
                            Publisher   = $publisher
                            Path        = $filePath
                        })
                    }
                }
            }

            $sortedAudit = $script:InvestigationState.AuditHistory | Sort-Object CreatedDate -Descending
            $flaggedList = [System.Collections.Generic.List[PSObject]]::new()
            
            $idx = 1
            foreach ($item in $sortedAudit) {
                $itemObj = [PSCustomObject]@{
                    Index       = $idx
                    CreatedDate = $item.CreatedDate.ToString("yyyy-MM-dd HH:mm:ss")
                    Status      = $item.Status
                    Name        = $item.Name
                    Publisher   = $item.Publisher
                    Path        = $item.Path
                }
                $flaggedList.Add($itemObj)
                $idx++
            }

            if ($flaggedList.Count -gt 0) {
                $flaggedList | Select-Object Index, CreatedDate, Status, Name, Publisher | Format-Table -AutoSize
            } else {
                Write-Host "      [-] Zero download artifacts located for this specific date timeframe." -ForegroundColor Red
            }

            Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [S] Run Static Verification" -ForegroundColor Yellow
            Write-Host "  [L] Pivot Download to Historical Log Engine" -ForegroundColor Cyan
            Write-Host "  [K] PURGE Malware Executable" -ForegroundColor Red
            Write-Host "  [T] Adjust Investigation Timeframe Window" -ForegroundColor Cyan
            Write-Host "  [G] Export Complete Audit to GridView" -ForegroundColor Yellow
            Write-Host "  [B] Return to NetScope Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red

            $opt = Read-CustomInput "`n  Select option [S/L/K/T/G/B/Q]: "
            switch ($opt.ToUpper()) {
                "S" {
                    if ($flaggedList.Count -eq 0) {
                        Write-Host "  [!] No items available to verify." -ForegroundColor Red; Start-Sleep -Seconds 1
                    } else {
                        $numInput = Read-CustomInput ("`n  Enter item Index Number to statically verify [1-{0}]: " -f $flaggedList.Count)
                        $selectedObj = $flaggedList | Where-Object { $_.Index -eq [int]$numInput }
                        if ($selectedObj) {
                            Analyze-FileCustomPath $selectedObj.Path
                        } else {
                            Write-Host "  [!] Invalid Index Number." -ForegroundColor Red; Start-Sleep -Seconds 1
                        }
                    }
                }
                "L" {
                    if ($flaggedList.Count -eq 0) {
                        Write-Host "  [!] No items available to pivot." -ForegroundColor Red; Start-Sleep -Seconds 1
                    } else {
                        $numInput = Read-CustomInput ("`n  Enter item Index Number to pivot into Historical Logs [1-{0}]: " -f $flaggedList.Count)
                        $selectedObj = $flaggedList | Where-Object { $_.Index -eq [int]$numInput }
                        if ($selectedObj) {
                            $fileTime = [datetime]$selectedObj.CreatedDate
                            $script:InvestigationState.TimeframeStart = $fileTime.AddMinutes(-10)
                            $script:InvestigationState.TimeframeEnd   = $fileTime.AddMinutes(10)
                            $script:InvestigationState.DiscoveredAssets.Clear()
                            
                            $fileNameOnly = [System.IO.Path]::GetFileNameWithoutExtension($selectedObj.Name)
                            if (-not $script:InvestigationState.SuspiciousTargets.Contains($fileNameOnly)) {
                                [void]$script:InvestigationState.SuspiciousTargets.Add($fileNameOnly)
                            }

                            Write-Host ("`n  [+] Timeframe locked to download window: {0} to {1}" -f $script:InvestigationState.TimeframeStart, $script:InvestigationState.TimeframeEnd) -ForegroundColor Green
                            Write-Host ("  [+] Target indicator added: '{0}'" -f $fileNameOnly) -ForegroundColor Yellow
                            Start-Sleep -Seconds 1.5
                            
                            Explorative-Forensics
                        } else {
                            Write-Host "  [!] Invalid Index Number." -ForegroundColor Red; Start-Sleep -Seconds 1
                        }
                    }
                }
                "K" {
                    if ($flaggedList.Count -eq 0) {
                        Write-Host "  [!] No items available to purge." -ForegroundColor Red; Start-Sleep -Seconds 1
                    } else {
                        $numInput = Read-CustomInput ("`n  Enter item Index Number to PURGE [1-{0}]: " -f $flaggedList.Count)
                        $selectedObj = $flaggedList | Where-Object { $_.Index -eq [int]$numInput }
                        if ($selectedObj) {
                            Purge-MalwareThreat $selectedObj.Path
                            $script:InvestigationState.AuditHistory.RemoveAll({ param($x) $x.Path -eq $selectedObj.Path }) | Out-Null
                            Start-Sleep -Seconds 1
                        } else {
                            Write-Host "  [!] Invalid Index Number." -ForegroundColor Red; Start-Sleep -Seconds 1
                        }
                    }
                }
                "T" { Set-InvestigationTimeframe; $script:InvestigationState.AuditHistory.Clear() }
                "G" { $sortedAudit | Out-GridView -Title "Application Download Audit By Date" }
                "B" { $inAudit = $false }
                "Q" { $script:Running = $false; $inAudit = $false }
                default { Write-Host "  [!] Option unrecognized." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        }
    }

    function Analyze-File {
        $filePath = Read-CustomInput "  Enter target file path (or drag-and-drop file) [Press 'Q' to Return]: "
        if ($filePath.Trim().ToUpper() -eq 'Q' -or [string]::IsNullOrWhiteSpace($filePath)) {
            return
        }

        $filePath = $filePath.Trim("'", '"')
        Analyze-FileCustomPath $filePath
    }

    function Analyze-FileCustomPath ($filePath) {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Host ("  [!] Target file path does not exist: {0}" -f $filePath) -ForegroundColor Red
            Start-Sleep -Seconds 1.5
            return
        }

        Write-Host "`n  [*] Executing Static File Forensics..." -ForegroundColor Cyan
        Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

        $item = Get-Item $filePath
        Write-Host "  [-] File Name     : " -NoNewline; Write-Host $item.Name -ForegroundColor Yellow
        Write-Host "  [-] Full Path     : " -NoNewline; Write-Host $item.FullName -ForegroundColor Yellow
        Write-Host "  [-] File Size     : " -NoNewline; Write-Host ("{0} Bytes" -f $item.Length) -ForegroundColor Yellow
        Write-Host "  [-] Modification  : " -NoNewline; Write-Host $item.LastWriteTime -ForegroundColor Yellow

        $verInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath)
        $compName = if ($verInfo.CompanyName) { $verInfo.CompanyName } else { "<MISSING METADATA>" }
        Write-Host "  [-] Publisher     : " -NoNewline
        if ($compName -eq "<MISSING METADATA>") {
            Write-Host ("{0} [!] UNKNOWN / UNTRUSTED PUBLISHER" -f $compName) -ForegroundColor Red
        } else {
            Write-Host $compName -ForegroundColor Green
        }

        Write-Host "`n  [*] Generating Cryptographic Hashes..." -ForegroundColor Cyan
        $md5    = (Get-FileHash $filePath -Algorithm MD5).Hash
        $sha256 = (Get-FileHash $filePath -Algorithm SHA256).Hash
        Write-Host "  [-] MD5           : " -NoNewline; Write-Host $md5 -ForegroundColor White
        Write-Host "  [-] SHA256        : " -NoNewline; Write-Host $sha256 -ForegroundColor White

        Write-Host "`n  [*] Extracting Printable ASCII Strings..." -ForegroundColor Cyan
        Get-Content $filePath -Encoding Byte -ReadCount 0 -ErrorAction SilentlyContinue |
            ForEach-Object { [System.Text.Encoding]::ASCII.GetString($_) } |
            Select-String -Pattern "[\w\s]{6,}" -AllMatches |
            Select-Object -ExpandProperty Matches |
            Select-Object -First 10 -ExpandProperty Value |
            ForEach-Object { Write-Host ("      > {0}" -f $_) -ForegroundColor DarkGray }

        Invoke-YaraScan $filePath
        Invoke-VirusTotalQuery $sha256

        Write-Host "`n  [+] Static analysis complete~" -ForegroundColor Green

        if (-not $script:InvestigationState.SuspiciousTargets.Contains($item.Name)) {
            $script:InvestigationState.SuspiciousTargets.Add($item.Name)
        }

        $inStaticMenu = $true
        while ($inStaticMenu -and $script:Running) {
            Write-Host "`n  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkMagenta
            Write-Host "  EXTENDED THREAT CONFIRMATION OPTIONS:" -ForegroundColor Cyan
            Write-Host ("  [1] Pivot to Historical Log Investigation Engine with '{0}'" -f $item.Name) -ForegroundColor Yellow
            Write-Host "  [K] PURGE & REMEDIATE" -ForegroundColor Red
            Write-Host "  [B] Return to NetScope Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red

            $opt = Read-CustomInput "`n  Select an option [1 / K / B / Q]: "
            switch ($opt.ToUpper()) {
                "1" { Explorative-Forensics; $inStaticMenu = $false }
                "K" { Purge-MalwareThreat $filePath; $inStaticMenu = $false }
                "B" { $inStaticMenu = $false }
                "Q" { $script:Running = $false; $inStaticMenu = $false }
                default { Write-Host "  [!] Unrecognized input." -ForegroundColor Yellow }
            }
        }
    }

    function Explorative-Forensics {
        $continuePivoting = $true
        while ($continuePivoting -and $script:Running) {
            $StartTime = $script:InvestigationState.TimeframeStart
            $EndTime   = $script:InvestigationState.TimeframeEnd

            Write-Host ("`n  [*] INVESTIGATION TIMEFRAME : {0} TO {1}" -f $StartTime, $EndTime) -ForegroundColor Cyan
            Write-Host ("  [*] ACTIVE INDICATORS       : {0}" -f $(if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { $script:InvestigationState.SuspiciousTargets -join ', ' } else { 'Blind Scan Mode (Unfiltered Search)' })) -ForegroundColor Yellow
            Write-Host ("  [*] IGNORED CATEGORIES      : {0}" -f $(if ($script:InvestigationState.IgnoredCategories.Count -gt 0) { $script:InvestigationState.IgnoredCategories -join ', ' } else { 'None (Display All Categories)' })) -ForegroundColor DarkYellow
            Write-Host ("  [*] OPERATOR to {0}         ::  [ Glory to Mankind ]" -f $script:HostIdentifier) -ForegroundColor Green
            Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

            if ($script:InvestigationState.DiscoveredAssets.Count -eq 0) {
                Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-PowerShell/Operational'; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | 
                    ForEach-Object {
                        if ($script:InvestigationState.DiscoveredAssets.Count -ge 5000) { return }
                        $rawPayload = ""
                        if ($_.Properties) { $rawPayload = ($_.Properties.Value -join " ") }
                        $fullText = "{0} {1}" -f $_.Message, $rawPayload

                        $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                            Time     = $_.TimeCreated
                            Category = "PowerShell Execution"
                            Log      = "PowerShell Operational"
                            Detail   = $fullText
                        })
                    }

                Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=@(4624, 4625, 4688); StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($script:InvestigationState.DiscoveredAssets.Count -ge 5000) { return }
                    $rawPayload = ""
                    if ($_.Properties) { $rawPayload = ($_.Properties.Value -join " ") }
                    $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                        Time     = $_.TimeCreated
                        Category = ("Security Event ID {0}" -f $_.Id)
                        Log      = "Security"
                        Detail   = ("{0} {1}" -f $_.Message, $rawPayload)
                    })
                }

                Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($script:InvestigationState.DiscoveredAssets.Count -ge 5000) { return }
                    $script:InvestigationState.DiscoveredAssets.Add([PSCustomObject]@{
                        Time     = $_.TimeCreated
                        Category = "Defender Alert"
                        Log      = "Defender"
                        Detail   = $_.Message
                    })
                }
            }

            $displayEvents = $script:InvestigationState.DiscoveredAssets

            # Apply Target Indicators Filter
            if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                $displayEvents = $displayEvents | Where-Object {
                    $item = $_
                    $matched = $false
                    foreach ($target in $script:InvestigationState.SuspiciousTargets) {
                        if ([string]::IsNullOrWhiteSpace($target)) { continue }
                        $cleanTarget = [regex]::Escape($target.Trim())
                        if ($item.Detail -match $cleanTarget -or $item.Category -match $cleanTarget) { 
                            $matched = $true 
                            break 
                        }
                    }
                    return $matched
                }
            }

            # Apply Ignored Categories Filter across Category, Log Name, and Details
            if ($script:InvestigationState.IgnoredCategories.Count -gt 0) {
                $displayEvents = $displayEvents | Where-Object {
                    $item = $_
                    $shouldIgnore = $false
                    foreach ($ignoreTerm in $script:InvestigationState.IgnoredCategories) {
                        if ([string]::IsNullOrWhiteSpace($ignoreTerm)) { continue }
                        $cleanTerm = [regex]::Escape($ignoreTerm.Trim())
                        if ($item.Category -match $cleanTerm -or $item.Log -match $cleanTerm -or $item.Detail -match $cleanTerm) {
                            $shouldIgnore = $true
                            break
                        }
                    }
                    return (-not $shouldIgnore)
                }
            }

            $totalCount = $displayEvents.Count
            Write-Host ("`n  [+] Retained {0} event record(s) in session memory after filters." -f $totalCount) -ForegroundColor Green
            if ($totalCount -gt 0) {
                Write-Host "  [*] Displaying LATEST 10 RECORDS on-screen:`n" -ForegroundColor Cyan
                $displayEvents | Sort-Object Time -Descending | Select-Object -First 10 @{N='Date'; E={$_.Time.ToString('yyyy-MM-dd HH:mm:ss')}}, Category, Log, Detail | Format-Table -AutoSize
            } else {
                Write-Host "  [-] Zero logs matched your active indicators and category filters.`n" -ForegroundColor DarkGray
            }

            Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [A] Add (+) or Remove (-) Target Indicator (e.g. 'meterpreter', '-meterpreter', '-*')" -ForegroundColor Yellow
            Write-Host "  [F] Filter / Ignore Log Categories (e.g. 'PowerShell', 'Security', '-*' to reset)" -ForegroundColor Yellow
            
            if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) {
                Write-Host "  [M] Audit Download Metadata" -ForegroundColor Yellow
                Write-Host "  [S] Static File Inspection Suite" -ForegroundColor Yellow
                Write-Host "  [K] PURGE MALWARE" -ForegroundColor Red
            }

            Write-Host "  [T] Adjust Investigation Timeframe Window" -ForegroundColor Cyan
            Write-Host "  [G] Export Filtered Results to GridView" -ForegroundColor Yellow
            Write-Host "  [B] Return to NetScope Menu" -ForegroundColor Gray
            Write-Host "  [Q] Exit Application" -ForegroundColor Red
            
            $promptOptions = if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { "A/F/M/S/K/T/G/B/Q" } else { "A/F/T/G/B/Q" }
            $choice = Read-CustomInput ("`n  Select action [{0}]: " -f $promptOptions)
            
            switch ($choice.ToUpper()) {
                "A" {
                    $inputTerm = Read-CustomInput "  Enter target indicator to ADD, REMOVE (-term), or CLEAR ALL (-*): "
                    if (-not [string]::IsNullOrWhiteSpace($inputTerm)) {
                        $rawInput = $inputTerm.Trim()

                        if ($rawInput -eq "-*" -or $rawInput.ToLower() -eq "-all") {
                            $script:InvestigationState.SuspiciousTargets.Clear()
                            Write-Host "  [+] Cleared all target indicators." -ForegroundColor Green
                        }
                        elseif ($rawInput.StartsWith("-")) {
                            $termToRemove = $rawInput.TrimStart("-").Trim()
                            [void]$script:InvestigationState.SuspiciousTargets.Remove($termToRemove)
                            Write-Host ("  [+] Removed target indicator '{0}'." -f $termToRemove) -ForegroundColor Green
                        } 
                        else {
                            if (-not $script:InvestigationState.SuspiciousTargets.Contains($rawInput)) {
                                $script:InvestigationState.SuspiciousTargets.Add($rawInput)
                                Write-Host ("  [+] Added target indicator '{0}'." -f $rawInput) -ForegroundColor Green
                            }
                        }
                        Start-Sleep -Seconds 1
                    }
                }
                "F" {
                    $catInput = Read-CustomInput "  Enter category or log term to IGNORE (e.g. 'PowerShell'), REMOVE (-term), or RESET ALL (-*): "
                    if ([string]::IsNullOrWhiteSpace($catInput) -or $catInput.Trim() -eq "-*") {
                        $script:InvestigationState.IgnoredCategories.Clear()
                        Write-Host "  [+] Cleared category exclusions. Displaying all log sources." -ForegroundColor Green
                    }
                    elseif ($catInput.Trim().StartsWith("-")) {
                        $catToRemove = $catInput.Trim().TrimStart("-").Trim()
                        [void]$script:InvestigationState.IgnoredCategories.Remove($catToRemove)
                        Write-Host ("  [+] Removed category exclusion '{0}'." -f $catToRemove) -ForegroundColor Green
                    }
                    else {
                        $cleanCat = $catInput.Trim()
                        if (-not $script:InvestigationState.IgnoredCategories.Contains($cleanCat)) {
                            $script:InvestigationState.IgnoredCategories.Add($cleanCat)
                            Write-Host ("  [+] Ignoring log category '{0}'." -f $cleanCat) -ForegroundColor Green
                        }
                    }
                    Start-Sleep -Seconds 1
                }
                "M" { Audit-ApplicationMetadata }
                "S" {
                    $confirmPath = Read-CustomInput "  Enter file path to inspect statically: "
                    if (-not [string]::IsNullOrWhiteSpace($confirmPath)) {
                        Analyze-FileCustomPath $confirmPath.Trim("'", '"')
                    }
                }
                "K" {
                    $purgePath = Read-CustomInput "  Enter file path or process name to purge: "
                    if (-not [string]::IsNullOrWhiteSpace($purgePath)) {
                        Purge-MalwareThreat $purgePath
                        Start-Sleep -Seconds 1
                    }
                }
                "T" { Set-InvestigationTimeframe; $script:InvestigationState.DiscoveredAssets.Clear() }
                "G" { $displayEvents | Sort-Object Time -Descending | Out-GridView -Title "Forensicology | Filtered Event Log Records" }
                "B" { $continuePivoting = $false }
                "Q" { $script:Running = $false; $continuePivoting = $false }
                default { Write-Host "  [!] Choice unrecognized. Select from options listed above." -ForegroundColor Red; Start-Sleep -Seconds 1 }
            }
        }
    }

    function Show-NativeResourceMonitor {
        Write-Host "`n  +--- FORENSICOLOGY | Native System Resource Monitor --------------------------------------------+" -ForegroundColor Green
        Write-Host "  |" -ForegroundColor Green

        $os = Get-CimInstance Win32_OperatingSystem
        $totalRamMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
        $usedRamMB  = $totalRamMB - [math]::Round($os.FreePhysicalMemory / 1024, 0)
        $cpuLoad    = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

        Write-Host ("  +---> CPU Load: {0}% | RAM Usage: {1} MB / {2} MB" -f $cpuLoad, $usedRamMB, $totalRamMB) -ForegroundColor Cyan
        Write-Host "  +-------------------------------------------------------------------------------------------------+" -ForegroundColor Green
        Write-Host ""
        Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 8 Id, ProcessName, @{N='RAM(MB)';E={[math]::Round($_.WorkingSet64/1MB,1)}}, CPU | Format-Table -AutoSize

        $key = Read-CustomInput "  Press Enter to return (or 'Q' to Exit): "
        if ($key -eq 'q' -or $key -eq 'Q') { $script:Running = $false }
    }

    # ==============================================================================
    # MAIN MENU CONTROLLER
    # ==============================================================================
    function Show-MainMenu {
        Show-Header -catMood "home"
        Write-Host "  +--- MAIN MODULE SELECTION ---------------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |" -ForegroundColor Cyan
        Write-Host "  +---> [1] ConScopy" -ForegroundColor Yellow
        Write-Host "  +---> [2] NetScopy" -ForegroundColor Yellow
        Write-Host "  +---> [3] Native Resource Monitor" -ForegroundColor Yellow
        Write-Host "  +---> [R] Reset / Clear In-Memory Investigation State" -ForegroundColor DarkYellow
        Write-Host "  |" -ForegroundColor Cyan
        Write-Host "  +---> [4 / Q] Terminate Session and Self-Clean" -ForegroundColor Red
        Write-Host "  -------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        
        if ($script:InvestigationState.DiscoveredAssets.Count -gt 0 -or $script:InvestigationState.SuspiciousTargets.Count -gt 0 -or $script:InvestigationState.DiscoveredIPs.Count -gt 0 -or $script:InvestigationState.IgnoredCategories.Count -gt 0) {
            Write-Host "  +--- ACTIVE INVESTIGATION STATE --------------------------------------------+" -ForegroundColor DarkMagenta
            Write-Host ("  |  * Tracked Indicators : {0}" -f $(if ($script:InvestigationState.SuspiciousTargets.Count -gt 0) { $script:InvestigationState.SuspiciousTargets -join ', ' } else { 'None (Blind Scan Mode)' })) -ForegroundColor Yellow
            Write-Host ("  |  * Ignored Categories : {0}" -f $(if ($script:InvestigationState.IgnoredCategories.Count -gt 0) { $script:InvestigationState.IgnoredCategories -join ', ' } else { 'None' })) -ForegroundColor DarkYellow
            Write-Host ("  |  * Tracked Public IPs : {0} Address(es) in memory" -f $script:InvestigationState.DiscoveredIPs.Count) -ForegroundColor Cyan
            Write-Host ("  |  * Active Time Window : {0} to {1}" -f $script:InvestigationState.TimeframeStart, $script:InvestigationState.TimeframeEnd) -ForegroundColor White
            Write-Host ("  |  * Retained Log Events: {0}" -f $script:InvestigationState.DiscoveredAssets.Count) -ForegroundColor Cyan
            Write-Host ("  |  * Retained Audit File: {0}" -f $script:InvestigationState.AuditHistory.Count) -ForegroundColor Cyan
            Write-Host "  +-------------------------------------------------------------------------------------------------+" -ForegroundColor DarkMagenta
            Write-Host ""
        }
    }

    # Main Framework Loop
    while ($script:Running) {
        Show-MainMenu
        $selection = Read-CustomInput "  Select option [1-4 / R / Q]: "
        switch ($selection.ToUpper()) {
            "1" { Show-ConScopeMenu }
            "2" { Show-NetScopeMenu }
            "3" { Show-NativeResourceMonitor }
            "R" { Clear-SessionMemoryState }
            "4" { $script:Running = $false }
            "Q" { $script:Running = $false }
            default { Write-Host "  [!] Invalid menu option. Enter 1, 2, 3, R, 4 or Q." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }

    # Centered Exit Overlay
    if (-not $script:Running) {
        $confirmExit = Show-CenteredExitBox -titleMessage "SESSION TERMINATION AND PURGE ENGINE"
        if (-not $confirmExit) {
            $script:Running = $true
            while ($script:Running) {
                Show-MainMenu
                $selection = Read-CustomInput "  Select option [1-4 / R / Q]: "
                switch ($selection.ToUpper()) {
                    "1" { Show-ConScopeMenu }
                    "2" { Show-NetScopeMenu }
                    "3" { Show-NativeResourceMonitor }
                    "R" { Clear-SessionMemoryState }
                    "4" { $script:Running = $false }
                    "Q" { $script:Running = $false }
                    default { Write-Host "  [!] Invalid menu option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
                }
            }
        }
    }
}
finally {
    [Console]::remove_CancelKeyPress($cancelHandler)
    $script:VTKey = $null
    $script:InvestigationState = $null
    if ($host.Name -eq "ConsoleHost") {
        $host.UI.RawUI.WindowTitle = $script:OriginalTitle
    }
    Exit-ForensicsEngine
}
