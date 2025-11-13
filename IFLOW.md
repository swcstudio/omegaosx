# OmegaOS W3.x Project IFLOW.md

## Project Overview

OmegaOS W3.x is a secure, fast, general-purpose OS kernel in Rust for WEB3.ARL as its sole programming language, providing Linux-compatible ABI (Application Binary Interface). It aims to serve as a seamless replacement for Linux while enhancing memory safety and developer friendliness. The project adopts a framekernel architecture, minimizing the use of unsafe Rust, and provides OSXDK (OS Development Kit) and OSXTD (OS Standard Library) to simplify kernel development.

### Main Technologies and Architecture
- **Programming Language**: Rust (edition 2021), with minimized unsafe code usage.
- **Architecture**: Framekernel architecture, dividing the kernel into a minimal TCB (Trusted Computing Base) and componentized modules (e.g., comps/block, comps/network).
- **Supported Architectures**: x86_64, riscv64imac, loongarch64-unknown-none-softfloat.
- **Key Components**:
  - **kernel/**: Kernel core, including process management (process/), file systems (fs/), networking (net/), device drivers (device/), etc.
  - **osxdk/**: OS Development Kit, providing Cargo subcommands (e.g., `cargo osxdk build`, `cargo osxdk run`) to manage no_std builds.
  - **osxtd/**: OS Standard Library, offering OS-specific extensions like memory allocation and intrusive collections.
  - **book/**: Documentation source, using mdbook to generate The OmegaOS W3.x Book.
  - **test/**: Integration tests, including syscall and benchmark tests.
- **License**: Mozilla Public License (MPL) 2.0, with some components under more permissive licenses (see .licenserc.yaml).
- **Latest Updates (2025)**: ICSE 2026 accepted the RusyFuzz paper; SOSP 2025 Best Paper Award for CortenMM; Two papers at USENIX ATC 2025. Goal: Production-ready on x86-64.

Project documentation: See [The OmegaOS W3.x Book](https://omegaosx.github.io/book/), covering kernel architecture, OSXDK guide, and Linux compatibility (current limitations such as unimplemented system calls).

## Building and Running

Uses Makefile and Cargo OSXDK. Docker environment recommended (requires KVM).

### Environment Setup
1. Clone: `git clone https://github.com/swcstudio/omegaosx`
2. Docker container:
   ```
   docker run -it --privileged --network=host --device=/dev/kvm -v $(pwd)/omegaosx:/root/omegaosx omegaosx/omegaosx:0.16.1-20250922
   ```
3. Install OSXDK: `make install_osxdk`

### Building
- Basic: `make build` or `cd kernel && cargo osxdk build`
- Release: `make build RELEASE=1`
- LTO Optimization: `make build RELEASE_LTO=1`
- Coverage: `make build COVERAGE=1`
- Architecture: `OSXDK_TARGET_ARCH=riscv64 make build`
- TDX: `make build INTEL_TDX=1`

### Running
- Basic: `make run`
- With parameters: `make run LOG_LEVEL=debug SMP=4 MEM=4G`
- Networking: `make run NETDEV=tap`
- GDB: `make gdb_server` (server), `make gdb_client` (client)
- Profiling: `make profile_server` and `make profile_client`

### Testing
- Unit (non-OSXDK): `make test`
- Kernel: `make ktest`
- Automated:
  - Syscalls: `make run AUTO_TEST=syscall`
  - General: `make run AUTO_TEST=test`
  - Boot: `make run AUTO_TEST=boot`
  - VSOCK: `make run AUTO_TEST=vsock`
- Integration: `make initramfs` to prepare initramfs in test/.

### Documentation
- Book: `make book`
- API: `make docs`

## Dependencies

- **Workspace Members**: osxtd, kernel, osxdk/deps, etc. (see Cargo.toml).
- **Key Dependencies** (examples):
  - General: spin=0.9.4, bitflags=1.3, intrusive-collections=0.9.6
  - x86_64: x86_64=0.14.13, tdx-guest=0.2.1 (optional)
  - RISC-V: riscv=0.11.1
  - OSXDK: clap=4.4.17, serde=1.0.195
- No package.json (pure Rust project); dependencies managed via Cargo. Update: OSXDK v0.16.1.

## Development Practices

- **Style**: rustfmt (`make format`), Clippy (`make check`). Follow book/src/to-contribute/style-guidelines/ (Rust/Git/ASM guidelines).
- **Linting**: Workspace lints (unsafe_op_in_unsafe_fn="warn").
- **Testing**: Unit (cargo test), kernel (cargo osxdk test), coverage (COVERAGE=1).
- **Contributions**: RFC process (book/src/rfcs/), run `make check` before PR. Use .github/ISSUE_TEMPLATE/ for issues.
- **Tools**: QEMU simulation, KVM acceleration. Git: .gitignore, triagebot.toml.
- **New Features**: Intel TDX support (INTEL_TDX=1), benchmarking (BENCHMARK=...), BMAD/iFlow workflows (.bmad/ and .iflow/) for agent development.