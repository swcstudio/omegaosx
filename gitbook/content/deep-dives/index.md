# OmegaOS W3.x Documentation Index

## Project Overview
OmegaOS W3.x: Web3 AR Kernel (Web3 OS Kernel). Focus: Secure, modular kernel for decentralized AR protocols (WEB3.ARL). GitHub: swcstudio/omegaosx; License: AGL 3.0; Owners: Spectrum Web Co LLC / Omega Labs Pty Ltd / Oveshen Govender. Docs at gitbook.com/docs.

## Generated Documentation
- [Project Overview](./project-overview.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Architecture](./architecture.md)
- [Development Guide](./development-guide.md)

## Deep-Dive Documentation
Detailed exhaustive analysis of specific areas:

- [kernel/comps Deep-Dive](./deep-dive-comps.md) - Modular components/drivers (153 files, ~10000 LOC) - Generated 2025-11-12
- [kernel/src/device Deep-Dive](./deep-dive-device.md) - Device management for modular hardware (18 files, 2487 LOC) - Generated 2025-11-12
- [kernel/src/fs Deep-Dive](./deep-dive-fs.md) - VFS and FS implementations (126 files, ~15000 LOC) - Generated 2025-11-12
- [kernel/src/ipc Deep-Dive](./deep-dive-ipc.md) - IPC for secure AR comms (6 files, ~800 LOC) - Generated 2025-11-12
- [kernel/src/net Deep-Dive](./deep-dive-net.md) - Network stack for WEB3.ARL sockets (97 files, ~5000 LOC) - Generated 2025-11-12
- [kernel/src/process Deep-Dive](./deep-dive-process.md) - Process management for AR tasks (68 files, ~8000 LOC) - Generated 2025-11-12
- [kernel/src/sched Deep-Dive](./deep-dive-sched.md) - Scheduler for low-latency AR tasks (12 files, ~1200 LOC) - Generated 2025-11-12
- [kernel/src/vm Deep-Dive](./deep-dive-vm.md) - VM for AR virtualization (10 files, ~1500 LOC) - Generated 2025-11-12

## Getting Started
1. Clone: git clone https://github.com/swcstudio/omegaosx
2. Build: make build
3. Run: make run (QEMU)
4. For Framework: Extend device/ for hot-plug modules.

Last Updated: 2025-11-12  
Deep-Dives: 8  
Total Docs: 20