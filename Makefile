# SPDX-License-Identifier: MPL-2.0

# =========================== Makefile options. ===============================

# Global build options.
OSXDK_TARGET_ARCH ?= x86_64
BENCHMARK ?= none
BOOT_METHOD ?= grub-rescue-iso
BOOT_PROTOCOL ?= multiboot2
BUILD_SYSCALL_TEST ?= 0
ENABLE_KVM ?= 1
INTEL_TDX ?= 0
MEM ?= 8G
OVMF ?= on
RELEASE ?= 0
RELEASE_LTO ?= 0
LOG_LEVEL ?= error
SCHEME ?= ""
SMP ?= 1
OSTD_TASK_STACK_SIZE_IN_PAGES ?= 64
FEATURES ?=
NO_DEFAULT_FEATURES ?= 0
COVERAGE ?= 0
ENABLE_BASIC_TEST ?= false
# End of global build options.

# GDB debugging and profiling options.
GDB_TCP_PORT ?= 1234
GDB_PROFILE_FORMAT ?= flame-graph
GDB_PROFILE_COUNT ?= 200
GDB_PROFILE_INTERVAL ?= 0.1
# End of GDB options.

# The Makefile provides a way to run arbitrary tests in the kernel
# mode using the kernel command line.
# Here are the options for the auto test feature.
AUTO_TEST ?= none
EXTRA_BLOCKLISTS_DIRS ?= ""
SYSCALL_TEST_WORKDIR ?= /tmp
# End of auto test features.

# Network settings
# NETDEV possible values are user,tap
NETDEV ?= user
VHOST ?= off
# The name server listed by /etc/resolv.conf inside the OmegaOS W3.x VM
DNS_SERVER ?= none
# End of network settings

# ========================= End of Makefile options. ==========================

SHELL := /bin/bash

CARGO_OSXDK := ~/.cargo/bin/cargo-osxdk

# Common arguments for `$(CARGO_OSXDK)` `build`, `run` and `test` commands.
CARGO_OSXDK_COMMON_ARGS := --target-arch=$(OSXDK_TARGET_ARCH)
# The build arguments also apply to the `$(CARGO_OSXDK) osdk run` command.
CARGO_OSXDK_BUILD_ARGS := --kcmd-args="osxtd.log_level=$(LOG_LEVEL)"
CARGO_OSXDK_TEST_ARGS :=

ifeq ($(AUTO_TEST), syscall)
BUILD_SYSCALL_TEST := 1
CARGO_OSXDK_BUILD_ARGS += --kcmd-args="SYSCALL_TEST_SUITE=$(SYSCALL_TEST_SUITE)"
CARGO_OSXDK_BUILD_ARGS += --kcmd-args="SYSCALL_TEST_WORKDIR=$(SYSCALL_TEST_WORKDIR)"
CARGO_OSXDK_BUILD_ARGS += --kcmd-args="EXTRA_BLOCKLISTS_DIRS=$(EXTRA_BLOCKLISTS_DIRS)"
CARGO_OSXDK_BUILD_ARGS += --init-args="/opt/syscall_test/run_syscall_test.sh"
else ifeq ($(AUTO_TEST), test)
ENABLE_BASIC_TEST := true
	ifneq ($(SMP), 1)
		CARGO_OSXDK_BUILD_ARGS += --kcmd-args="BLOCK_UNSUPPORTED_SMP_TESTS=1"
	endif
CARGO_OSXDK_BUILD_ARGS += --kcmd-args="INTEL_TDX=$(INTEL_TDX)"
CARGO_OSXDK_BUILD_ARGS += --init-args="/test/run_general_test.sh"
else ifeq ($(AUTO_TEST), boot)
ENABLE_BASIC_TEST := true
CARGO_OSXDK_BUILD_ARGS += --init-args="/test/boot_hello.sh"
else ifeq ($(AUTO_TEST), vsock)
ENABLE_BASIC_TEST := true
export VSOCK=on
CARGO_OSXDK_BUILD_ARGS += --init-args="/test/run_vsock_test.sh"
endif

ifeq ($(RELEASE_LTO), 1)
CARGO_OSXDK_COMMON_ARGS += --profile release-lto
OSTD_TASK_STACK_SIZE_IN_PAGES = 8
else ifeq ($(RELEASE), 1)
CARGO_OSXDK_COMMON_ARGS += --release
	ifeq ($(OSXDK_TARGET_ARCH), riscv64)
	# FIXME: Unwinding in RISC-V seems to cost more stack space, so we increase
	# the stack size for it. This may need further investigation.
	# See https://github.com/swcstudio/omegaosx/pull/2383#discussion_r2307673156
	OSTD_TASK_STACK_SIZE_IN_PAGES = 16
	else
	OSTD_TASK_STACK_SIZE_IN_PAGES = 8
	endif
