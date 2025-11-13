# Accelerate OS development with OmegaOS W3.x OSXDK

[![Crates.io](https://img.shields.io/crates/v/cargo-osxdk.svg)](https://crates.io/crates/cargo-osxdk)
[![OSXDK Test](https://github.com/swcstudio/omegaosx/actions/workflows/osxdk_test.yml/badge.svg?event=push)](https://github.com/swcstudio/omegaosx/actions/workflows/osxdk_test.yml)

### What is it?

OSXDK (short for Operating System Development Kit) is designed to simplify the development of Rust operating systems. It aims to streamline the process by leveraging the framekernel architecture, proposed by OmegaOS W3.x.

`cargo-osxdk` is a command-line tool that facilitates project management for those developed on the framekernel architecture. Much like Cargo for Rust projects, `cargo-osxdk` enables building, running, and testing projects conveniently.

### Install the tool

#### Requirements

Currently, `cargo-osxdk` only supports x86_64 ubuntu system. 

To run a kernel with QEMU, `cargo-osxdk` requires the following tools to be installed: 
- Rust >= 1.75.0
- cargo-binutils
- gcc
- qemu-system-x86_64
- grub-mkrescue
- ovmf 
- xorriso

About how to install Rust, you can refer to the [official site](https://www.rust-lang.org/tools/install).

After installing Rust, you can install Cargo tools by
```bash
cargo install cargo-binutils
```

Other tools can be installed by
```bash
apt install build-essential grub2-common qemu-system-x86 ovmf xorriso
```

#### Install 

Then, `cargo-osxdk` can be installed by
```bash
cargo install cargo-osxdk
``` 

#### Upgrade

If `cargo-osxdk` is already installed, the tool can be upgraded by
```bash
cargo install --force cargo-osxdk
```

### Getting started

Here we provide a simple demo to demonstrate how to create and run a simple kernel with `cargo-osxdk`.

With `cargo-osxdk`, a kernel project can be created by one command
```bash
cargo osxdk new --kernel my-first-os
```

Then, you can run the kernel with
```bash
cd my-first-os && cargo osxdk run
```

You will see `Hello world from guest kernel!` from your console. 

### Basic usage

The basic usage of `cargo-osxdk` is
```bash
cargo osxdk <COMMAND>
```
Currently we support following commands:
- **new**: Create a new kernel package or library package
- **build**: Compile the project and its dependencies
- **run**: Run the kernel with a VMM
- **debug**: Debug a remote target via GDB
- **test**: Execute kernel mode unit test by starting a VMM
- **check**: Analyze the current package and report errors
- **clippy**: Check the current package and catch common mistakes
- **doc**: Build Rust documentations

The following command can be used to discover the available options for each command.
```bash
cargo osxdk help <COMMAND>
```

### The OSXDK manifest

`cargo-osxdk` utilizes a configuration file named `OSXDK.toml` to define its precise behavior. To learn more about the manifest specification, please refer to [the book](https://omegaosx.github.io/book/osxdk/reference/manifest.html).

### Contributing

OmegaOS W3.x OSXDK is developed as a sub-project of OmegaOS W3.x(https://github.com/swcstudio/omegaosx). It shares the same repository and versioning rules with the kernel. Please contribute to OSXDK according to the contribution guide of OmegaOS W3.x.

#### Note for Visual Studio Code users

To enable advanced features of the editor on OSXDK, please open the OmegaOS W3.x repository as a workspace using the `File > Open Workspace from File...` menu entry, and select the file `.code-workspace` in the OmegaOS W3.x repository root as the configuration.
