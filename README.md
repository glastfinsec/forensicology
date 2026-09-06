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

* **Static File Inspection Suite:** Evaluate file metadata, compute cryptographic hashes (MD5, SHA256), inspect printable ASCII strings, run inline YARA signature checks, and query VirusTotal (via API key or public aggregator fallback).
* **Historical Log Investigation Engine:** Scan Windows Event Logs (Application, PowerShell Operational, Security, Defender) dynamically using fuzzy time windows (`today`, `last week`, `3 hours ago`) and pivot on suspicious indicators.
* **Native Resource Monitor:** Track real-time CPU load and RAM usage with automated performance warning triggers and process consumers listing.
* **Targeted Threat Purge & Remediation:** Kill malicious processes, delete correlated payloads from disk, clear out downloads artifacts, and clean dangerous startup registry keys with integrated progress bars.

---

## 🎛️ Interactive TUI Menu Structure

```text
[1] Static File Inspection Suite (Metadata, Hashes, YARA, VirusTotal)
[2] Historical Log Investigation Engine (Blind Scan -> Add Indicator)
[3] Native Resource Monitor (System Performance & Process Warning Alert)
[4 / Q] Terminate Session & Self-Clean
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



