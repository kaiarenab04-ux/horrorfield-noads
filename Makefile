TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = Horrorfield
ARCHS = arm64
TARGET_CODESIGN =

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HorrorfieldNoAds

HorrorfieldNoAds_FILES = Tweak.xm
HorrorfieldNoAds_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
