TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = Horrorfield
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HorrorfieldNoAds

HorrorfieldNoAds_FILES = Tweak.xm
HorrorfieldNoAds_CFLAGS = -fobjc-arc
HorrorfieldNoAds_USE_SUBSTRATE = 0

include $(THEOS_MAKE_PATH)/tweak.mk
