################################################################################
#
# wasmtime - WebAssembly runtime for RISC-V
#
################################################################################

WASMTIME_VERSION = v27.0.0
WASMTIME_SITE = $(call github,bytecodealliance,wasmtime,$(WASMTIME_VERSION))
WASMTIME_LICENSE = Apache-2.0
WASMTIME_LICENSE_FILES = LICENSE

WASMTIME_DEPENDENCIES = host-rustc

# Cargo environment for cross-compilation
WASMTIME_CARGO_ENV = \
	CARGO_HOME=$(HOST_DIR)/share/cargo \
	RUSTFLAGS="$(TARGET_RUSTFLAGS)" \
	CC=$(TARGET_CC) \
	CXX=$(TARGET_CXX) \
	AR=$(TARGET_AR) \
	CARGO_TARGET_RISCV64GC_UNKNOWN_LINUX_GNU_LINKER=$(TARGET_CC)

# RISC-V target triple
WASMTIME_CARGO_TARGET = riscv64gc-unknown-linux-gnu

# Build options
WASMTIME_CARGO_OPTS = \
	--target=$(WASMTIME_CARGO_TARGET) \
	--release \
	--manifest-path=$(@D)/Cargo.toml

# Build both CLI and C API
define WASMTIME_BUILD_CMDS
	$(WASMTIME_CARGO_ENV) \
		cargo build $(WASMTIME_CARGO_OPTS) \
			--package wasmtime-cli \
			--package wasmtime-c-api
endef

# Install binaries and libraries
define WASMTIME_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 \
		$(@D)/target/$(WASMTIME_CARGO_TARGET)/release/wasmtime \
		$(TARGET_DIR)/usr/bin/wasmtime
	
	$(INSTALL) -D -m 0755 \
		$(@D)/target/$(WASMTIME_CARGO_TARGET)/release/libwasmtime.so \
		$(TARGET_DIR)/usr/lib/libwasmtime.so
endef

# Install to staging for proplet linking
define WASMTIME_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 \
		$(@D)/target/$(WASMTIME_CARGO_TARGET)/release/libwasmtime.so \
		$(STAGING_DIR)/usr/lib/libwasmtime.so
	
	mkdir -p $(STAGING_DIR)/usr/include/wasmtime
	if [ -d "$(@D)/crates/c-api/include" ]; then \
		cp -r $(@D)/crates/c-api/include/* \
			$(STAGING_DIR)/usr/include/wasmtime/; \
	fi
endef

WASMTIME_INSTALL_STAGING = YES

$(eval $(generic-package))
