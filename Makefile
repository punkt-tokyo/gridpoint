APP_NAME = GridPoint
VERSION = 1.0.1
BUILD_DIR = build
ZIP_NAME = $(APP_NAME)-$(VERSION).zip
APP_PATH = $(BUILD_DIR)/$(APP_NAME).xcarchive/Products/Applications/$(APP_NAME).app
NOTARY_PROFILE = GridPointNotary

.PHONY: build archive zip notarize release clean

build:
	xcodebuild -scheme $(APP_NAME) -configuration Release -derivedDataPath $(BUILD_DIR)

archive:
	xcodebuild -scheme $(APP_NAME) -configuration Release \
		-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive archive

zip: archive
	cd $(BUILD_DIR)/$(APP_NAME).xcarchive/Products/Applications && \
		zip -r ../../../../$(ZIP_NAME) $(APP_NAME).app
	shasum -a 256 $(ZIP_NAME)

# Submit the zip to Apple for notarization, staple the ticket onto the .app,
# then repackage. Requires a keychain profile named $(NOTARY_PROFILE), created
# once via:
#   xcrun notarytool store-credentials GridPointNotary \
#       --apple-id <apple-id> --team-id MLW8563CF7 --password <app-specific-password>
release: zip
	xcrun notarytool submit $(ZIP_NAME) --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple $(APP_PATH)
	rm -f $(ZIP_NAME)
	cd $(BUILD_DIR)/$(APP_NAME).xcarchive/Products/Applications && \
		zip -r ../../../../$(ZIP_NAME) $(APP_NAME).app
	shasum -a 256 $(ZIP_NAME)

clean:
	rm -rf $(BUILD_DIR) $(ZIP_NAME)
