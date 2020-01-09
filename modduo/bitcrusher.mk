######################################
#
# bitcrusher
#
######################################

# where to find the source code - locally in this case
BITCRUSHER_SITE_METHOD = local
BITCRUSHER_SITE = $($(PKG)_PKGDIR)/

# even though this is a local build, we still need a version number
# bump this number if you need to force a rebuild
BITCRUSHER_VERSION = 1

# dependencies (list of other buildroot packages, separated by space)
BITCRUSHER_DEPENDENCIES =

# LV2 bundles that this package generates (space separated list)
BITCRUSHER_BUNDLES = bitcrusher.lv2

# call make with the current arguments and path. "$(@D)" is the build directory.
BITCRUSHER_TARGET_MAKE = $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/source


# build command
define BITCRUSHER_BUILD_CMDS
	$(BITCRUSHER_TARGET_MAKE)
endef

# install command
define BITCRUSHER_INSTALL_TARGET_CMDS
	$(BITCRUSHER_TARGET_MAKE) install DESTDIR=$(TARGET_DIR)
endef


# import everything else from the buildroot generic package
$(eval $(generic-package))
