################################################################################
#
# proplet - Propeller edge worker (RISC-V compatible)
#
################################################################################

PROPLET_VERSION = main
PROPLET_SITE = $(call github,absmach,propeller,$(PROPLET_VERSION))
PROPLET_LICENSE = Apache-2.0
PROPLET_LICENSE_FILES = LICENSE

PROPLET_GOMOD = github.com/absmach/propeller

# Dependencies - minimal for edge device
PROPLET_DEPENDENCIES = \
	wasmtime \
	host-pkgconf \
	openssl \
	ca-certificates

# CGO enabled for Wasmtime integration
PROPLET_GO_ENV = CGO_ENABLED=1

# Build flags from Propeller Makefile
PROPLET_TIME = $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
PROPLET_LDFLAGS = -s -w \
	-X 'github.com/absmach/supermq.BuildTime=$(PROPLET_TIME)' \
	-X 'github.com/absmach/supermq.Version=$(PROPLET_VERSION)' \
	-X 'github.com/absmach/supermq.Commit=$(PROPLET_VERSION)'

# PKG_CONFIG for Wasmtime cross-compilation
PROPLET_GO_ENV += \
	PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \
	PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)"

# Build proplet binary only
# Following Makefile: cmd/proplet/main.go -> build/proplet
define PROPLET_BUILD_CMDS
	mkdir -p $(@D)/build && \
	cd $(@D) && \
	$(TARGET_MAKE_ENV) \
	$(PROPLET_GO_ENV) \
	GOOS=linux \
	GOARCH=riscv64 \
	CC=$(TARGET_CC) \
	CXX=$(TARGET_CXX) \
	CGO_CFLAGS="$(TARGET_CFLAGS)" \
	CGO_LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib" \
	$(GO_BIN) build \
		-ldflags "$(PROPLET_LDFLAGS)" \
		-o $(@D)/build/proplet \
		./cmd/proplet/main.go
endef

# Install binary and configuration
define PROPLET_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/proplet \
		$(TARGET_DIR)/usr/bin/proplet
	
	# Install default configuration template
	$(INSTALL) -D -m 0644 $(PROPLET_PKGDIR)/proplet.env \
		$(TARGET_DIR)/etc/proplet/proplet.env
	
	# Create directories
	mkdir -p $(TARGET_DIR)/var/lib/proplet/wasm-cache
	mkdir -p $(TARGET_DIR)/var/log/proplet
endef

# Install systemd service
define PROPLET_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(PROPLET_PKGDIR)/proplet.service \
		$(TARGET_DIR)/usr/lib/systemd/system/proplet.service
endef

# Create proplet user
define PROPLET_USERS
	proplet -1 proplet -1 * /var/lib/proplet - - Propeller Proplet
endef

$(eval $(golang-package))
