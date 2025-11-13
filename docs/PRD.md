# OmegaOS W3.x - Product Requirements Document

**Author:** BMad
**Date:** 2025-11-12 (Updated for GPU/Docs Epics)
**Version:** 1.0

---

## Executive Summary

OmegaOS W3.x is a secure, modular OS kernel designed for Web3 Augmented Reality (WEB3.ARL) protocols, built in Rust to provide Linux-compatible ABI while enhancing memory safety.

### What Makes This Special

The magic of OmegaOS lies in its framekernel architecture that minimizes unsafe Rust code, enabling a trusted computing base (TCB) that's both secure and developer-friendly for building decentralized AR applications.

---

## Project Classification

**Technical Type:** os_kernel
**Domain:** blockchain_web3
**Complexity:** high

Brownfield project enhancing the existing Asterinas kernel to OmegaOS W3.x, focusing on WEB3.ARL integration and multi-architecture support.

### Domain Context

WEB3.ARL requires secure, low-latency kernel support for decentralized protocols, including custom sockets, secure execution environments, and compatibility with Linux tools for developer adoption.

---

## Success Criteria

- Achieve production-ready status on x86-64 architecture.
- Publish accepted papers (ICSE 2026, USENIX ATC 2025).
- Win awards like SOSP 2025 Best Paper.
- Support multiple architectures: x86_64, riscv64imac, loongarch64.
- Pass all syscall, boot, and integration tests.
- Enable seamless Linux application porting via ABI compatibility.

### Business Metrics

- Open-source adoption: GitHub stars, forks, contributors.
- Community contributions via RFC process.
- Integration in WEB3 projects and AR protocol stacks.

---

## Product Scope

### MVP - Minimum Viable Product

- Core kernel boot and basic process management on x86_64.
- Essential syscalls for process, file, and device operations.
- Basic testing and build system with QEMU support.

### Growth Features (Post-MVP)

- Modular components (comps/) for block, network, input, etc.
- Multi-architecture support (riscv, loongarch).
- Advanced features: TDX, networking (tap/vsock), profiling.
- OSXDK and OSXTD for development kit and std lib.

### Vision (Future)

- Full Linux ABI compatibility for seamless replacement.
- Production deployment in WEB3.ARL ecosystems.
- Enhanced security with minimized TCB and framekernel optimizations.

---

## Domain-Specific Requirements

- Secure execution for decentralized AR protocols.
- Support for custom networking primitives (e.g., omega-bigtcp).
- Compliance with open-source licenses (MPL 2.0).
- Integration with crypto libraries if needed for WEB3.

This shapes requirements for secure IPC, net stack, and VM isolation.

---

## OS Kernel Specific Requirements

- Architecture support: x86_64, riscv64imac, loongarch64-unknown-none-softfloat.
- Syscall interface compatible with Linux ABI.
- Modular driver and component system (comps/, device/).
- Memory management with frame allocator and VM support.
- Scheduler for multi-core (SMP).

Key Requirements:

- Boot process with initramfs support.
- Process creation, scheduling, and termination.
- File system VFS and implementations.
- Networking stack with sockets and drivers.
- Device management for PCI, virtio, etc.

---

## User Experience Principles

N/A - Kernel level, no direct UI. Developer experience via OSXDK tools (cargo osxdk build/run).

---

## Functional Requirements

### Core Kernel

- Bootloader and early initialization (arch-specific).
- CPU management: context switching, interrupts.
- Memory allocation: frame allocator, page tables.

### Process Management

- Process creation via fork/exec.
- Thread support.
- Signal handling.
- Resource limits and rights management (omega-rights).

### File System

- VFS abstraction.
- Support for ramfs, ext2, etc.
- Initramfs extraction.

### Networking

- Socket API compatible with Linux.
- TCP/IP stack.
- Virtio-net, tap support.

### Device Drivers

- PCI enumeration and hotplug.
- Console, keyboard, framebuffer.
- Block devices, virtio.

### Scheduling

- Multi-core scheduler.
- Priority and fairness.

### IPC

- Pipes, shared memory.
- Syscalls for messaging.

### Security

- Capability-based rights.
- Secure boot options (TDX).

### Utilities