endif

# If the BENCHMARK is set, we will run the benchmark in the kernel mode.
ifneq ($(BENCHMARK), none)
CARGO_OSXDK_BUILD_ARGS += --init-args="/benchmark/common/bench_runner.sh $(BENCHMARK) omegaosx"
endif

ifeq ($(INTEL_TDX), 1)
BOOT_METHOD = grub-qcow2
BOOT_PROTOCOL = linux-efi-handover64
CARGO_OSXDK_COMMON_ARGS += --scheme tdx
endif

ifeq ($(BOOT_PROTOCOL), linux-legacy32)
BOOT_METHOD = qemu-direct
OVMF = off
else ifeq ($(BOOT_PROTOCOL), multiboot)
BOOT_METHOD = qemu-direct
OVMF = off
endif

ifeq ($(SCHEME), "")
	ifeq ($(OSXDK_TARGET_ARCH), riscv64)
	SCHEME = riscv
	else ifeq ($(OSXDK_TARGET_ARCH), loongarch64)
	SCHEME = loongarch
	endif
endif

ifneq ($(SCHEME), "")
CARGO_OSXDK_COMMON_ARGS += --scheme $(SCHEME)
else
CARGO_OSXDK_COMMON_ARGS += --boot-method="$(BOOT_METHOD)"
endif

ifeq ($(COVERAGE), 1)
CARGO_OSXDK_COMMON_ARGS += --coverage
endif

ifdef FEATURES
CARGO_OSXDK_COMMON_ARGS += --features="$(FEATURES)"
endif
ifeq ($(NO_DEFAULT_FEATURES), 1)
CARGO_OSXDK_COMMON_ARGS += --no-default-features
endif

# To test the linux-efi-handover64 boot protocol, we need to use Debian's
# GRUB release, which is installed in /usr/bin in our Docker image.
ifeq ($(BOOT_PROTOCOL), linux-efi-handover64)
CARGO_OSXDK_COMMON_ARGS += --grub-mkrescue=/usr/bin/grub-mkrescue --grub-boot-protocol="linux"
else ifeq ($(BOOT_PROTOCOL), linux-efi-pe64)
CARGO_OSXDK_COMMON_ARGS += --grub-boot-protocol="linux"
else ifeq ($(BOOT_PROTOCOL), linux-legacy32)
CARGO_OSXDK_COMMON_ARGS += --linux-x86-legacy-boot --grub-boot-protocol="linux"
else
CARGO_OSXDK_COMMON_ARGS += --grub-boot-protocol=$(BOOT_PROTOCOL)
endif

ifeq ($(ENABLE_KVM), 1)
	ifeq ($(OSXDK_TARGET_ARCH), x86_64)
		CARGO_OSXDK_COMMON_ARGS += --qemu-args="-accel kvm"
	endif
endif

# Skip GZIP to make encoding and decoding of initramfs faster
ifeq ($(INITRAMFS_SKIP_GZIP),1)
CARGO_OSXDK_INITRAMFS_OPTION := --initramfs=$(abspath test/build/initramfs.cpio)
CARGO_OSXDK_COMMON_ARGS += $(CARGO_OSXDK_INITRAMFS_OPTION)
endif

CARGO_OSXDK_BUILD_ARGS += $(CARGO_OSXDK_COMMON_ARGS)
CARGO_OSXDK_TEST_ARGS += $(CARGO_OSXDK_COMMON_ARGS)

# Pass make variables to all subdirectory makes
export

# Basically, non-OSXDK crates do not depend on Omega Frame and can be checked
# or tested without OSXDK.
NON_OSXDK_CRATES := osxtd/libs/align_ext \
osxtd/libs/id-alloc \
osxtd/libs/linux-bzimage/builder \
osxtd/libs/linux-bzimage/boot-params \
osxtd/libs/osxtd-macros \
osxtd/libs/osxtd-test \
kernel/libs/omega-rights \
kernel/libs/omega-rights-proc \
kernel/libs/atomic-integer-wrapper \
kernel/libs/cpio-decoder \
kernel/libs/int-to-c-enum \
kernel/libs/int-to-c-enum/derive \
kernel/libs/jhash \
kernel/libs/keyable-arc \
kernel/libs/logo-ascii-art \
kernel/libs/typeflags \
kernel/libs/typeflags-util

