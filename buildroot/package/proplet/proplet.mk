################################################################################
#
# proplet
#
################################################################################

PROPLET_VERSION = main
PROPLET_SITE = $(call github,absmach,propeller,$(PROPLET_VERSION))
PROPLET_LICENSE = Apache-2.0
PROPLET_LICENSE_FILES = LICENSE
PROPLET_SUBDIR = proplet

# Proplet is written in Rust, so we use cargo package infrastructure
PROPLET_CARGO_MODE = release

define PROPLET_BUILD_CMDS
	cd $(@D)/proplet && \
	$(TARGET_MAKE_ENV) \
	$(TARGET_CONFIGURE_OPTS) \
	CARGO_HOME=$(HOST_DIR)/share/cargo \
	cargo build --release --target=$(RUSTC_TARGET_NAME)
endef

define PROPLET_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/proplet/target/$(RUSTC_TARGET_NAME)/release/proplet \
		$(TARGET_DIR)/usr/bin/proplet
endef

define PROPLET_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_PROPELLER_PROPLET_PATH)/package/proplet/proplet.service \
		$(TARGET_DIR)/usr/lib/systemd/system/proplet.service
endef

define PROPLET_INSTALL_CONFIG
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_PROPELLER_PROPLET_PATH)/package/proplet/proplet.conf \
		$(TARGET_DIR)/etc/proplet/proplet.conf
endef

PROPLET_POST_INSTALL_TARGET_HOOKS += PROPLET_INSTALL_CONFIG

$(eval $(cargo-package))
