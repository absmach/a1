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

PROPLET_LDFLAGS = -s -w

define PROPLET_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(HOST_GO_TARGET_ENV) \
		CGO_ENABLED=0 \
		$(HOST_DIR)/bin/go build -v -o $(@D)/proplet \
		-ldflags "$(PROPLET_LDFLAGS)" \
		$(PROPLET_SITE_METHOD)://$(PROPLET_SITE)/proplet
endef

define PROPLET_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/proplet $(TARGET_DIR)/usr/bin/proplet
endef

# Install init script if systemd or sysvinit
define PROPLET_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_PROPELLER_PROPLET_PATH)/package/proplet/proplet.service \
		$(TARGET_DIR)/usr/lib/systemd/system/proplet.service
endef

define PROPLET_INSTALL_CONFIG
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_PROPELLER_PROPLET_PATH)/package/proplet/proplet.conf \
		$(TARGET_DIR)/etc/proplet.conf
endef

PROPLET_POST_INSTALL_TARGET_HOOKS += PROPLET_INSTALL_CONFIG

$(eval $(golang-package))