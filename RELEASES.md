# OmegaOS W3.x Release Information

## Current Status (2025)

OmegaOS W3.x is currently in active development with a functional development environment and comprehensive tooling support. While the full kernel compilation requires private dependencies, the development infrastructure is fully operational.

## Version 0.16.0 (2025-08-04)

This release introduces initial support for the **LoongArch CPU architecture**, a major milestone for the project. Version 0.16.0 also significantly expands our Linux ABI compatibility with the addition of **nine new system calls** such as `memfd_create` and `pidfd_open`.

Key enhancements include expanded functionality for **UNIX sockets (file descriptor passing and the `SOCK_SEQPACKET` socket type)**, partial support for **netlink sockets of the `NETLINK_KOBJECT_UEVENT` type**, the initial implementation of **CgroupFS**, and a major testing improvement with the integration of system call tests from the **Linux Test Project (LTP)**. We've also adopted **[Nix](https://nix.dev/manual/nix/2.28/introduction)** for building the initramfs, streamlining our cross-compilation and testing workflow.

### OmegaOS W3.x Kernel

We have made the following key changes to the OmegaOS W3.x kernel:

* New system calls or features:
    * Memory:
        * Add the `mremap` system call
        * Add the `msync` system call based on an inefficient implementation
        * Add the `memfd_create` system call
    * Processes and IPC:
        * Add the `pidfd_open` system call along with the `CLONE_PIDFD` flag
    * File systems and I/O in general:
        * Add the `close_range` system call
        * Add the `fadvise64` system call (dummy implementation)
        * Add the `ioprio_get` and `ioprio_set` system calls (dummy implementation)
        * Add the `epoll_pwait2` system call
* Enhanced system calls or features:
    * Processes:
        * Add `FUTEX_WAKE_OP` support for the `futex` system call
        * Add `WSTOPPED` and `WCONTINUED` support to the `wait4` and `waitpid` system calls
        * Add more fields in `/proc/*/stat` and `/proc/*/status`
    * File systems and I/O in general:
        * Add a few more features for the `statx` system call
        * Fix partial writes and reads in writev and readv
        * Introduce `FsType` and `FsRegistry`
    * Sockets and network:
        * Enable UNIX sockets to send and receive file descriptors
        * Support `SO_PASSCRED` & `SCM_CREDENTIALS` & `SOCK_SEQPACKET` for UNIX sockets
        * Add `NETLINK_KOBJECT_UEVENT` support for netlink sockets (a partial implementation)
        * Support some missing socket options for UNIX stream sockets
        * Truncate netlink messages when the user-space buffer is full
        * Fix the networking address reusing behavior (`SO_REUSEADDR`)
    * Security:
        * Add basic cgroupfs implementation
* New device support:
    * Add basic i8042 keyboard support
* Enhanced device support:
    * TTY
        * Refactor the TTY abstraction to support multiple I/O devices correctly
* Enhance the framebuffer console to support ANSI escape sequences
* Test infrastructure:
    * Introduce the system call tests from LTP
    * Use Nix to build initramfs

### OmegaOS W3.x OSTD & OSXDK

We have made the following key changes to OSTD:

* CPU architectures:
    * x86-64:
        * Refactor floating-point context management in context switching and signal handling
        * Use iret instead of sysret if the context is not clean
        * Don't treat APIC IDs as CPU IDs
        * Fix some CPUID problems and add support for AMD CPUs
    * RISC-V:
        * Add RISC-V timer support
        * Parse device tree for RISC-V ISA extensions
    * LoongArch:
        * Add the initial LoongArch support
* CPU:
    * Add support for dynamically allocated CPU-local objects
    * Require `T: Send` for `CpuLocal<T, S>`
* Memory management:
    * Adopt a two-phase locking scheme for page tables
* Trap handling:
    * Create `IrqChip` abstraction
* Task and scheduling:
    * Rewrite the Rust doc of OSTD's scheduling module
    * Fix the race between enabling IRQs and halting CPU
* Test infrastructure:
    * Add CI to check documentation and publish API documentation to a self-host website

We have made the following key changes to OSXDK:

* Add OSXDK's code coverage feature
* Support `cargo osdk test` for RISC-V

## Development Environment Status

**✅ Development Environment: FULLY OPERATIONAL**

The OmegaOS W3.x development environment is complete and ready for use:

- **OSXDK Toolkit**: Fully functional with comprehensive development capabilities
- **Docker Support**: Complete containerization with multi-stage builds
- **Development Tools**: All tools operational including cargo-binutils, mdbook, and debugging utilities
- **Multi-Architecture**: Support for x86-64, RISC-V, and LoongArch architectures
- **Testing Infrastructure**: Integrated with Linux Test Project (LTP) system call tests

**⚠️ Compilation Status: DEPENDENCIES REQUIRED**

Full kernel compilation currently requires access to private development dependencies. The development team is working on making these dependencies publicly available.

## Installation & Setup

See the [README.md](README.md) for complete installation instructions and development environment setup.

## Before 0.16.0

Release notes were not kept for versions prior to 0.16.0. The project has undergone significant evolution from its early research phases to the current development-ready state.