- Timekeeping.
- Logging.
- Command line parsing.

Each with acceptance criteria: pass ktest, unit tests, build successfully.

---

## Non-Functional Requirements

### Performance

- Boot time < 5s in QEMU.
- Context switch overhead < 1us.
- Syscall latency < 100ns.

### Security

- Minimize unsafe Rust (<5% code).
- Framekernel TCB isolation.
- No known vulnerabilities in tests.

### Scalability

- Support up to 64 cores (SMP=64).
- Multi-arch builds.

### Compatibility

- Linux ABI for user-space apps.
- Run standard Linux binaries where possible.

### Integration

- QEMU simulation.
- KVM acceleration.
- Docker build environment.

---

### Implementation Planning

#### Epic Breakdown

The following epics represent major areas of development for OmegaOS W3.x. Each epic includes a high-level description, key user stories (framed for kernel developers and system integrators), and acceptance criteria.

**Epic 1: Core Kernel and Boot**

*Description:* Establish the foundational kernel structure, including architecture-specific initialization, early boot sequence, and basic runtime environment setup.

*Stories:*
- As a kernel developer, I want architecture-specific boot code (e.g., for x86_64) so that the kernel can initialize the CPU, memory, and interrupts correctly.
- As a system integrator, I want kernel command line parsing so that boot parameters like SMP, MEM, and LOG_LEVEL can be configured dynamically.
- As a developer, I want basic error handling and logging during boot so that initialization failures can be diagnosed.

*Acceptance Criteria:* Kernel successfully boots to a basic shell in QEMU; passes boot tests (AUTO_TEST=boot).

**Epic 2: Process and Thread Management**

*Description:* Implement process lifecycle management, including creation, execution, scheduling hooks, and termination, with support for multi-threading.

*Stories:*
- As a developer, I want fork() and exec() syscalls compatible with Linux ABI so that existing applications can spawn processes.
- As a system integrator, I want thread creation and management so that multi-threaded applications can run efficiently.
- As a security engineer, I want process rights management using omega-rights so that capabilities are enforced.

*Acceptance Criteria:* Basic user-space processes can fork and exec binaries; syscall tests pass (AUTO_TEST=syscall).

**Epic 3: Virtual Memory**

*Description:* Provide memory management abstractions, including page allocation, virtual address spaces, and frame allocation.

*Stories:*
- As a kernel developer, I want a frame allocator so that physical memory pages can be tracked and allocated.
- As a process manager, I want virtual memory mapping (mmap, mprotect) so that processes can manage their address spaces.
- As a security specialist, I want page table isolation so that processes cannot access each other's memory.

*Acceptance Criteria:* Processes can allocate and map memory without leaks or crashes; VM tests in ktest pass.

**Epic 4: File System**

*Description:* Implement the Virtual File System (VFS) layer and support for initial file systems like ramfs and initramfs extraction.

*Stories:*
- As a developer, I want VFS abstractions for open, read, write, and close so that file operations are portable.
- As a boot loader, I want initramfs extraction so that the initial root filesystem can be unpacked.
- As a system admin, I want support for basic filesystems (e.g., ramfs) so that temporary files can be stored.

*Acceptance Criteria:* Basic file I/O works in user-space; fs tests pass.

**Epic 5: Networking Stack**

*Description:* Build a Linux-compatible networking subsystem, including sockets, TCP/IP, and drivers for virtio-net and tap.

*Stories:*
- As a network engineer, I want socket syscalls (socket, bind, connect) so that applications can communicate over networks.
- As a WEB3 developer, I want support for custom protocols like omega-bigtcp for decentralized AR.
- As a tester, I want VSOCK and tap device support so that virtual networking can be tested.

*Acceptance Criteria:* Ping and basic TCP connections work in QEMU; AUTO_TEST=vsock passes.

**Epic 6: Device Drivers and Components**

*Description:* Develop modular components (comps/) for hardware interaction, including PCI, virtio, console, input, and GPU devices.

*Stories:*
- As a hardware integrator, I want PCI enumeration so that devices can be discovered and configured.
- As a user, I want console and keyboard drivers so that input/output is functional.
- As a component developer, I want the comps/ framework to load modular drivers dynamically.
- As a graphics developer, I want VirtIO-GPU support in comps/virtio-gpu/ so that AR applications can render accelerated viewports in QEMU/KVM environments, integrating with framebuffer for WEB3.ARL protocols.

