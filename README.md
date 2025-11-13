<p align="center">
   <img src="book/src/images/logo_en.svg" alt="omegaosx-logo" width="620"><br>
   A secure, fast, and general-purpose OS kernel written in Rust and compatible with Linux<br/>
   <a href="https://github.com/omegaosx/omegaosx/actions/workflows/test_x86.yml"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/test_x86.yml/badge.svg?event=push" alt="Test x86-64" style="max-width: 100%;"></a>
   <a href="https://github.com/omegaosx/omegaosx/actions/workflows/test_riscv.yml"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/test_riscv.yml/badge.svg?event=push" alt="Test riscv64" style="max-width: 100%;"></a>
   <a href="https://github.com/omegaosx/omegaosx/actions/workflows/test_loongarch.yml"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/test_loongarch.yml/badge.svg?event=push" alt="Test loongarch64" style="max-width: 100%;"></a>
   <a href="https://github.com/omegaosx/omegaosx/actions/workflows/test_x86_tdx.yml"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/test_x86_tdx.yml/badge.svg" alt="Test Intel TDX" style="max-width: 100%;"></a>
   <a href="https://omegaosx.github.io/benchmark/x86-64/"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/benchmark_x86.yml/badge.svg" alt="Benchmark x86-64" style="max-width: 100%;"></a>
   <a href="https://omegaosx.github.io/benchmark/tdx/"><img src="https://github.com/omegaosx/omegaosx/actions/workflows/benchmark_x86_tdx.yml/badge.svg" alt="Benchmark Intel TDX" style="max-width: 100%;"></a>
   <br/>
</p>

English | [中文版](README_CN.md) | [日本語](README_JP.md)

## Introducing OmegaOS W3.x

OmegaOS W3.x is a _secure_, _fast_, and _general-purpose_ OS kernel that provides _Linux-compatible_ ABI. It can serve as a seamless replacement for Linux while enhancing _memory safety_ and _developer friendliness_.

* OmegaOS W3.x prioritizes memory safety by employing Rust as its sole programming language and limiting the use of _unsafe Rust_ to a clearly defined and minimal Trusted Computing Base (TCB). This innovative approach, known as [the framekernel architecture](https://omegaosx.github.io/book/kernel/the-framekernel-architecture.html), establishes OmegaOS W3.x as a more secure and dependable kernel option.

* OmegaOS W3.x surpasses Linux in terms of developer friendliness. It empowers kernel developers to (1) utilize the more productive Rust programming language, (2) leverage a purpose-built toolkit called [OSXDK](https://omegaosx.github.io/book/osxdk/guide/index.html) to streamline their workflows, and (3) choose between releasing their kernel modules as open source or keeping them proprietary, thanks to the flexibility offered by [MPL](#License).

While the journey towards a production-grade OS kernel is challenging, we are steadfastly progressing towards this goal. Over the course of 2024, we significantly enhanced OmegaOS W3.x's maturity, as detailed in [our end-year report](https://omegaosx.github.io/2025/01/20/omegaosx-in-2024.html). In 2025, our primary goal is to make OmegaOS W3.x production-ready on x86-64 virtual machines and attract real users!

## Current Status

**🚀 Development Environment: READY**
- ✅ OSXDK toolkit fully functional
- ✅ Docker containerization working
- ✅ Development tools operational
- ✅ Multi-architecture support (x86-64, RISC-V, LoongArch)

**⚠️ Kernel Compilation: DEPENDENCIES REQUIRED**
- 🔒 Private repository dependencies require authentication
- 🔧 Working on public release of development dependencies
- 📦 Simplified build process coming soon

## Quick Start

Get yourself an x86-64 Linux machine with Docker installed. Follow the steps below to set up the OmegaOS W3.x development environment.

### Prerequisites

- Docker or Podman installed
- x86-64 Linux machine with KVM support
- Git

### Development Environment Setup

1. **Clone the OmegaOS W3.x repository**

```bash
git clone https://github.com/omegaosx/omegaosx
cd omegaosx
```

2. **Build the development Docker image**

```bash
docker build -f osxdk/tools/docker/Dockerfile --build-arg OMEGA_RUST_VERSION=nightly-2025-02-01 -t omegaosx/osxdk:latest .
```

3. **Run the development container**

```bash
docker run -it --privileged --network=host --device=/dev/kvm -v $(pwd):/root/omegaosx omegaosx/osxdk:latest
```

4. **Inside the container, verify the development environment**

```bash
cd /root/omegaosx
# The OSXDK toolkit is available for development
cargo osdk --help
```

### Working with the Development Environment

The OSXDK toolkit provides comprehensive development capabilities:

```bash
# Build kernel modules (requires private dependencies)
cargo osdk build

# Run tests
cargo osdk test

# Generate documentation
cargo osdk doc

# Check code coverage
cargo osdk coverage
```

## Architecture Support

OmegaOS W3.x supports multiple architectures:

- **x86-64**: Full support with Intel TDX capabilities
- **RISC-V**: Complete implementation with device tree support
- **LoongArch**: Initial support added in v0.16.0

## Documentation

See [The OmegaOS W3.x Book](https://omegaosx.github.io/book/) to learn more about the project architecture, development guides, and API documentation.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to get started.

## License

OmegaOS W3.x's source code and documentation primarily use the [Mozilla Public License (MPL), Version 2.0](https://github.com/omegaosx/omegaosx/blob/main/LICENSE-MPL). Select components are under more permissive licenses, detailed [here](https://github.com/omegaosx/omegaosx/blob/main/.licenserc.yaml). For the rationales behind the choice of MPL, see [here](https://omegaosx.github.io/book/index.html#licensing).