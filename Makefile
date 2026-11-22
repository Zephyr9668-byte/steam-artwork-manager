# Either "linux" or "darwin", windows is built via mstools atm
OS_NAME := $(shell uname -s | tr A-Z a-z)
ARCH := $(shell uname -m)
VERSION := $(shell awk -F'"' '/define VERSION/{print $$2}' steam-artwork-manager.c)

ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

USER_LIB_PATH := /usr/lib
ifdef FLATPAK_BUILDER_BUILDDIR
USER_LIB_PATH := /app/lib
endif

PKG_CONFIG ?= pkg-config

all: build

.PHONY: build
build: build-$(OS_NAME)
	@echo "Built for target: $(OS_NAME)"
	
.PHONY: build-linux build-darwin
build-linux:
	$(CC) -O3 -g steam-artwork-manager.c curl-helper.c gui-helper-gtk.c string-helpers.c crc.c $(shell $(PKG_CONFIG) --cflags --libs gtk+-3.0 libcurl) -o steam-artwork-manager $(LDFLAGS)
	chmod +x steam-artwork-manager

build-darwin:
	mkdir -p steam-artwork-manager.app/Contents/MacOS
	mkdir -p steam-artwork-manager.app/Contents/Resources
	cp LICENSE steam-artwork-manager.app/Contents/Resources/LICENSE.txt
	cp res/mac/AppIcon.icns steam-artwork-manager.app/Contents/Resources/AppIcon.icns
	cp res/mac/Assets.car steam-artwork-manager.app/Contents/Resources/Assets.car
	cp res/mac/Info.plist steam-artwork-manager.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" steam-artwork-manager.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(VERSION)" steam-artwork-manager.app/Contents/Info.plist
	$(CC) -Wno-pointer-sign -fobjc-arc -arch arm64 -arch x86_64 -g steam-artwork-manager.c curl-helper.c gui-helper-mac.m string-helpers.c crc.c $(shell $(PKG_CONFIG) --cflags --libs libcurl) -framework Cocoa -o steam-artwork-manager.app/Contents/MacOS/steam-artwork-manager $(LDFLAGS)
	chmod +x steam-artwork-manager.app/Contents/MacOS/steam-artwork-manager

.PHONY: install install-linux install-flatpak
ifdef FLATPAK_BUILDER_BUILDDIR
install: install-flatpak
else
install: install-$(OS_NAME)
endif

install-linux: build
	install -Dm755 steam-artwork-manager -t $(DESTDIR)$(PREFIX)/bin
	desktop-file-install res/linux/com.steamgriddb.steam-artwork-manager.desktop --rebuild-mime-info-cache
	@su - $(SUDO_USER)
	xdg-mime default com.steamgriddb.steam-artwork-manager.desktop x-scheme-handler/sgdb

install-flatpak: build
	install -Dm644 res/linux/com.steamgriddb.steam-artwork-manager-flatpak.desktop /app/share/applications/com.steamgriddb.steam-artwork-manager.desktop
	install -Dm644 com.steamgriddb.steam-artwork-manager.appdata.xml -t /app/share/metainfo
	install -Dm755 steam-artwork-manager -t /app/bin
	install -Dm644 res/com.steamgriddb.steam-artwork-manager.svg -t /app/share/icons/hicolor/scalable/apps

.PHONY: dist
dist: build
	mkdir -p dist/
# if mac delete symbols before archiving
ifeq ($(OS_NAME),darwin)
	rm -r steam-artwork-manager.app/Contents/MacOS/*.dSYM
	ditto -c -k --keepParent $(shell $(MAKE) -s print-dists-darwin) dist/steam-artwork-manager-$(OS_NAME)-universal.zip
else
	mkdir -p dist/$(OS_NAME)
	cp $(shell $(MAKE) -s print-dists-$(OS_NAME)) dist/$(OS_NAME)/
	tar -czvf $(CURDIR)/dist/steam-artwork-manager-$(OS_NAME)-$(ARCH).tar.gz -C dist/$(OS_NAME) .
	rm -rf dist/$(OS_NAME)
endif

.PHONY: print-dists print-dists-linux print-dists-darwin
print-dists: print-dists-$(OS_NAME)

print-dists-linux:
	@echo "steam-artwork-manager" "LICENSE" "res/linux/com.steamgriddb.steam-artwork-manager.desktop" "res/linux/install.sh"

print-dists-darwin:
	@echo "steam-artwork-manager.app"

.PHONY: clean
clean:
	rm -rf steam-artwork-manager.app steam-artwork-manager dist