# In contrast, OSXDK crates depend on OSXTD (or being `osxtd` itself)
# and need to be built or tested with OSXDK.
OSXDK_CRATES := \
osxdk/deps/frame-allocator \
osxdk/deps/heap-allocator \
osxdk/deps/test-kernel \
osxtd \
osxtd/libs/linux-bzimage/setup \
kernel \
kernel/comps/block \
kernel/comps/console \
kernel/comps/framebuffer \
kernel/comps/input \
kernel/comps/keyboard \
kernel/comps/network \
kernel/comps/softirq \
kernel/comps/systree \
kernel/comps/logger \
kernel/comps/mlsdisk \
kernel/comps/time \
kernel/comps/virtio \
kernel/comps/pci \
kernel/libs/omega-util \
kernel/libs/omega-bigtcp \
kernel/libs/xarray

# OSXDK dependencies
OSXDK_SRC_FILES := \
	$(shell find osxdk/Cargo.toml osxdk/Cargo.lock osxdk/src -type f)

.PHONY: all
all: build

# Install or update OSXDK from source
# To uninstall, do `cargo uninstall cargo-osxdk`
.PHONY: install_osxdk
install_osxdk:
	@# The `OSXDK_LOCAL_DEV` environment variable is used for local development
	@# without the need to publish the changes of OSXDK's self-hosted
	@# dependencies to `crates.io`.
	@OSXDK_LOCAL_DEV=1 cargo install cargo-osxdk --path osxdk

# This will install and update OSXDK automatically
$(CARGO_OSXDK): $(OSXDK_SRC_FILES)
	@$(MAKE) --no-print-directory install_osxdk

.PHONY: check_osxdk
check_osxdk:
	@cd osxdk && cargo clippy -- -D warnings

.PHONY: test_osxdk
test_osxdk:
	@cd osxdk && \
		OSXDK_LOCAL_DEV=1 cargo build && \
		OSXDK_LOCAL_DEV=1 cargo test

.PHONY: check_vdso
check_vdso:
	@# Checking `VDSO_LIBRARY_DIR` environment variable
	@if [ -z "$(VDSO_LIBRARY_DIR)" ]; then \
		echo "Error: the \$(VDSO_LIBRARY_DIR) environment variable must be given."; \
		echo "    This variable points to a directory that provides Linux's vDSO files,"; \
		echo "    which is required to build OmegaOS W3.x. Search for VDSO_LIBRARY_DIR"; \
		echo "    in OmegaOS W3.x's Dockerfile for more information."; \
		exit 1; \
	fi

.PHONY: initramfs
initramfs: check_vdso
	@$(MAKE) --no-print-directory -C test

.PHONY: build
build: $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk build $(CARGO_OSXDK_BUILD_ARGS)


.PHONY: tools
tools:
	@cd kernel/libs/comp-sys && cargo install --path cargo-component

.PHONY: run
run: initramfs $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk run $(CARGO_OSXDK_BUILD_ARGS)
# Check the running status of auto tests from the QEMU log
ifeq ($(AUTO_TEST), syscall)
	@tail --lines 100 qemu.log | grep -q "^All syscall tests passed." \
		|| (echo "Syscall test failed" && exit 1)
else ifeq ($(AUTO_TEST), test)
	@tail --lines 100 qemu.log | grep -q "^All general tests passed." \
		|| (echo "General test failed" && exit 1)
else ifeq ($(AUTO_TEST), boot)
	@tail --lines 100 qemu.log | grep -q "^Successfully booted." \
		|| (echo "Boot test failed" && exit 1)
else ifeq ($(AUTO_TEST), vsock)
	@tail --lines 100 qemu.log | grep -q "^Vsock test passed." \
		|| (echo "Vsock test failed" && exit 1)
endif

.PHONY: gdb_server
gdb_server: initramfs $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk run $(CARGO_OSXDK_BUILD_ARGS) --gdb-server wait-client,vscode,addr=:$(GDB_TCP_PORT)

.PHONY: gdb_client
gdb_client: initramfs $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk debug $(CARGO_OSXDK_BUILD_ARGS) --remote :$(GDB_TCP_PORT)

.PHONY: profile_server
profile_server: initramfs $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk run $(CARGO_OSXDK_BUILD_ARGS) --gdb-server addr=:$(GDB_TCP_PORT)

