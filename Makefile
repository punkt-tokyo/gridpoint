APP_NAME = GridPoint
VERSION = 1.0.0
BUILD_DIR = build
ZIP_NAME = $(APP_NAME)-$(VERSION).zip

.PHONY: build archive zip clean

build:
	xcodebuild -scheme $(APP_NAME) -configuration Release -derivedDataPath $(BUILD_DIR)

archive:
	xcodebuild -scheme $(APP_NAME) -configuration Release \
		-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive archive

zip: archive
	cd $(BUILD_DIR)/$(APP_NAME).xcarchive/Products/Applications && \
		zip -r ../../../../$(ZIP_NAME) $(APP_NAME).app
	shasum -a 256 $(ZIP_NAME)

clean:
	rm -rf $(BUILD_DIR) $(ZIP_NAME)
