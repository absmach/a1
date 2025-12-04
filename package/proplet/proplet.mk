################################################################################
#
# proplet
#
################################################################################

PROPLET_VERSION = main
PROPLET_SITE = $(call github,absmach,propeller,$(PROPLET_VERSION))
PROPLET_LICENSE = Apache-2.0
PROPLET_LICENSE_FILES = LICENSE
PROPLET_DEPENDENCIES = wamr libcurl openssl zlib

# If Proplet is written in Go
PROPLET_GOMOD = github.com/absmach/propeller

define PROPLET_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		GOOS=linux GOARCH=riscv64 \
		-C $(@D) proplet
endef

define PROPLET_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/proplet \
		$(TARGET_DIR)/usr/bin/proplet
	$(INSTALL) -D -m 0644 $(@D)/configs/proplet.toml \
		$(TARGET_DIR)/etc/proplet/proplet.toml
endef

$(eval $(golang-package))