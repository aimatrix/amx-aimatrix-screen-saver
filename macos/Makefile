# Makefile for Digital Rain Screen Saver (merged from NewMakefile)

TARGET = aimatrix
BUNDLE_NAME = aimatrix-v5.24.saver
SOURCES = AIMatrixView.m
INSTALL_DIR = ~/Library/Screen\ Savers
CODESIGN_IDENTITY = "Apple Development: VINCENT LEE (5GKJMFZD6T)"

CC_FLAGS = -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 -O2 -fobjc-arc

all: $(BUNDLE_NAME)

$(BUNDLE_NAME): $(SOURCES) NewInfo.plist
	@echo "Building AIMatrix Screen Saver..."
	@mkdir -p $(BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(BUNDLE_NAME)/Contents/Resources
	
	# Compile Objective-C files
	clang $(CC_FLAGS) \
		-bundle \
		-o $(BUNDLE_NAME)/Contents/MacOS/$(TARGET) \
		-framework ScreenSaver \
		-framework Cocoa \
		$(SOURCES)
	
	# Copy Info.plist
	cp NewInfo.plist $(BUNDLE_NAME)/Contents/Info.plist
	
	# Copy thumbnail images for preview in System Settings
	@if [ -f thumbnail.png ]; then cp thumbnail.png $(BUNDLE_NAME)/Contents/Resources/; fi
	@if [ -f thumbnail@2x.png ]; then cp thumbnail@2x.png $(BUNDLE_NAME)/Contents/Resources/; fi
	
	# Sign the bundle with hardened runtime and entitlements
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		$(BUNDLE_NAME)
	
	@echo "Screen saver built and signed successfully: $(BUNDLE_NAME)"

install: $(BUNDLE_NAME)
	@echo "Installing to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@echo "Cleaning up previous aimatrix versions..."
	@rm -rf $(INSTALL_DIR)/aimatrix-v*.saver
	@rm -rf /Library/Screen\ Savers/aimatrix-v*.saver || true
	@rm -rf $(INSTALL_DIR)/$(BUNDLE_NAME)
	@cp -r $(BUNDLE_NAME) $(INSTALL_DIR)/
	@echo "Installation complete!"
	@echo "If System Settings is open, please quit it and reopen after install."
	@echo "Go to System Settings > Screen Saver and pick 'aimatrix v5.24'"

uninstall:
	@echo "Removing installed aimatrix screen savers..."
	@rm -rf $(INSTALL_DIR)/aimatrix-v*.saver
	@rm -rf /Library/Screen\ Savers/aimatrix-v*.saver || true
	@echo "Done."

clean:
	@rm -rf $(BUNDLE_NAME)
	@echo "Cleaned build artifacts"

.PHONY: all install uninstall clean
