## Introducing OmegaOS W3.x

OmegaOS W3.x is a _secure_, _fast_, and _general-purpose_ OS kernel that provides _Linux-compatible_ ABI. It can serve as a seamless replacement for Linux while enhancing _memory safety_ and _developer friendliness_.

### 🎉 Latest Release: 1.0.0 (LATEST)
**Release Date:** November 18, 2025  
**Container Package:** `ghcr.io/swcstudio/omega-osx-parrotsec:latest`  
**Status:** Available for public download and deployment

* OmegaOS W3.x prioritizes memory safety by employing Rust as its sole programming language and limiting the use of _unsafe Rust_ to a clearly defined and minimal Trusted Computing Base (TCB). This innovative approach, known as [the framekernel architecture](https://omegaosx.github.io/book/kernel/the-framekernel-architecture.html), establishes OmegaOS W3.x as a more secure and dependable kernel option.

* OmegaOS W3.x surpasses Linux in terms of developer friendliness. It empowers kernel developers to (1) utilize the more productive Rust programming language, (2) leverage a purpose-built toolkit called [OSXDK](https://omegaosx.github.io/book/osxdk/guide/index.html) to streamline their workflows, and (3) choose between releasing their kernel modules as open source or keeping them proprietary, thanks to the flexibility offered by [MPL](#License).

While the journey towards a production-grade OS kernel is challenging, we are steadfastly progressing towards this goal. Over the course of 2024, we significantly enhanced OmegaOS W3.x's maturity, as detailed in [our end-year report](https://omegaosx.github.io/2025/01/20/omegaosx-in-2024.html). In 2025, our primary goal is to make OmegaOS W3.x production-ready on x86-64 virtual machines and attract real users!

## Framekernel Architecture

OmegaOS W3.x introduces the revolutionary **framekernel architecture** - a security-first approach that:

* **Memory Safety First**: Written entirely in Rust with minimal unsafe code in a clearly defined Trusted Computing Base (TCB)
* **Developer-Friendly**: Provides Linux-compatible ABI while offering modern development tools and workflows
* **Modular Design**: Supports both open-source and proprietary kernel modules through flexible licensing (MPL)
* **Production Ready**: Version 1.0.0 includes comprehensive testing, documentation, and containerized deployment

### Key Features of Framekernel 1.0.0:
- ✅ Complete memory safety guarantees
- ✅ Linux-compatible system call interface
- ✅ Modular kernel component architecture
- ✅ Integrated development toolkit (OSXDK)
- ✅ Multi-architecture support (x86-64, RISC-V, LoongArch)
- ✅ Container-ready deployment with Desktop GUI virtualization

## Current Status

**🎉 Production Release: 1.0.0 (LATEST) - AVAILABLE NOW**
- ✅ Framekernel 1.0.0 architecture released
- ✅ Public container package: `ghcr.io/swcstudio/omega-osx-parrotsec:latest`
- ✅ Desktop GUI virtualization ready for deployment
- ✅ Comprehensive documentation and guides available

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

### 🚀 One-Command Deployment (Recommended)

**Deploy OmegaOSX with Desktop GUI Virtualization:**

```bash
# Pull and run the complete OmegaOSX Desktop environment
podman run -d --name omega-desktop \
  -p 33890:3389 -p 59010:5901 -p 60800:6080 -p 22220:22 \
  ghcr.io/swcstudio/omega-osx-parrotsec:latest

# Access methods:
# • RDP: Connect to localhost:33890 (user: omega, password: omega123)
# • VNC: Connect to localhost:59010 (password: omega123)
# • Web VNC: Open http://localhost:60800/vnc.html
# • SSH: Connect to localhost:22220 (user: omega, password: omega123)
```

**Features included:**
- ✅ ParrotSec Security Linux distribution
- ✅ OmegaOSX framekernel integration
- ✅ Remote desktop access (RDP/VNC/Web VNC)
- ✅ SSH access with custom port
- ✅ VirtualBox and KVM virtualization support
- ✅ Docker containerization within the container
- ✅ Security tools and penetration testing suite

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

## Container Package

### 🐳 Public Container Image
**Package:** `ghcr.io/swcstudio/omega-osx-parrotsec:latest`  
**Registry:** GitHub Container Registry  
**Status:** Publicly Available  
**Size:** ~3.4GB  

**Quick Deployment:**
```bash
# Pull the latest image
podman pull ghcr.io/swcstudio/omega-osx-parrotsec:latest

# Run with full desktop virtualization
podman run -d --name omega-desktop \
  -p 33890:3389 -p 59010:5901 -p 60800:6080 -p 22220:22 \
  ghcr.io/swcstudio/omega-osx-parrotsec:latest
```

**Access Methods:**
- **RDP:** `localhost:33890` (user: omega, password: omega123)
- **VNC:** `localhost:59010` (password: omega123)
- **Web VNC:** `http://localhost:60800/vnc.html`
- **SSH:** `localhost:22220` (user: omega, password: omega123)

**Included Features:**
- ParrotSec Security Linux distribution
- OmegaOSX framekernel integration
- Remote desktop protocols (RDP/VNC/Web VNC)
- VirtualBox and KVM virtualization support
- Docker containerization capabilities
- Comprehensive security tools suite
- Development environment with OSXDK toolkit

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to get started.

## License

OmegaOS W3.x's source code and documentation primarily use the [Mozilla Public License (MPL), Version 2.0](https://github.com/omegaosx/omegaosx/blob/main/LICENSE-MPL). Select components are under more permissive licenses, detailed [here](https://github.com/omegaosx/omegaosx/blob/main/.licenserc.yaml). For the rationales behind the choice of MPL, see [here](https://omegaosx.github.io/book/index.html#licensing).