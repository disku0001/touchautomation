include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TouchSpoofApp

TouchSpoofApp_FILES = main.m TSAppDelegate.m TSMainViewController.m TSRRSViewController.m TSAppleIDViewController.m TSAccountsViewController.m TSSettingsViewController.m TSProxyManager.m TSDeviceManager.m TSAppManager.m
TouchSpoofApp_FRAMEWORKS = UIKit CoreLocation CoreTelephony AdSupport
TouchSpoofApp_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-function -Wno-deprecated-declarations
TouchSpoofApp_CODESIGN_FLAGS = -Sentitlements.plist
TouchSpoofApp_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
