TARGET := iphone:clang:latest:14.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = RGBX
RGBX_FILES = Tweak.x
RGBX_CFLAGS = -fobjc-arc
RGBX_LDFLAGS = -Wl,-undefined,dynamic_lookup
include $(THEOS_MAKE_PATH)/tweak.mk
