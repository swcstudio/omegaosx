# Architecture

## Executive Summary

OmegaOS W3.x employs a framekernel architecture to provide a secure, modular OS kernel in Rust with Linux-compatible ABI. The design minimizes unsafe code through a minimal Trusted Computing Base (TCB) and componentized modules, supporting x86_64, RISC-V, and LoongArch architectures. This structure enhances memory safety while maintaining developer-friendliness via OSXDK and OSXTD tools. Verified versions: Rust 1.81.0 (stable 2025), Cargo OSXDK 0.17.0 (latest 2025).

No new project initialization is required as this is a brownfield enhancement of the existing kernel codebase.

## Decision Summary

| Category | Decision | Version | Affects Epics | Rationale |
| -------- | -------- | ------- | ------------- | --------- |
| Language | Rust with no_std | 1.81.0 (stable 2025) | All | Memory safety without GC, suitable for kernel development |
| Architecture | Framekernel | Custom (v1.0, 2025) | All | Minimizes TCB, enables modular components |
| ABI | Linux-compatible | Partial (220+ syscalls, 2025) | Epic 2,4,5 | Enables seamless application porting |
| Build System | Cargo with OSXDK | 0.17.0 (latest 2025) | Epic 9 | Simplifies no_std builds and testing |
| Memory Management | Frame allocator + VM | Custom (CortenMM v1.0, 2025) | Epic 3 | Secure and efficient page management |
| Scheduling | Multi-core CFS-like | Custom (v1.0, 2025) | Epic 7 | Fair resource allocation on SMP |
| File System | VFS + ramfs/ext2 | Custom (v1.0, 2025) | Epic 4 | Linux-compatible FS operations |
| Networking | Custom stack with omega-bigtcp | Custom (v1.0, 2025) | Epic 5 | Supports WEB3.ARL protocols |
| Security | Capability-based (omega-rights) + TDX | Custom (v1.0, 2025) | Epic 8 | Least-privilege and confidential computing |
| Testing | Unit + ktest + AUTO_TEST | Custom (v1.0, 2025) | Epic 9 | Ensures reliability across components |
| Multi-Arch | x86_64, riscv64imac, loongarch64 | Supported (v1.0, 2025) | Epic 10 | Broad hardware compatibility |
| Graphics | VirtIO-GPU + framebuffer integration | Custom (v1.0, 2025) | Epic 6 | Paravirtualized GPU for WEB3.ARL AR rendering with omega-rights isolation |
| Documentation | mdBook + GitBook sync | Custom (v1.0, 2025) | Epic 9 | Interactive search/collaboration for kernel guides |

## Project Structure

```
/home/ubuntu/src/repos/omegaosx/
├── Cargo.toml                 # Workspace root
├── Makefile                   # Build and run scripts
├── kernel/                    # Core kernel source
│   ├── Cargo.toml
│   ├── comps/                 # Modular components
│   │   ├── block/             # Block device drivers
│   │   ├── console/           # Console output
│   │   ├── framebuffer/       # Graphics output
│   │   ├── input/             # Input devices
│   │   ├── keyboard/          # Keyboard handling
│   │   ├── logger/            # Logging system
│   │   ├── mlsdisk/           # Secure disk
│   │   ├── network/           # Network stack
│   │   ├── pci/               # PCI bus
│   │   ├── softirq/           # Soft interrupts
│   │   ├── systree/           # System tree
│   │   ├── time/              # Timekeeping
│   │   ├── virtio/            # Virtio drivers
│   │   └── virtio-gpu/        # VirtIO GPU for AR rendering
│   ├── libs/                  # Kernel libraries
│   │   ├── atomic-integer-wrapper/
│   │   ├── comp-sys/          # Component system
│   │   ├── cpio-decoder/      # Initramfs decoder
│   │   ├── int-to-c-enum/
│   │   ├── jhash/
│   │   ├── keyable-arc/
│   │   ├── logo-ascii-art/
│   │   ├── omega-bigtcp/      # BigTCP for WEB3
│   │   ├── omega-rights/      # Rights management
│   │   ├── omega-rights-proc/
│   │   ├── omega-util/
│   │   ├── typeflags/
│   │   ├── typeflags-util/
│   │   └── xarray/
│   └── src/                   # Kernel modules
│       ├── context.rs         # Context switching
│       ├── cpu.rs             # CPU management
│       ├── error.rs           # Error handling
│       ├── init.rs            # Initialization
│       ├── kcmdline.rs        # Kernel command line
│       ├── lib.rs             # Kernel entry
│       ├── prelude.rs         # Common prelude
│       ├── vdso.rs            # VDSO
│       ├── arch/              # Architecture-specific
│       ├── device/            # Device management
│       ├── driver/            # Drivers
│       ├── events/            # Event handling
│       ├── fs/                # File systems
│       ├── ipc/               # IPC
│       ├── net/               # Networking
│       ├── process/           # Process management
│       ├── sched/             # Scheduling
│       ├── security/          # Security
│       ├── syscall/           # Syscalls
│       ├── thread/            # Threads
│       ├── time/              # Time
│       ├── util/              # Utilities
│       └── vm/                # Virtual memory
├── osxdk/                     # OS Development Kit
│   ├── Cargo.toml
│   ├── src/                   # OSXDK source
│   ├── deps/                  # Dependencies
│   └── tools/                 # Tools
├── osxtd/                     # OS Standard Library
│   ├── Cargo.toml
│   ├── libs/                  # Libraries
│   └── src/                   # Source
├── book/                      # Documentation
├── docs/                      # Additional docs
├── test/                      # Tests
└── tools/                     # Build tools
```

## Epic to Architecture Mapping