.PHONY: profile_client
profile_client: initramfs $(CARGO_OSXDK)
	@cd kernel && $(CARGO_OSXDK) osdk profile $(CARGO_OSXDK_BUILD_ARGS) --remote :$(GDB_TCP_PORT) \
		--samples $(GDB_PROFILE_COUNT) --interval $(GDB_PROFILE_INTERVAL) --format $(GDB_PROFILE_FORMAT)

.PHONY: test
test:
	@for dir in $(NON_OSXDK_CRATES); do \
		(cd $$dir && cargo test) || exit 1; \
	done

.PHONY: ktest
ktest: initramfs $(CARGO_OSXDK)
	@# Exclude linux-bzimage-setup from ktest since it's hard to be unit tested
	@for dir in $(OSXDK_CRATES); do \
		[ $$dir = "osxtd/libs/linux-bzimage/setup" ] && continue; \
		echo "[make] Testing $$dir"; \
		(cd $$dir && $(CARGO_OSXDK) osdk test $(CARGO_OSXDK_TEST_ARGS)) || exit 1; \
		tail --lines 10 qemu.log | grep -q "^\\[ktest runner\\] All crates tested." \
			|| (echo "Test failed" && exit 1); \
	done

.PHONY: docs
docs: $(CARGO_OSXDK)
	@for dir in $(NON_OSXDK_CRATES); do \
		(cd $$dir && cargo doc --no-deps) || exit 1; \
	done
	@for dir in $(OSXDK_CRATES); do \
		(cd $$dir && $(CARGO_OSXDK) osdk doc --no-deps) || exit 1; \
	done

.PHONY: book
book:
	@cd book && mdbook build

.PHONY: format
format:
	@./tools/format_all.sh
	@$(MAKE) --no-print-directory -C test format

.PHONY: check
check: initramfs $(CARGO_OSXDK)
	@# Check formatting issues of the Rust code
	@./tools/format_all.sh --check
	@
	@# Check if the combination of NON_OSXDK_CRATES and OSXDK_CRATES is the
	@# same as all workspace members
	@sed -n '/^\[workspace\]/,/^\[.*\]/{/members = \[/,/\]/p}' Cargo.toml | \
		grep -v "members = \[" | tr -d '", \]' | \
		sort > /tmp/all_crates
	@echo $(NON_OSXDK_CRATES) $(OSXDK_CRATES) | tr ' ' '\n' | sort > /tmp/combined_crates
	@diff -B /tmp/all_crates /tmp/combined_crates || \
		(echo "Error: The combination of NON_OSXDK_CRATES and OSXDK_CRATES" \
			"is not the same as all workspace members" && exit 1)
	@rm /tmp/all_crates /tmp/combined_crates
	@
	@# Check if all workspace members enable workspace lints
	@for dir in $(NON_OSXDK_CRATES) $(OSXDK_CRATES); do \
		if [[ "$$(tail -2 $$dir/Cargo.toml)" != "[lints]"$$'\n'"workspace = true" ]]; then \
			echo "Error: Workspace lints in $$dir are not enabled"; \
			exit 1; \
		fi \
	done
	@
	@# Check compilation of the Rust code
	@for dir in $(NON_OSXDK_CRATES); do \
		echo "Checking $$dir"; \
		(cd $$dir && cargo clippy -- -D warnings) || exit 1; \
	done
	@for dir in $(OSXDK_CRATES); do \
		echo "Checking $$dir"; \
		# Exclude linux-bzimage-setup since it only supports x86-64 currently and will panic \
		# in other architectures. \
		[ "$$dir" = "osxtd/libs/linux-bzimage/setup" ] && [ "$(OSXDK_TARGET_ARCH)" != "x86_64" ] && continue; \
		(cd $$dir && $(CARGO_OSXDK) osdk clippy -- -- -D warnings) || exit 1; \
	done
	@
	@# Check formatting issues of the C code (regression tests)
	@$(MAKE) --no-print-directory -C test check
	@
	@# Check typos
	@typos

.PHONY: clean
clean:
	@echo "Cleaning up OmegaOS W3.x workspace target files"
	@cargo clean
	@echo "Cleaning up OSXDK workspace target files"
	@cd osxdk && cargo clean
	@echo "Cleaning up mdBook output files"
	@cd book && mdbook clean
	@echo "Cleaning up test target files"
	@$(MAKE) --no-print-directory -C test clean
	@echo "Uninstalling OSXDK"
	@rm -f $(CARGO_OSXDK)