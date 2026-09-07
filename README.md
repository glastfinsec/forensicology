> [!WARNING]
> 🚧 **TRAILER / UNDER ACTIVE DEVELOPMENT** 🚧  
> *Forensicology is currently a work-in-progress project by **glastfin**. Features, syntax, and behaviors are subject to change as development evolves.*

---

# Forensicology
> **Monolithic In-Memory Windows Incident Response & Remediation Suite**  
> *Made by **glastfin***

![Forensicology Banner](https://img.shields.io/badge/Platform-Windows-blue) ![PowerShell](https://img.shields.io/badge/Language-PowerShell-yellow) ![Status-ActiveDevelopment](https://img.shields.io/badge/Status-Under%20Development-orange) ![License](https://img.shields.io/badge/License-MIT-green)

---

## 👁️ The Vision & Motive

Operating systems lock away a wealth of forensic artifacts behind layers of abstraction, heavy enterprise licensing, and bloated software agents. **Forensicology** exists to pull back the curtain. 

Conceived as a monolithic, in-memory execution suite, its core purpose is twofold:
1. **Unlocking Windows Transparency:** To demonstrate how much vital telemetry and forensic data is hidden right beneath our noses within Windows systems.
2. **Zero-Friction Education & Execution:** To provide security practitioners and newcomers alike with a fast, accessible taste of digital forensics and threat hunting—without leaving persistent footprints on disk or requiring heavy installations.

---


## 🛠️ Core Capabilities
Here is a quick breakdown of what each tool does and how it works under the hood in plain, beginner-friendly terms:

| Capability | What It Does  | How It Works |
| :--- | :--- | :--- |
| **Static File Inspection** | Checks if a suspicious file is safe by reading its inner traits and scanning it. | Reads file metadata, computes MD5/SHA256 digital hashes, extracts printable strings, runs pattern-matching checks, and queries VirusTotal. |
| **Historical Log Engine** | Searches past Windows activity logs to find when and how something happened. | Queries Windows Event Logs (PowerShell, Security, Defender) using fuzzy timeframes (`last month`, `last year`, `24 hours`) and filters results by keywords. |
| **Native Resource Monitor** | Shows your live CPU and RAM usage along with the heaviest background apps. | Queries system performance metrics via CIM/WMI (`Win32_OperatingSystem`, `Win32_Processor`) and lists active processes sorted by memory usage. |
| **Threat Purge & Remediation** | Safely stops malicious background tasks, deletes bad files, and cleans startup keys. | Terminates running process IDs, sends files to the Recycle Bin or wipes them permanently, and clears related persistence keys from the Windows Registry. |

---

## ⚙️ How It Works & Usage Guide

Forensicology is designed around two primary investigative pillars: **ConScopy** (for live network reconnaissance) and **NetScopy** (for deep historical and file forensics). 

### 1. ConScopy (Live Network, Sockets & Ports)
_Laproscopy of Connections_
* **What it checks:** Active network traffic, remote IP connections, listening ports, ARP tables, and routing configurations.
* **How to use it:**
  1. From the **Main Menu**, select option `[1]` for **ConScopy**.
  2. Choose **[1] Active Socket Correlation Scan** to capture all established network connections.
  3. The tool automatically performs quick reverse DNS lookups on external connections and flags public IP addresses into memory.
  4. From the post-scan menu, select **[1]** to generate instant **VirusTotal browser links** for any suspicious external IPs found, or pivot straight into log/file analysis.

### 2. NetScopy (Deep Forensics & Historical Logs)
_Laproscopy of Network_
* **What it checks:** Static files, historical Windows event logs, and download folder artifacts.
* **How to use it:**
  1. From the **Main Menu**, select option `[2]` for **NetScopy**.
  2. **Set your Timeframe Window:** Press `[T]` to define how far back you want to look. You can use precise hours/days or fuzzy filters like `"last month"`, `"last year"`, or `24 hours`.
  3. **Scan Historical Logs (`[2]`):** Queries PowerShell operational logs, Windows Security events, and Windows Defender alerts. You can type indicators (like `meterpreter`) to filter out noise instantly.
  4. **Audit Downloads (`[3]`):** Scans your `Downloads` folder for files created during your selected timeframe, checks their digital publishers, and lets you pivot right into a file's history or wipe it safely.

---

---

## 🎛️ Interactive TUI Menu Structure

```text
[1] ConScopy (Live Connections, Sockets & Ports)
[2] NetScopy (Deep Forensics, Static Analysis & Historical Logs)
[3] Native Resource Monitor (System Performance & Process Check)
[R] Reset / Clear In-Memory Investigation State
[Q] Terminate Session and Self-Clean
```

## 🚀 Quick Execution

Run Forensicology instantly straight from your terminal without cloning or downloading bulky packages by executing this one-liner in an elevated PowerShell prompt:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/glastfinsec/forensicology/main/forensicology.ps1 | iex"
```
## 🔒 Security & Session Hygiene
Forensicology operates entirely within memory. Upon exit or termination:

The active PowerShell session state vector and API tokens are completely purged.

The original console window title and system states are safely restored.

Zero persistent artifacts are intentionally left behind on the host disk.

## 🛡️ Disclaimer
Forensicology is built for educational, defensive security, and authorized incident response operations only. Always ensure you have explicit permission before running forensic or remediation routines on any host.



