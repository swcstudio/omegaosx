# OmegaOS W3.x Documentation Index (Full Rescan - 2025-11-12)

## Project Overview

**Type:** monorepo with 7 parts  
**Primary Language:** Rust (edition 2021, no_std for kernel)  
**Architecture:** Framekernel (modular TCB + components for kernel; Cargo CLI for osxdk; library crates for osxtd)  
**Purpose:** Secure, fast OS kernel for WEB3.ARL (Linux ABI compatible), with OSXDK/OSXTD for development.  
**Owners:** swcstudio/omegaosx (GitHub), MPL 2.0 license.  
**Total LOC:** ~25k (exhaustive scan: kernel ~15k, osxdk ~2k, osxtd ~1k, others ~7k docs/scripts).  

Repository structure: kernel (core), osxdk (tools), osxtd (std lib), book/docs (documentation), test (tests), tools (infra).

## Quick Reference

### kernel (embedded - Framekernel)
- **Type:** embedded/system kernel  
- **Tech Stack:** Rust no_std, deps: spin=0.9.4, x86_64=0.14.13, riscv=0.11.1, intrusive-collections=0.9.6  
- **Root:** kernel/  
- **Entry Point:** src/main.rs (boot via arch/x86_64 or riscv)  
- **Architecture Pattern:** Modular framekernel (minimal core + hot-plug comps/drivers)

### osxdk (cli - Development Kit)
- **Type:** cli toolkit  
- **Tech Stack:** Rust, clap=4.4.17, serde=1.0.195  
- **Root:** osxdk/  
- **Entry Point:** src/main.rs (cargo osxdk subcommands)  
- **Architecture Pattern:** Cargo extension (build/run/test commands)

### osxtd (library - OS Std Lib)
- **Type:** library crates  
- **Tech Stack:** Rust no_std, alloc/intrusive-colls  
- **Root:** osxtd/  
- **Entry Point:** src/lib.rs (export crates)  
- **Architecture Pattern:** Reusable kernel libs (utils/collections)

### book (docs - mdBook)
- **Type:** docs generator  
- **Tech Stack:** mdBook, Markdown  
- **Root:** book/  
- **Entry Point:** book.toml (build via mdbook)  
- **Architecture Pattern:** Static site (src/SUMMARY.md)

### test (library - Test Harness)
- **Type:** library (integration tests)  
- **Tech Stack:** Rust, Makefile  
- **Root:** test/  
- **Entry Point:** Makefile (make ktest)  
- **Architecture Pattern:** Syscall/benchmark suite

### docs (docs - Technical Docs)
- **Type:** docs (Markdown)  
- **Tech Stack:** None (plain MD)  
- **Root:** docs/  
- **Entry Point:** index.md  
- **Architecture Pattern:** Reference manual

### tools (infra - Scripts/Build)
- **Type:** infra (deployment/CI)  
- **Tech Stack:** Bash/Rust, GitHub Actions  
- **Root:** tools/  
- **Entry Point:** Makefile (top-level)  
- **Architecture Pattern:** Script-based (docker/workflows)

## Generated Documentation

- [Project Overview](./project-overview.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Integration Architecture](./integration-architecture.md)

**Per-Part Architectures:**
- [kernel Architecture](./architecture-kernel.md)
- [osxdk Architecture](./architecture-osxdk.md)
- [osxtd Architecture](./architecture-osxtd.md)
- [book Architecture](./architecture-book.md)
- [test Architecture](./architecture-test.md)
- [docs Architecture](./architecture-docs.md)
- [tools Architecture](./architecture-tools.md)

**Supporting Docs:**
- [Component Inventory - kernel](./component-inventory-kernel.md)
- [Development Guide](./development-guide.md)
- [Deployment Configuration](./deployment-configuration.md)
- [Contribution Guidelines](./contribution-guidelines.md)
- [Hardware Interfaces - kernel](./hardware-interfaces-kernel.md)
- [Project Parts Metadata](./project-parts.json)

## Existing Documentation

- [kernel/libs/comp-sys/cargo-component README](kernel/libs/comp-sys/cargo-component/README.md) - Component system
- [kernel/libs/logo-ascii-art README](kernel/libs/logo-ascii-art/README.md) - ASCII art
- [kernel/libs/int-to-c-enum README](kernel/libs/int-to-c-enum/README.md) - Enum utils
- [kernel/libs/comp-sys/component README](kernel/libs/comp-sys/component/README.md) - Components
- [osxdk README](osxdk/README.md) - Main kit
- [osxdk/tools/docker README](osxdk/tools/docker/README.md) - Docker tools
- [osxdk/deps README](osxdk/deps/README.md) - Deps
- [osxdk/deps/test-kernel README](osxdk/deps/test-kernel/README.md) - Test kernel
- [osxdk/deps/heap-allocator README](osxdk/deps/heap-allocator/README.md) - Heap
- [osxdk/deps/frame-allocator README](osxdk/deps/frame-allocator/README.md) - Frame
- [osxtd README](osxtd/README.md) - Std lib
- [book/src README](book/src/README.md) - Book source
- [book/src/to-contribute README](book/src/to-contribute/README.md) - Contributing
- [book/src/rfcs README](book/src/rfcs/README.md) - RFCs
- [book/src/osxtd README](book/src/osxtd/README.md) - OSXTD section
- [book/src/to-contribute/style-guidelines README](book/src/to-contribute/style-guidelines/README.md) - Style
- [book/src/osxdk/reference README](book/src/osxdk/reference/README.md) - OSXDK ref
- [book/src/osxdk/guide README](book/src/osxdk/guide/README.md) - OSXDK guide
- [book/src/kernel/the-approach README](book/src/kernel/the-approach/README.md) - Kernel approach
- [book/src/kernel/linux-compatibility README](book/src/kernel/linux-compatibility/README.md) - Linux compat
- [book/src/osxdk/reference/commands README](book/src/osxdk/reference/commands/README.md) - Commands
- [book/src/kernel/linux-compatibility/limitations-on-system-calls README](book/src/kernel/linux-compatibility/limitations-on-system-calls/README.md) - Syscall limits
- [book/src/kernel README](book/src/kernel/README.md) - Kernel section
- [test/src/benchmark README](test/src/benchmark/README.md) - Benchmarks
- [test README](test/README.md) - Tests
- [docs/architecture.md](docs/architecture.md) - Existing arch
- [tools/docker README](tools/docker/README.md) - Docker

## Getting Started

1. **Clone:** `git clone https://github.com/swcstudio/omegaosx`
2. **Setup:** `make install_osxdk` (Rust 1.75+, KVM/Docker)
3. **Build:** `make build` (or `cargo osxdk build` for kernel)
4. **Run:** `make run` (QEMU, SMP=4 MEM=4G)
5. **Test:** `make test` (unit), `make ktest` (kernel)
6. **Docs:** `make book` (mdBook), view at omegaosx.github.io/book
7. **Deploy:** GitHub Actions (workflows/test_x86.yml), Docker: `docker build -t omegaosx .` in tools/docker

For per-part: Kernel (make run), OSXDK (cargo osxdk), Tests (make ktest). Refer to development-guide.md for details.

Last Updated: 2025-11-12  
Parts: 7  
Generated Files: 17