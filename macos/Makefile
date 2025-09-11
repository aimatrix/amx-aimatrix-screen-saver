# Makefile for Digital Rain Screen Saver (merged from NewMakefile)

TARGET = aimatrix
VERSION = 7.7
BUNDLE_NAME = aimatrix-v$(VERSION).saver
SOURCES = AIMatrixView.m AIMatrixConfig.m

# GPU Version 8.0 Configuration
GPU_TARGET = aimatrix-gpu
GPU_VERSION = 8.0
GPU_BUNDLE_NAME = aimatrix-gpu-v$(GPU_VERSION).saver
GPU_SOURCES = AIMatrixGPUView.m

INSTALL_DIR = ~/Library/Screen\ Savers
CODESIGN_IDENTITY = "Apple Development: VINCENT LEE (5GKJMFZD6T)"

CC_FLAGS = -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 -O2 -fobjc-arc

all: $(BUNDLE_NAME)

# GPU-accelerated version target
gpu: $(GPU_BUNDLE_NAME)

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
		-framework OpenGL \
		-framework GLUT \
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

# GPU Version 8.0 Build Rule
$(GPU_BUNDLE_NAME): $(GPU_SOURCES) InfoGPU.plist
	@echo "Building AIMatrix GPU Screen Saver v$(GPU_VERSION)..."
	@mkdir -p $(GPU_BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(GPU_BUNDLE_NAME)/Contents/Resources
	
	# Compile GPU version with Metal frameworks
	clang $(CC_FLAGS) \
		-bundle \
		-o $(GPU_BUNDLE_NAME)/Contents/MacOS/$(GPU_TARGET) \
		-framework ScreenSaver \
		-framework Cocoa \
		-framework QuartzCore \
		-framework Metal \
		-framework MetalKit \
		-framework CoreText \
		$(GPU_SOURCES)
	
	# Copy GPU Info.plist
	cp InfoGPU.plist $(GPU_BUNDLE_NAME)/Contents/Info.plist
	
	# Copy thumbnail images for preview in System Settings
	@if [ -f thumbnail.png ]; then cp thumbnail.png $(GPU_BUNDLE_NAME)/Contents/Resources/; fi
	@if [ -f thumbnail@2x.png ]; then cp thumbnail@2x.png $(GPU_BUNDLE_NAME)/Contents/Resources/; fi
	
	# Sign the GPU bundle with hardened runtime and entitlements
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		$(GPU_BUNDLE_NAME)
	
	@echo "GPU Screen saver built and signed successfully: $(GPU_BUNDLE_NAME)"
	@echo "This version uses TRUE GPU acceleration with Metal for ultra-smooth 60 FPS!"

install: $(BUNDLE_NAME)
	@echo "Installing to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@echo "Cleaning up ALL previous versions..."
	@rm -rf $(INSTALL_DIR)/aimatrix*.saver
	@rm -rf $(INSTALL_DIR)/AIMatrix*.saver
	@rm -rf /Library/Screen\ Savers/aimatrix*.saver || true
	@rm -rf /Library/Screen\ Savers/AIMatrix*.saver || true
	@cp -r $(BUNDLE_NAME) $(INSTALL_DIR)/
	@echo "Installation complete!"
	@echo "If System Settings is open, please quit it and reopen after install."
	@echo "Go to System Settings > Screen Saver and pick 'aimatrix-v$(VERSION)'"

# GPU Version Install
install-gpu: $(GPU_BUNDLE_NAME)
	@echo "Installing GPU version to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@echo "Cleaning up ALL previous versions..."
	@rm -rf $(INSTALL_DIR)/aimatrix*.saver
	@rm -rf $(INSTALL_DIR)/AIMatrix*.saver
	@rm -rf /Library/Screen\ Savers/aimatrix*.saver || true
	@rm -rf /Library/Screen\ Savers/AIMatrix*.saver || true
	@cp -r $(GPU_BUNDLE_NAME) $(INSTALL_DIR)/
	@echo "GPU Installation complete!"
	@echo "If System Settings is open, please quit it and reopen after install."
	@echo "Go to System Settings > Screen Saver and pick 'AIMatrix GPU v$(GPU_VERSION)'"
	@echo "This version uses TRUE GPU acceleration with Metal!"

uninstall:
	@echo "Removing installed aimatrix screen savers..."
	@rm -rf $(INSTALL_DIR)/aimatrix-v*.saver
	@rm -rf /Library/Screen\ Savers/aimatrix-v*.saver || true
	@echo "Done."

clean:
	@rm -rf $(BUNDLE_NAME)
	@rm -rf $(GPU_BUNDLE_NAME)
	@rm -rf *.saver
	@echo "Cleaned build artifacts"

# Test screen savers for debugging
ForceDrawTest.saver: ForceDrawTest.m ForceDrawTest.plist
	@echo "Building ForceDrawTest..."
	@mkdir -p ForceDrawTest.saver/Contents/MacOS
	@mkdir -p ForceDrawTest.saver/Contents/Resources
	clang $(CC_FLAGS) -bundle -o ForceDrawTest.saver/Contents/MacOS/ForceDrawTest \
		-framework ScreenSaver -framework Cocoa ForceDrawTest.m
	cp ForceDrawTest.plist ForceDrawTest.saver/Contents/Info.plist
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		ForceDrawTest.saver
	@echo "ForceDrawTest.saver built"

TestFall.saver: TestFall.m
	@echo "Building TestFall..."
	@mkdir -p TestFall.saver/Contents/MacOS
	@mkdir -p TestFall.saver/Contents/Resources
	clang $(CC_FLAGS) -bundle -o TestFall.saver/Contents/MacOS/TestFall \
		-framework ScreenSaver -framework Cocoa TestFall.m
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > TestFall.saver/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> TestFall.saver/Contents/Info.plist
	@echo '<plist version="1.0"><dict>' >> TestFall.saver/Contents/Info.plist
	@echo '<key>CFBundleIdentifier</key><string>com.test.testfall</string>' >> TestFall.saver/Contents/Info.plist
	@echo '<key>CFBundleName</key><string>TestFall</string>' >> TestFall.saver/Contents/Info.plist
	@echo '<key>NSPrincipalClass</key><string>TestFall</string>' >> TestFall.saver/Contents/Info.plist
	@echo '</dict></plist>' >> TestFall.saver/Contents/Info.plist
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		TestFall.saver
	@echo "TestFall.saver built"

MetalMatrix.saver: MetalMatrixView.m MetalMatrix.plist
	@echo "Building MetalMatrix..."
	@mkdir -p MetalMatrix.saver/Contents/MacOS
	@mkdir -p MetalMatrix.saver/Contents/Resources
	clang $(CC_FLAGS) -bundle -o MetalMatrix.saver/Contents/MacOS/MetalMatrix \
		-framework ScreenSaver -framework Cocoa -framework Metal -framework MetalKit \
		MetalMatrixView.m
	cp MetalMatrix.plist MetalMatrix.saver/Contents/Info.plist
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		MetalMatrix.saver
	@echo "MetalMatrix.saver built"

install-test: ForceDrawTest.saver TestFall.saver MetalMatrix.saver
	@echo "Installing test screen savers..."
	@cp -r ForceDrawTest.saver $(INSTALL_DIR)/
	@cp -r TestFall.saver $(INSTALL_DIR)/
	@cp -r MetalMatrix.saver $(INSTALL_DIR)/
	@echo "Test screen savers installed"

# Variants version
AIMatrixVariants.saver: AIMatrixVariantsView.m VariantsInfo.plist
	@echo "Building AIMatrix Variants Screen Saver..."
	@mkdir -p AIMatrixVariants.saver/Contents/MacOS
	@mkdir -p AIMatrixVariants.saver/Contents/Resources
	clang $(CC_FLAGS) -bundle -o AIMatrixVariants.saver/Contents/MacOS/AIMatrixVariants \
		-framework ScreenSaver -framework Cocoa \
		AIMatrixVariantsView.m
	cp VariantsInfo.plist AIMatrixVariants.saver/Contents/Info.plist
	codesign --force --deep --strict --verbose \
		--sign $(CODESIGN_IDENTITY) \
		--entitlements ScreenSaver.entitlements \
		--options runtime \
		--timestamp \
		AIMatrixVariants.saver
	@echo "AIMatrixVariants.saver built"

install-variants: AIMatrixVariants.saver
	@echo "Installing AIMatrix Variants..."
	@cp -r AIMatrixVariants.saver $(INSTALL_DIR)/
	@echo "AIMatrix Variants installed!"
	@echo "Go to System Settings > Screen Saver and select 'AIMatrix Variants'"

.PHONY: all gpu install install-gpu uninstall clean install-test install-variants
