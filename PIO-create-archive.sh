#!/bin/bash

# Current SOURCE at GitHub
#   https://github.com/espressif/arduino-esp32/releases/tag/3.0.2

clear       # Clear the screen
#------------------------------------------------------------------------------
# Define the colors for the echo output
#------------------------------------------------------------------------------
export eBL="\x1B[34m"   # echo Color (blue) for Files that are executed or used
export eRD="\x1B[31m"   # echo Color (Red) for Targets
export eNO="\x1B[0m"    # Back to    (Black)
# Start Message
echo -e "      START the Script to create PIO - Release"

# -------------------------------
# HELPERSs
# -------------------------------
oneUpDir=$(realpath $(pwd)/../)        # DIR above the current directory

# -------------------------------
# PIO Folder for OUTPUT 
# -------------------------------
OUT_PIO=$oneUpDir/PIO-Out/framework-arduinoespressif32  # Set path to the PIO-Folder 
[ -d "$OUT_PIO" ] && rm -rf "$OUT_PIO" # Remove old folder if exists
mkdir -p $OUT_PIO # Make sure Folder exists
echo -e "...   Output-Folder: $eRD$OUT_PIO$eNO"

# -------------------------------
# Set she SOURCE Folders
# -------------------------------
# The Folders with the Sources expected 1-Level-above-the-current Directory  > $oneUpDir
sourceFolderName="DL-Resources" # Set the name of the Downloaded Resourcees
# ..............................................
# <arduino-esp32> = All the Source Codes from the 'arduino-esp32' repository the Arduino Framework
# ..............................................
sourceCodePath=$oneUpDir/$sourceFolderName/arduino-esp32
# ..............................................
# <esp32-arduino-libs> = All the Pre-Compiled Libraries for targets (=ESP32 Chip-Variants, eg. esp32h2, esp32s2, esp32)
# ..............................................
buildLibsPath=$oneUpDir/$sourceFolderName/esp32-arduino-libs
# ..............................................
# FULL SourceCode of <arduino-esp32> what is 'Source code (zip)' in the latest release
# ..............................................
fullSourceCodePath=$oneUpDir/$sourceFolderName/arduino-esp32-fullSC
find "$fullSourceCodePath" -mindepth 1 -type d -exec rm -rf {} \;  # Delete ALL Sub-Directories of FULL SourceCode
find "$fullSourceCodePath" -type f -name ".*" -exec rm {} \;       # Delete All Hidden-Files in Root-Folder
find "$fullSourceCodePath" -type f -name "*.md" -exec rm {} \;     # Delete All MarkDown-Files in Root-Folder
find "$fullSourceCodePath" -type f -name "*.yml" -exec rm {} \;    # Delete All YAML-File sin Root-Folder

#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/cores/esp32/* - FOLDER > to > <PIO-OUT>/cores/esp32
#-------------------------------------------------------------------------------
echo -e "\n***   Copy from <arduino-esp32>"
mkdir -p $OUT_PIO/cores/esp32 && echo -e "      ...  /cores/esp32/*  to  <PIO-OUT>"
cp -rf $sourceCodePath/cores $OUT_PIO
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/tools/*       - FOLDER > to > <PIO-OUT>/tools
#-------------------------------------------------------------------------------
mkdir -p $OUT_PIO/tools && echo -e "      ...  /tools/*        to  <PIO-OUT>/tools"
cp -rf $sourceCodePath/tools $OUT_PIO 
#   Remove *.exe files as they are not needed
    rm -f $OUT_PIO/tools/*.exe           # *.exe in Tools-Folder >> remove
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/libraries/*    - FOLDER > to > <PIO-OUT>/libraries
#-------------------------------------------------------------------------------
echo -e "      ...  /libraries/*    to  <PIO-OUT>/libraries"
cp -rf $sourceCodePath/libraries $OUT_PIO
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/variants/*     - FOLDER > to > <PIO-OUT>/variants
#-------------------------------------------------------------------------------
echo -e "      ...  variants/*      to  <PIO-OUT>/variants"
cp -rf $sourceCodePath/variants $OUT_PIO

#-------------------------------------------------------------------------------
# PIO COPY Single FILES from FULL SOURCE CODE of <arduino-esp32> to <PIO-OUT>
#-------------------------------------------------------------------------------
echo -e   "***   Copy single files from <arduino-esp32>-Full-Source-Code  to   <PIO-OUT>"
echo -e   "      ...  CMakeLists.txt\n      ...  Kconfig.projbuild\n      ...  package.json"
cp -f $fullSourceCodePath/CMakeLists.txt $OUT_PIO    # CMakeLists.txt (for CMake)
cp -f $fullSourceCodePath/Kconfig.projbuild $OUT_PIO # Kconfig.projbuild 
cp -f $fullSourceCodePath/package.json $OUT_PIO      # package.json (PIO Framework Manifest-File)
#cp -rf $fullSourceCodePath/idf_* $OUT_PIO            # idf.py

#-------------------------------------------------------------------------------
# PIO COPY <esp32-arduino-libs>/*        - FOLDER > to > <PIO-OUT>/tools
#-------------------------------------------------------------------------------
echo -e   "***   Copy from <esp32-arduino-libs>"
echo -e   "      ...          /*      to  <PIO-OUT>/tools"
cp -rf $buildLibsPath $OUT_PIO/tools/
#------------------------------------------------------------------------------- 
# PIO modify <PIO-OUT>/tools//platformio-build.py 
# ...............................................................................
#   from: FRAMEWORK_LIBS_DIR = platform.get_package_dir("framework-arduinoespressif32-libs")
#   to:   FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")
#-------------------------------------------------------------------------------
echo -e "      modfied <PIO-OUT>/tools//platformio-build.py FOR FRAMEWORK_LIBS_DIR"
searchLineBy='FRAMEWORK_LIBS_DIR ='
 replaceLine='FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")'
sed -i '' "/^$searchLineBy/s/.*/$replaceLine/" $OUT_PIO/tools/platformio-build.py

