#!/bin/bash

# What and Where to download
TAG_NAME="3.0.2"
DOWNLOAD_DIR="/Users/thomas/ESP-Build/SHORTCut/DL-Resources"
REPO="espressif/arduino-esp32" 
# Create the download directory if it doesn't exist
rm -rf $DOWNLOAD_DIR && mkdir -p $DOWNLOAD_DIR

# Get release information including assets and source code URL
release_info=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$TAG_NAME")

# Step 1: Find the release by tag name and get the assets' download URLs
assets_urls=$(echo "$release_info" | jq -r '.assets[] | .browser_download_url')

# -------------------------------------------
# Download source code (tarball)
# -------------------------------------------
source_code_url=$(echo "$release_info" | jq -r '.tarball_url') 
source_code_filename="$TAG_NAME.tar.gz" 
echo && echo "SOURCE CODE" && echo
echo "--- Downloading source code..."
curl -sL "$source_code_url" -o "$DOWNLOAD_DIR/$source_code_filename"
# Extract the source code
echo "    +++ Extracting source code..."
tar -xzf "$DOWNLOAD_DIR/$source_code_filename" -C "$DOWNLOAD_DIR"
rm -f "$DOWNLOAD_DIR/$source_code_filename"
# Rename the extracted directory
echo -e "    +++ Renaming source code-Foder to 'arduino-esp32-fullSC'\n"
dirToRename=$(find $DOWNLOAD_DIR -maxdepth 1 -type d -name "espressif-arduino-esp32*" -print -quit)
mv $dirToRename "$DOWNLOAD_DIR/arduino-esp32-fullSC"

# -------------------------------------------
# Download Release-Assets-Files
# -------------------------------------------
echo "Downloading Release-Assets-Files for tag $TAG_NAME..." && echo
for url in $assets_urls; do
    filename=$(basename "$url") # Extract the filename from the URL
    filetype="${filename##*.}"
    if [ ! "$filetype" = "json" ]; then  # Skip the JSON files
       echo "--- Downloading $filename ..."
       curl -sL "$url" -o "$DOWNLOAD_DIR/$filename" # Download the file to the specified directory
        if [ "$filetype" = "zip" ]; then  # When the file is a ZIP archive
            echo "    +++ Extracting $filename for Folder..."
            unzip -q "$DOWNLOAD_DIR/$filename" -d "$DOWNLOAD_DIR" # Extract the ZIP archive
            rm -f "$DOWNLOAD_DIR/$filename" # Remove the ZIP archive
            folderNameUnpacked="${filename%.*}" 
            if [[ $folderNameUnpacked == "esp32-$TAG_NAME" ]]; then  # Check if name indicates <arduino-esp32> 
                # Then it this <arduino-esp32> of the Release related to the TAG
                echo "    +++ Renamin $folderNameUnpacked to 'arduino-esp32'"
                mv $DOWNLOAD_DIR/$folderNameUnpacked "$DOWNLOAD_DIR/arduino-esp32" # Rename the created Folder
            fi
            echo
        fi
    fi
done
echo "Download completed." && echo

