# Desktop GUI Virtualization Guide

This guide covers the deployment and usage of OmegaOSX with Desktop GUI Virtualization using our public container package.

## Overview

OmegaOSX Desktop GUI Virtualization provides a complete, containerized desktop environment with:
- **ParrotSec Security Linux** distribution
- **OmegaOSX Framekernel** integration
- **Multiple access methods** (RDP, VNC, Web VNC, SSH)
- **Virtualization support** (VirtualBox, KVM)
- **Security tools** and penetration testing suite

## Quick Start

### One-Command Deployment

Deploy the complete OmegaOSX Desktop environment:

```bash
podman run -d --name omega-desktop \\
  -p 33890:3389 -p 59010:5901 -p 60800:6080 -p 22220:22 \\
  ghcr.io/swcstudio/omega-osx-parrotsec:latest
```

### Access Methods

| Protocol | Port | URL/Command | Credentials |
|----------|------|-------------|-------------|
| **RDP** | 33890 | `rdp://localhost:33890` | user: `omega`, password: `omega123` |
| **VNC** | 59010 | `vnc://localhost:59010` | password: `omega123` |
| **Web VNC** | 60800 | `http://localhost:60800/vnc.html` | No auth required |
| **SSH** | 22220 | `ssh -p 22220 omega@localhost` | user: `omega`, password: `omega123` |

## Detailed Setup

### Prerequisites

- **Podman** or **Docker** installed
- **x86-64 Linux** machine
- **4GB+ RAM** recommended
- **10GB+ disk space** for container

### Step-by-Step Deployment

1. **Pull the container image:**
   ```bash
   podman pull ghcr.io/swcstudio/omega-osx-parrotsec:latest
   ```

2. **Run with custom configuration:**
   ```bash
   podman run -d \\
     --name omega-desktop \\
     --privileged \\
     --network=host \\
     --device=/dev/kvm \\
     -p 33890:3389 \\
     -p 59010:5901 \\
     -p 60800:6080 \\
     -p 22220:22 \\
     -v omega-work:/home/omega/work \\
     -v omega-vms:/var/lib/libvirt/images \\
     ghcr.io/swcstudio/omega-osx-parrotsec:latest
   ```

3. **Wait for services to start** (30-60 seconds)

4. **Access the desktop environment** using any of the methods above

## Features and Capabilities

### Security Tools
The container includes ParrotSec's comprehensive security toolkit:
- **Network Analysis**: Wireshark, nmap, netcat
- **Web Application Security**: Burp Suite, OWASP ZAP
- **Forensics**: Autopsy, Sleuth Kit
- **Cryptography**: John the Ripper, Hashcat
- **System Security**: Lynis, ClamAV

### Virtualization Support
- **KVM**: Full virtualization support with hardware acceleration
- **VirtualBox**: Complete VirtualBox installation
- **Docker**: Nested containerization support
- **QEMU**: Emulation and virtualization tools

### Development Environment
- **OmegaOSX Framekernel**: Integrated kernel development environment
- **OSXDK Toolkit**: Complete development toolchain
- **Rust Toolchain**: Latest Rust compiler and tools
- **VS Code**: Pre-installed for development

## Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USER` | `omega` | Primary username |
| `PASSWORD` | `omega123` | User password |
| `VNC_PORT` | `59010` | VNC server port |
| `RDP_PORT` | `33890` | RDP server port |
| `DISPLAY` | `:1` | X11 display number |

### Volume Mounts

```bash
# Persistent workspace
-v /path/to/work:/home/omega/work

# Virtual machine storage
-v /path/to/vms:/var/lib/libvirt/images

# VirtualBox VMs
-v /path/to/virtualbox:/var/lib/virtualbox
```

### Network Configuration

```bash
# Custom network (recommended for production)
--network omega-net

# Host network (for development)
--network=host

# Port mapping (required)
-p 33890:3389 -p 59010:5901 -p 60800:6080 -p 22220:22
```

## Troubleshooting

### Container Won't Start
- **Check port conflicts**: Ensure ports 33890, 59010, 60800, 22220 are available
- **Verify KVM support**: Run `ls /dev/kvm` to check KVM device
- **Check permissions**: Ensure user has Docker/Podman permissions

### Desktop Connection Issues
- **Wait longer**: Services take 30-60 seconds to fully start
- **Check logs**: `podman logs omega-desktop`
- **Verify services**: `podman exec omega-desktop netstat -tulpn`

### Performance Issues
- **Allocate more memory**: Add `--memory=4g` to container run command
- **Enable KVM**: Ensure `--device=/dev/kvm` is specified
- **Use host network**: Add `--network=host` for better performance

## Advanced Usage

### Custom Startup Script
Create a custom startup script:

```bash
#!/bin/bash
# custom-startup.sh

echo "Starting OmegaOSX Desktop with custom configuration..."

# Start additional services
service postgresql start
service apache2 start

# Run custom applications
/opt/custom-app/start.sh

# Keep container running
tail -f /dev/null
```

Then run with custom entrypoint:
```bash
podman run -d \\
  --entrypoint /path/to/custom-startup.sh \\
  ghcr.io/swcstudio/omega-osx-parrotsec:latest
```

### Multi-Container Setup
For production environments, consider separating services:

```bash
# Database container
podman run -d --name omega-db postgres:13

# Application container
podman run -d \\
  --name omega-app \\
  --link omega-db:db \\
  ghcr.io/swcstudio/omega-osx-parrotsec:latest
```

## Security Considerations

### Default Credentials
**Change default passwords in production:**
```bash
# Inside container
passwd omega
vncpasswd
```

### Network Security
- Use VPN for remote access
- Configure firewall rules
- Consider reverse proxy for web access
- Enable SSL/TLS where possible

### Container Security
- Run with minimal privileges
- Use read-only filesystems where possible
- Regularly update the container image
- Scan for vulnerabilities

## Performance Optimization

### Resource Allocation
```bash
# CPU and memory limits
--cpus=2 --memory=4g

# I/O optimization
--storage-opt size=20G
```

### Graphics Performance
- Use hardware acceleration when available
- Configure VNC for optimal compression
- Consider SPICE protocol for better performance

## Next Steps

- Explore the [OmegaOSX Framekernel Documentation](../kernel/the-framekernel-architecture.html)
- Learn about [OSXDK Development Tools](../osxdk/guide/index.html)
- Join our [Community Discussions](https://github.com/omegaosx/omegaosx/discussions)
- Report issues on [GitHub Issues](https://github.com/omegaosx/omegaosx/issues)

---

**Package Information:**
- **Image**: `ghcr.io/swcstudio/omega-osx-parrotsec:latest`
- **Registry**: GitHub Container Registry
- **Size**: ~3.4GB
- **Status**: Publicly Available
- **Last Updated**: November 18, 2025