#-------------------------------------------------------------------------------------------
# EXTRACT Info from alreday copied   <PIO-OUT>/tools/esp32-arduino-libs/versions.txt - File
#-------------------------------------------------------------------------------------------
echo -e "\n***   EXTRACT Commits from <PIO-OUT>/tools/esp32-arduino-libs/versions.txt"
filePath=$OUT_PIO/tools/esp32-arduino-libs/versions.txt
IDF_BRANCH=$(grep "esp-idf:" $filePath | awk '{print $2}')   # esp-idf BRANCH
IDF_COMMIT=$(grep "esp-idf:" $filePath | awk '{print $3}')   # esp-idf COMMIT
AR_BRANCH=$(grep "arduino:" $filePath | awk '{print $2}')    # esp-idf BRANCH
AR_COMMIT=$(grep "arduino:" $filePath | awk '{print $3}')    # esp-idf COMMIT

# -------------------------------------------------------------------
# Get the latest TAG of the <esp-idf> Repository by the given COMMIT
# --------------------------------------------------------------------
# WHAT is needed?
#   The IDF_COMMIT is given, used for bulding the <arduino-esp32> Framework
#   >>  What is the latest TAG related to this COMMIT?
# Why is TAG needed?
#    >> A TAG is needed and used for Releases 
#       (TAGS are a point in time of a Repository-state)
#    >> This TAG is used to point at download link for the esp-idf in the PIO-
echo -e   "***   Get the latest TAG of the <esp-idf> Repository by the given COMMIT"
IDF_PATH_OWN="/Users/thomas/ESP-Build/twischi-Dev4GitHub/GitHub-Sources/esp-idf" # Local Path to the <esp-idf> Repository
git -C $IDF_PATH_OWN fetch --all --quiet    # Update Repository to latest state
git -C $IDF_PATH_OWN pull  > /dev/null 2>&1 # Pull the latest changes
IDF_TAG=$(git -C $IDF_PATH_OWN describe --tags --abbrev=0 $COMMIT)
echo -e "      ...  <esp-idf>-TAG:       $eRD$IDF_TAG$eNO"
# -------------------------------------------------------------------
# Get the TAG of the <arduino-esp32> Repository used for Framework 
# --------------------------------------------------------------------
# WHAT is needed?
#   TAG of the <arduino-esp32>-Repository used to build the libs
# Why is TAG needed?
#    >> A TAG is needed have a sensfull PIO Release Info & Naming
# Where to find the TAG?
#   >> The TAG in package.json 
#      at: <PIO-OUT>/package.json
#               '{"name": "framework-arduinoespressif32",
#                 "version": "3.0.2",'
echo -e   "***   Get the TAG of the <arduino-esp32> Repository used for Framework"
fileJson="$OUT_PIO/package.json" # Path to the JSON-File
jqPath=".version"                                            # Path to the value in JSON-File
AR_TAG=$(jq -r $jqPath "$fileJson")                        # Read current value
echo -e "      ...  <arduino-esp32>-TAG: $eRD$AR_TAG$eNO"

#-------------------------------------------------------------------------------------------
# Get list of targets that has been build
#-------------------------------------------------------------------------------------------
# How to get the list of targets?
#   >> The list of targets is the list of all sub-folders in the <esp32-arduino-libs>-Folder
#-------------------------------------------------------------------------------------------
echo -e   "***   Get the list of Targets form <esp32-arduino-libs>-Folder"
targetsList=$(find $buildLibsPath -mindepth 1 -maxdepth 1 -type d -print | sed 's/.*\///' | paste -sd "," -) # Comma-List of Target = Folders
targetsList="${targetsList//,/,\ }" # Prettiyfy the list with ', ' between the targets instald of pure ',' 
echo -e "      ...  Targets: $eRD$targetsList$eNO"

