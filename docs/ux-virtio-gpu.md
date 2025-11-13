# UX Design: VirtIO-GPU Driver for OmegaOS W3.x

## Overview
**Feature:** VirtIO-GPU Modular Driver  
**UX Focus:** Developer Experience (DevX) for kernel integrators and WEB3.ARL app developers.  
**Date:** 2025-11-12  
**Principles:** Simplicity (minimal unsafe), Modularity (comps/ hot-plug), Security (caps-gated), Compatibility (Linux ABI). No end-user UI; focus on API ergonomics and tooling.  

Kernel-level graphics have no direct UI, so UX emphasizes seamless integration, discoverability, and low-friction development for AR rendering in QEMU/KVM.

## User Personas
- **Kernel Developer (Primary):** Builds/extends comps/virtio-gpu/; needs clear PCI probe, queue APIs.
- **WEB3.ARL Integrator (Secondary):** Uses syscalls for AR viewports in containers; expects intuitive flags/caps.
- **Tester/Contributor:** Runs AUTO_TEST=gpu; wants readable logs, easy debugging.

## UX Goals
- **Ease of Integration:** Plug-and-play comps/ loading; auto-detect VirtIO-GPU in boot (init.rs).
- **Discoverability:** Docs in book/src/gpu.md with examples (e.g., render AR frame via syscall).
- **Error Handling:** Descriptive Errno (e.g., EACCES for cap denial); log::info! for queue states.
- **Performance Feedback:** Sysfs-like exposure (systree/) for GPU stats (e.g., queue depth, render latency).
- **Accessibility:** No_std safe wrappers; OSXDK commands (cargo osxdk test-gpu).

## Key Interactions & Flows
### 1. Driver Loading (DevX Flow)
- **Trigger:** Boot with QEMU -device virtio-gpu.
- **Steps:**
  1. PCI enum (comps/pci/) detects device → log::info!("VirtIO-GPU probed at BAR0").
  2. comps/virtio-gpu/ loads via comp-sys/ → Negotiate features (VIRTIO_GPU_F_VIRGL for 3D).
  3. Init queues (ctrl/cursor/display) → Allocate DMA buffers with osxtd/ intrusive-collections.
  4. Integrate framebuffer → Console switch to Graphics mode (mode.rs).
- **UX Elements:** Safe trait impls (trait VirtGpuDriver { fn submit_cmd(&self, cmd: &Cmd) -> Result<()> }); error: "DMA alloc failed: ENOMEM" with hints.
- **Pain Points Mitigated:** Unsafe MMIO hidden in wrappers; spin locks prevent races.

### 2. AR Rendering in Containers (Integrator Flow)
- **Trigger:** sys_arl_spawn with CLONE_GPU_ISOLATION flag.
- **Steps:**
  1. clone.rs checks cap GPU_ACCESS → Alloc isolated queues per container.
  2. sys_gpu_render(ptr: usize, size: usize, cmd: u64) → Submit to display-q; return job_id.
  3. Poll/complete via sys_gpu_status(job_id) → Latency <10ms logged.
  4. P2P share: net/omega-bigtcp hooks for texture export (ipc/shm).
- **UX Elements:** Bitflags for cmds (e.g., GPU_RENDER_AR_VIEWPORT); Result<isize> with errno (EINVAL for invalid ptr). Example syscall in book/:
    ```rust
    let job = unsafe { syscall(sys_gpu_render, buf.as_ptr() as _, buf.len(), CMD_AR_VIEWPORT) };
    if job < 0 { eprintln!("Render failed: {}", io::Error::from_raw_os_error(-job)); }
    ```
- **Pain Points Mitigated:** Cap checks prevent leaks; fallback to software render (vm/) if no GPU.

### 3. Testing & Debugging (Contributor Flow)
- **Trigger:** make run GPU=virtio AUTO_TEST=gpu.
- **Steps:**
  1. ktest boots → Probe GPU, submit test cmd (display info).
  2. Render benchmark frame → Assert <10ms, no DMA errors.
  3. GDB attach (make gdb_client) → Break on queue submit; inspect buffers.
- **UX Elements:** AUTO_TEST=gpu outputs "GPU: VirtIO ready, queues: 3 active"; coverage via COVERAGE=1.
- **Pain Points Mitigated:** QEMU console shows live framebuffer; logs filter by "virtio-gpu:".

## Wireframes/Sketch (Conceptual)
- **API Surface:** 
  - Syscalls: sys_gpu_* (simple u64 args, like sys_zk_verify).
  - Traits: SafeGpu (no raw ptrs; use slices).
- **Tooling:** OSXDK subcmd: cargo osxdk gpu-test (runs ktest subset).
- **Metrics:** Dev time <1 day to render first AR frame; 95% syscall success in tests.

## Risks & Mitigations
- **Complexity for Noobs:** Unsafe hidden → Tutorials in book/ with safe examples.
- **Debug Overhead:** Verbose logs → Toggle via LOG_LEVEL=gpu.
- **Cross-Arch:** x86 focus → RISC-V stub (future Epic 10).

## Next Steps
- Prototype API in syscall/mod.rs (1 SP).
- User test with AR stub app.
- Integrate feedback into book/src/.

Generated via BMAD core-workflow UX (iFlow CLI). Kernel DevX prioritized; no end-user UI.