| Epic | Description | Mapped Components |
|------|-------------|-------------------|
| 1: Core Kernel and Boot | Boot and initialization | kernel/src/init.rs, arch/, Makefile |
| 2: Process and Thread Management | Process lifecycle | kernel/src/process/, thread/, syscall/ |
| 3: Virtual Memory | Memory management | kernel/src/vm/, libs/heap-allocator/ |
| 4: File System | VFS and FS impl | kernel/src/fs/, comps/block/ |
| 5: Networking Stack | Sockets and net | kernel/src/net/, comps/network/, libs/omega-bigtcp/ |
| 6: Device Drivers and Components | Hardware drivers | comps/ (pci, virtio-gpu, console, etc.), device/, driver/ |
| 7: Scheduler and Time | Scheduling and time | kernel/src/sched/, time/, comps/time/ |
| 8: IPC and Security | IPC and security | kernel/src/ipc/, security/, libs/omega-rights/ |
| 9: Testing and Build Tools | Tests and OSXDK | test/, osxdk/, Makefile |
| 10: Multi-Architecture and Optimizations | Multi-arch support | arch/ (x86_64, riscv, loongarch), build flags |
| 11: Native WEB3/ARL Integration | WEB3/ARL features | net/omega-bigtcp, ipc/shm for AR tasks |

## Technology Stack Details

### Core Technologies

- **Language**: Rust 1.81.0 (stable 2025), no_std environment
- **Build Tool**: Cargo with custom OSXDK 0.17.0 (latest 2025)
- **Simulator**: QEMU with KVM acceleration (VirtIO-GPU support)
- **Dependencies**: spin=0.9.4, bitflags=1.3, intrusive-collections=0.9.6, x86_64=0.14.13, riscv=0.11.1, etc. (see Cargo.toml)
- **Documentation**: mdBook for local, GitBook for hosted interactive docs
- **License**: AGPL-3.0

### Integration Points

- **Components**: Loaded via comps/ framework (comp-sys/)
- **Syscalls**: Handled in syscall/ with Linux ABI mapping
- **Drivers**: PCI enumeration in comps/pci/, virtio in comps/virtio/
- **Networking**: Sockets via net/, drivers via comps/network/
- **Memory**: Frame allocation shared across VM and processes

No novel pattern designs required; all patterns follow established OS kernel practices adapted for Rust.

## Implementation Patterns

These patterns ensure consistent implementation across all AI agents:

- **Module Organization**: Use kernel/src/<module>/ for core logic, comps/<name>/ for drivers
- **Error Handling**: Use custom error.rs with Result<T, KernelError>
- **Logging**: Via comps/logger/, levels from LOG_LEVEL env
- **Unsafe Code**: Minimize, only in TCB; use safe abstractions elsewhere
- **Testing**: Unit tests in src/, kernel tests via ktest, AUTO_TEST scripts

## Consistency Rules

### Naming Conventions

- Modules: snake_case (e.g., process.rs)
- Types: PascalCase (e.g., Process)
- Functions: snake_case (e.g., create_process)
- Constants: SCREAMING_SNAKE_CASE
- Syscalls: Linux names (e.g., sys_fork)

### Code Organization

- Core in kernel/src/
- Components in comps/
- Libs in libs/
- Tests co-located or in test/
- Arch-specific in arch/

### Error Handling

Use Result and custom error types; propagate errors up, log at appropriate levels.

### Logging Strategy

Structured logging via logger component; levels: error, warn, info, debug, trace.

## Data Architecture

- **Processes**: Managed in process/ with structs for PID, state, etc.
- **Memory**: Page tables, frames tracked in vm/
- **Files**: Inodes and dentries in fs/
- **Network**: Sockets and packets in net/
- Relationships: Processes own threads/files/sockets; hierarchical via parent-child.

No traditional DB; in-memory structures with intrusive collections.

## API Contracts

- **Syscalls**: Linux ABI, e.g., fork() returns pid_t, open() returns fd
- **Internal**: Traits for components (e.g., BlockDevice trait)
- **Errors**: errno.h compatible for syscalls

## Security Architecture

- **Capabilities**: omega-rights for process rights
- **Isolation**: VM page tables, no shared memory without shm
- **TDX**: Optional Intel TDX for confidential computing
- **Min TCB**: Framekernel isolates components

## Performance Considerations

- Boot <5s, syscall <100ns via direct calls
- SMP up to 64 cores
- LTO and release optimizations
- Benchmarking via test/

## Deployment Architecture

- Build: make build/release
- Run: QEMU simulation, KVM for accel
- Production: Bare-metal or hypervisor on supported arches

## Development Environment

### Prerequisites

- Rust toolchain (rust-toolchain.toml)
- Docker for env (omegaosx/omegaosx:0.16.1-20250922)
- QEMU, KVM

### Setup Commands

```bash
git clone https://github.com/swcstudio/omegaosx
cd omegaosx
docker run -it --privileged --network=host --device=/dev/kvm -v $(pwd):/root/omegaosx omegaosx/omegaosx:0.16.1-20250922
make install_osxdk
make build
make run
```

## Architecture Decision Records (ADRs)

1. **Use Rust for Kernel**: Safety without GC; decision in project inception.
2. **Framekernel Design**: Modular TCB; minimizes unsafe, see book/.
3. **Linux ABI**: Compatibility goal; partial impl, track unimplemented syscalls.
4. **Multi-Arch Support**: Portability; conditional compilation via arch/.
5. **OSXDK**: Ease development; custom Cargo commands.
6. **VirtIO-GPU Integration**: Paravirtualized graphics for AR; modular comps/ driver with safe MMIO.
7. **GitBook Docs Sync**: Auto-deploy for enhanced search/collaboration; CI via workflows.

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2025-11-12 (Updated for GPU and Docs)_
_For: BMad_