#---------------------------------------------------------
# Set/generate variables for the PIO-Release archive 
#---------------------------------------------------------
echo -e "\n***   Set/generate variables for the PIO-Release archive"
OUT_PIO_Relase=$(realpath $OUT_PIO/../)       # Path to the PIO-Release Folder
# ... Version strings for the archive
pioIDF_verStr="IDF_$IDF_TAG"                  # Create IDF     Version string based on TAG
pioAR_verStr="AR_$AR_TAG"                     # Create AR      Version string based on TAG
relVersStr="$pioAR_verStr-$pioIDF_verStr"     # Create Release Version string, what is combined of above
relVersStr=${relVersStr//\//_}                # Replace '/' to '_' in string (not really needed here)
# ... Filname Name and FN with Path of the archive
pioArchFN="framework-arduinoespressif32-$relVersStr.tar.gz"  # Name of the archive file tar.gz or zip
pioArchFP="$OUT_PIO_Relase/$pioArchFN"                       # Full path of the archive
# ... This tool
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)                # Get current branch running Remote-Repository 
gitHubURL=$(git remote get-url origin | sed 's/\.git$//')    # Get URL of running Remote-Repository

# ... Source-Repository-Names 
IDF_REPO="espressif/esp-idf"                  # Source-Repository-Name of <esp-idf>
AR_REPO="espressif/arduino-esp32"             # Source-Repository-Name of <arduino-esp32>

#--------------------------------------------------------------
# CREATE release-info.sh > that used import varialbe PIO-Releae by https://github.com/twischi/platform-espressif32
#--------------------------------------------------------------
echo -e   "***   CREATE$eRD release-info.sh $eNO\n      > this is used to import variables when releae PIO"
rm -f $OUT_PIO/../pio-release-info.sh  # Remove potential old file
cat <<EOL > "$OUT_PIO/../pio-release-info.sh"
#!/bin/bash
# ---------------------------------------------------
# PIO <framework-arduinoespressif32> 
# ---------------------------------------------------
# This *.sh is called by 
#    https://github.com/twischi/platform-espressif32
# to set varibles used to release this build version
# ---------------------------------------------------
# Filename:
rlFN="$pioArchFN"

# Build-Tools-Version used in Filename:
rlVersionBuild="$relVersStr"

# Version for PIO-package:
rlVersionPkg="$(date +"%Y.%m.%d")"

# <arduino-esp32> - Used for the build:
rlAR="$pioAR_verStr"
rlArTag="$AR_TAG"

# <esp-idf> - Used for the build:
rlIDF="$pioIDF_verStr"
rlIdfTag="$IDF_TAG"

# Build for this targets:
rlTagets="$targetsList"
# ---------------------------------------------------
# Created with:
# ---------------------------------------------------
# $gitHubURL
EOL
chmod +x $OUT_PIO_Relase/pio-release-info.sh

#--------------------------------------------------------------
# CREATE release-info.txt > that will be added to PIO-Releae by https://github.com/twischi/platform-espressif32
#--------------------------------------------------------------
#echo -e "      d) Creating release-info.txt used for publishing (creating...)"
#echo -e "         ...to: $(shortFP $OUT_PIO/)$eTG"release-info.txt"$eNO" 
echo -e   "***   CREATE$eRD release-info.txt $eNO\n      > this is later added to Release-package"
cat <<EOL > "$OUT_PIO_Relase/release-info.txt"
Framework built from resources:

-- $IDF_REPO
 * tag [$IDF_TAG]
   https://github.com/$IDF_REPO/releases/tag/$IDF_TAG
 * branch [$IDF_BRANCH]
   https://github.com/$IDF_REPO/tree/$IDF_BRANCH
 * commit [$IDF_COMMIT]
   https://github.com/$IDF_REPO/commits/$IDF_BRANCH/#:~:text=$IDF_COMMIT

-- $AR_REPO
 * tag [$AR_TAG]
   https://github.com/$AR_REPO/releases/tag/$AR_TAG
 * branch [$AR_BRANCH]
   https://github.com/$AR_REPO/tree/$AR_BRANCH
 * commit [$AR_COMMIT]
   https://github.com/$AR_REPO/commits/$AR_BRANCH/#:~:text=$AR_COMMIT

Created with:
 $gitHubURL
 * branch [$GIT_BRANCH]
EOL

# ---------------------------------------------
# Create the Archive with tar
# ---------------------------------------------
echo -e "\n***   CREATE Archive-File (takes a while...)"
savedPWD=$(pwd)          # Save current working directory
cd $OUT_PIO/..           # Step to source-Folder
rm -f $pioArchFP         # Remove potential old file
mkdir -p $OUT_PIO_Relase # Make sure Folder exists
#          <target>       <source> in currtent dir 
tar -zcf $pioArchFP framework-arduinoespressif32/
cd $savedPWD              # Step back to script-Folder
echo -e "      ...  Created: $eRD$pioArchFN$eNO"

# ---------------------
echo -e "\n PIO DONE!\n"
# ---------------------

# ################################################################
# WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP WiP 
# ################################################################

# ################################################################