*Acceptance Criteria:* Devices like framebuffer, keyboard, and VirtIO-GPU respond correctly; GPU init and basic rendering pass in QEMU (AUTO_TEST=gpu); device tests cover DMA security via omega-rights.

**Epic 7: Scheduler and Time**

*Description:* Implement a multi-core scheduler and timekeeping mechanisms for fair resource allocation and timing.

*Stories:*
- As a scheduler designer, I want a priority-based scheduler supporting SMP so that multi-core execution is efficient.
- As a developer, I want accurate time syscalls (gettimeofday, nanosleep) so that applications can handle timing.
- As a tester, I want softirq handling for deferred work so that interrupts don't block the kernel.

*Acceptance Criteria:* Multi-core scheduling works (SMP=4); time tests accurate within 1ms.

**Epic 8: IPC and Security**

*Description:* Provide inter-process communication primitives and security features like capabilities and TDX support.

*Stories:*
- As an application developer, I want pipes and shared memory for IPC so that processes can communicate.
- As a security expert, I want capability-based security with omega-rights-proc so that least-privilege is enforced.
- As a confidential computing user, I want Intel TDX support so that secure enclaves can run.

*Acceptance Criteria:* IPC syscalls work; security tests (e.g., rights enforcement) pass; TDX builds successfully.

**Epic 9: Testing and Build Tools**

*Description:* Enhance testing suite, build system, developer tools including OSXDK, and documentation with GitBook integration.

*Stories:*
- As a contributor, I want comprehensive unit and kernel tests (cargo test, ktest) so that changes can be verified.
- As a developer, I want OSXDK commands (cargo osxdk build/run) streamlined for no_std development.
- As a documenter, I want updated book and API docs with GitBook sync for interactive search and collaboration so that contributors can easily navigate kernel guides and WEB3.ARL features.

*Acceptance Criteria:* All tests pass (AUTO_TEST=test); build with RELEASE=1 succeeds; coverage >80%; GitBook deploys on CI with search for terms like 'VirtIO-GPU' and auto-sync from book/src/.

**Epic 10: Multi-Architecture and Optimizations**

**Epic 11: Native WEB3/ARL Integration**

*Description:* Introduce deep OS-level support for WEB3 and ARL features, enabling secure decentralized AR protocols.

*Stories:*
- As a WEB3 developer, I want extended net/ sockets for P2P protocols so that AR apps can communicate securely over BigTCP.
- As an ARL integrator, I want enhanced ipc/ shm/pipes with caps for secure AR data channels so that real-time AR tasks isolate properly.
- As a container manager, I want namespaces/caps in process/ for AR task containers so that WEB3.ARL runtimes execute with least privilege.

*Acceptance Criteria:* Custom sockets pass net tests; AR container spawns without leaks; integrates with TDX for confidential AR.

*Description:* Extend support to RISC-V and LoongArch, with performance optimizations like LTO and profiling.

*Stories:*
- As an arch porter, I want riscv64imac support so that the kernel runs on RISC-V hardware.
- As a performance engineer, I want LTO and release optimizations so that boot and runtime are faster.
- As a profiler, I want GDB and profiling tools so that bottlenecks can be identified.

*Acceptance Criteria:* Builds and runs on multiple arches (OSXDK_TARGET_ARCH=riscv64); performance benchmarks meet targets.

---

## References

- Project Documentation: /home/ubuntu/src/repos/omegaosx/docs/index.md
- Kernel Source: /home/ubuntu/src/repos/omegaosx/kernel/
- Book: /home/ubuntu/src/repos/omegaosx/book/

---

## Next Steps

1. **Epic & Story Breakdown** - Completed (incl. WEB3/ARL Epic 11)

2. **UX Design** (if UI) - N/A
3. **Architecture** - Run: `workflow create-architecture`

---

_This PRD captures the essence of OmegaOS W3.x - Memory-safe kernel for the Web3 era._

_Created through collaborative discovery between BMad and AI facilitator._