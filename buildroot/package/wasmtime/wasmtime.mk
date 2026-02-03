################################################################################
#
# wasmtime
#
################################################################################

WASMTIME_VERSION = 27.0.0
WASMTIME_SOURCE = wasmtime-v$(WASMTIME_VERSION)-$(WASMTIME_ARCH)-linux.tar.xz
WASMTIME_SITE = https://github.com/bytecodealliance/wasmtime/releases/download/v$(WASMTIME_VERSION)
WASMTIME_LICENSE = Apache-2.0
WASMTIME_LICENSE_FILES = LICENSE

# Map Buildroot architecture to Wasmtime architecture
ifeq ($(BR2_RISCV_64),y)
WASMTIME_ARCH = riscv64gc
else ifeq ($(BR2_aarch64),y)
WASMTIME_ARCH = aarch64
else ifeq ($(BR2_x86_64),y)
WASMTIME_ARCH = x86_64
else
$(error Unsupported architecture for wasmtime)
endif

define WASMTIME_EXTRACT_CMDS
	$(TAR) -xf $(WASMTIME_DL_DIR)/$(WASMTIME_SOURCE) -C $(@D) --strip-components=1
endef

define WASMTIME_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/wasmtime $(TARGET_DIR)/usr/bin/wasmtime
endef

$(eval $(generic-package))
