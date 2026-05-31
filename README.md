<div align="center">

<img src="icon.png" width="128" alt="Moni icon" />

# Moni

**A tiny, native menu-bar system monitor for Apple Silicon Macs.**

Live CPU load, RAM usage, CPU temperature, and network / disk throughput —
in a clean menu-bar popover that uses **~0% CPU when closed**.

<br/>

<img src="picture/screenshot.png" width="320" alt="Moni popover" />

</div>

---

## Features

- 🧊 **CPU** load, **RAM** usage, and **CPU temperature** as clean ring gauges
- 🌡️ Real on-die temperature on Apple Silicon (no `sudo`, no kext)
- 🌐 Live **network** (↓/↑) and **disk** (read/write) throughput
- 👆 **Drill-down by click** — tap a ring to redraw the popover into a detail screen:
  - **CPU / RAM**: a live history graph + **top processes** by that resource
  - **Disk**: **free space per volume** + read/write activity
  - **Temperature**: a history graph
- 📈 **Load history** — CPU & RAM are recorded in the background (~5 s) so the
  graphs are meaningful the moment you open them
- 🔍 **Open Activity Monitor** in one click for deep/hidden inspection
- 🪶 **Featherweight**: ~0% CPU when the popover is closed
- 🚀 **Launch at login** toggle (via `SMAppService`)
- 🔒 100% local — no network access, no telemetry, no elevated privileges
- 🖥️ Lives in the menu bar only (no Dock icon)

> Per-process stats are read unprivileged via `libproc`, so the top lists show
> mainly your own processes; the **Open Activity Monitor** button covers
> root/system processes.

## Requirements

- **Apple Silicon** Mac (M1 or newer)
- **macOS 14 Sonoma** or later

## Install

1. Download the DMG:
   - from the [**Releases**](../../releases) page, **or**
   - directly: [**installation/Moni-2.0.dmg**](installation/Moni-2.0.dmg) (click, then **Download**).
2. Open the DMG and drag **Moni** into **Applications**.
3. Launch it. Because the app is **ad-hoc signed** (no paid Developer ID),
   macOS Gatekeeper will warn on first launch:
   - Right-click **Moni.app → Open**, then confirm, **or**
   - **System Settings → Privacy & Security → Open Anyway**.

You only need to do this once. The Moni icon then appears in your menu bar —
click it for the stats popover.

## Build from source

You need **Xcode 16+** (Swift 6) command-line tools.

```bash
git clone https://github.com/BadmintonAdmin/moni.git
cd moni

# Build and install into /Applications:
./build.sh

# …or build a distributable DMG (into dist/):
./make-dmg.sh
```

## How it works

Metrics come from cheap system interfaces. The live rings sample every ~1.5 s
**only while the popover is open**; CPU/RAM history is sampled every ~5 s in the
background:

| Metric          | Source |
|-----------------|--------|
| CPU load        | `host_processor_info` tick counters (delta between samples) |
| RAM             | `host_statistics64` (VM stats) + `hw.memsize` |
| CPU temp        | Private `IOHIDEventSystemClient` thermal sensors (averaged across the CPU/SoC die) — same approach as Stats/btop, no root required |
| Network         | `getifaddrs` interface byte counters |
| Disk I/O        | IOKit `IOBlockStorageDriver` statistics |
| Disk free space | `URL` volume resource values (`mountedVolumeURLs`) |
| Per-process     | `libproc` (`proc_listallpids` + `proc_pidinfo`), CPU% via time deltas |
| Thermal state   | `ProcessInfo.thermalState` |

> **Note on temperature:** Apple provides no public API for on-die temperatures,
> so Moni reads them via a private (but unprivileged) IOKit interface. If your
> chip exposes no usable sensor, the temperature ring shows `—`.

## Project layout

```
Sources/
  CIOHID/        C shim exposing the private IOHID symbols
  Moni/
    MoniApp.swift          @main, MenuBarExtra
    StatsPanel.swift       popover root + overview + lightweight navigation
    Views/                 metric / process / disk detail screens
    Components/            ring gauge, chart, rows, badges, theme, hover
    Metrics/               CPU / Memory / Temp / IO / Process / Disk samplers + model
    LoginItem.swift        SMAppService wrapper
scripts/build-app.sh       builds Moni.app (used by both scripts below)
build.sh                   build + install to /Applications
make-dmg.sh                build + package a DMG
```

## License

[MIT](LICENSE)
