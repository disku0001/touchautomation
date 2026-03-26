ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TouchSpoof

TouchSpoof_FILES = Tweak.x
TouchSpoof_CFLAGS = -fobjc-arc
TouchSpoof_FRAMEWORKS = CoreLocation UIKit CoreTelephony CoreMotion AdSupport WebKit
TouchSpoof_PRIVATE_FRAMEWORKS = MobileGestalt
TouchSpoof_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += touchspoofprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
