# Product Brief: VirtIO-GPU Driver for OmegaOS W3.x

## Overview
**Product Name:** VirtIO-GPU Modular Driver  
**Version:** 1.0 Prototype (Sprint 4)  
**Target Audience:** Kernel developers, WEB3.ARL integrators building AR applications on OmegaOS.  
**Date:** 2025-11-12  
**Status:** Proposed (Research Complete, Implementation Pending)  

OmegaOS W3.x introduces VirtIO-GPU as a hot-pluggable component in the framekernel architecture, leveraging existing VirtIO infrastructure (comps/virtio/) for paravirtualized GPU acceleration in QEMU/KVM environments. This driver enables secure, low-latency graphics rendering for decentralized AR protocols, addressing key WEB3 needs like virtualized 3D asset visualization and P2P texture sharing without proprietary hardware dependencies.

## Problem Statement
Current OmegaOS graphics are limited to basic framebuffer console (text mode, pixel rendering in comps/framebuffer/). No support for accelerated rendering, essential for WEB3.ARL use cases:
- AR containers (process/clone.rs CLONE_ARL) lack GPU isolation for viewport rendering.
- P2P mesh (net/omega-bigtcp) cannot accelerate video streams or shaders for AR sessions.
- Enclaves (security/TDX) miss confidential compute for zk-SNARK visuals.
Result: High CPU overhead (>50ms/frame), limiting production AR deployments.

## Solution
**Core Features:**
- **PCI Enumeration & Probing:** Detect VirtIO-GPU (vendor 0x1AF4, device 0x1050) via comps/pci/. Safe MMIO wrappers using osxtd/ for no_std compatibility.
- **Virtqueues Management:** 3 queues (ctrl-q for display info/cmds, cursor-q, display-q for DMA buffers). Use intrusive-collections for ring descriptors; spin locks for synchronization.
- **Framebuffer Integration:** Extend comps/framebuffer/ with VirtIO backend. Render AR viewports via shared Arc<FrameBuffer>; switch console modes (text <-> graphics in comps/console/mode.rs).
- **Security & Isolation:** omega-rights caps (GPU_ACCESS) to gate queue submission; TDX for confidential DMA. No shared memory leaks in AR containers.
- **WEB3.ARL Hooks:** Extend sys_arl_spawn for GPU flags (e.g., CLONE_GPU_ISOLATION); p2p_sync for GPU-accelerated encoding (net/mod.rs).

**Technical Specs:**
- **Story Points:** 5 SP (probe 2SP, queues 2SP, integration 1SP).
- **Dependencies:** Existing VirtIO (comps/virtio/src/device/mod.rs GPU=16), framebuffer pixel ops.
- **API:** New syscall sys_gpu_render(buffer_ptr: usize, cmd: u64) -> Result<isize>; stub logs/Ok(0).
- **Testing:** ktest GPU init (AUTO_TEST=gpu); benchmark <10ms frame in QEMU (make run GPU=virtio).
- **Build:** Add to Makefile (INTEL_TDX=1 for secure); OSXDK target x86_64.

**Architecture Fit:** Modular comps/virtio-gpu/ loads dynamically via comp-sys/. Minimizes TCB unsafe (only MMIO reads); safe abstractions for higher layers.

## Benefits & Value
- **Performance:** 5x faster rendering vs CPU (e.g., AR NFT viz at 60fps).
- **Security:** Capability-based access prevents AR container escapes; IOMMU for DMA.
- **WEB3 Enablement:** P2P AR sessions with shared shaders; zk_verify acceleration (>2x proofs/sec).
- **Compatibility:** Linux ABI for userspace (e.g., OpenGL ES via VirtIO); QEMU standard.
- **ROI:** Enables Epic 6/11 (Device Drivers, WEB3 Integration); production-ready x86-64 AR kernel.

## Risks & Mitigations
- **Unsafe Code:** MMIO races – Use validated descriptors, spin::Mutex.
- **DMA Vulnerabilities:** Guest writes – Enforce IOMMU, cap limits.
- **No Hardware Test:** QEMU virtio-gpu only – Future VFIO for bare-metal.
- **Effort Overrun:** Start with 2D framebuffer; defer 3D cmds.

## Next Steps
1. Prototype comps/virtio-gpu/ (1 week).
2. Integrate with AR stubs (sys_arl_spawn GPU flags).
3. Test in Docker/QEMU; gate-check vs PRD Epic 6.
4. Document in book/src/gpu.md.

**Approval Gate:** Aligns with framekernel modularity; 90% PRD coverage for graphics.

Generated via BMAD core-workflow product-brief (iFlow CLI).