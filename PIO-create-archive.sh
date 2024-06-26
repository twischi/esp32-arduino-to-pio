#!/bin/bash

# Current SOURCE at GitHub
#   https://github.com/espressif/arduino-esp32/releases/tag/3.0.2

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
mkdir -p $OUT_PIO/cores/esp32
cp -rf $sourceCodePath/cores $OUT_PIO
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/tools/*       - FOLDER > to > <PIO-OUT>/tools
#-------------------------------------------------------------------------------
mkdir -p $OUT_PIO/tools
cp -rf $sourceCodePath/tools $OUT_PIO 
#   Remove *.exe files as they are not needed
    rm -f $OUT_PIO/tools/*.exe           # *.exe in Tools-Folder >> remove
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/libraries/*    - FOLDER > to > <PIO-OUT>/libraries
#-------------------------------------------------------------------------------
cp -rf $sourceCodePath/libraries $OUT_PIO
#-------------------------------------------------------------------------------
# PIO COPY <arduino-esp32>/variants/*     - FOLDER > to > <PIO-OUT>/variants
#-------------------------------------------------------------------------------
cp -rf $sourceCodePath/variants $OUT_PIO

#-------------------------------------------------------------------------------
# PIO COPY Single FILES from FULL SOURCE CODE of <arduino-esp32> to <PIO-OUT>
#-------------------------------------------------------------------------------
cp -f $fullSourceCodePath/CMakeLists.txt $OUT_PIO    # CMakeLists.txt (for CMake)
cp -f $fullSourceCodePath/Kconfig.projbuild $OUT_PIO # Kconfig.projbuild 
cp -f $fullSourceCodePath/package.json $OUT_PIO      # package.json (PIO Framework Manifest-File)
#cp -rf $fullSourceCodePath/idf_* $OUT_PIO            # idf.py

#-------------------------------------------------------------------------------
# PIO COPY <esp32-arduino-libs>/*        - FOLDER > to > <PIO-OUT>/tools
#-------------------------------------------------------------------------------
cp -rf $buildLibsPath $OUT_PIO/tools/
#------------------------------------------------------------------------------- 
# PIO modify <PIO-OUT>/tools//platformio-build.py 
# ...............................................................................
#   from: FRAMEWORK_LIBS_DIR = platform.get_package_dir("framework-arduinoespressif32-libs")
#   to:   FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")
#-------------------------------------------------------------------------------
echo -e "      ...modfied '/tools//platformio-build.py' for FRAMEWORK_LIBS_DIR"
searchLineBy='FRAMEWORK_LIBS_DIR ='
 replaceLine='FRAMEWORK_LIBS_DIR = join(FRAMEWORK_DIR, "tools", "esp32-arduino-libs")'
sed -i '' "/^$searchLineBy/s/.*/$replaceLine/" $OUT_PIO/tools/platformio-build.py

#-------------------------------------------------------------------------------------------
# EXTRACT Info from alreday copied   <PIO-OUT>/tools/esp32-arduino-libs/versions.txt - File
#-------------------------------------------------------------------------------------------
filePath=$OUT_PIO/tools/esp32-arduino-libs/versions.txt
IDF_BRANCH=$(grep "esp-idf:" $filePath | awk '{print $2}')   # esp-idf BRANCH
IDF_COMMIT=$(grep "esp-idf:" $filePath | awk '{print $3}')   # esp-idf COMMIT
AR_BRANCH=$(grep "arduino:" $filePath | awk '{print $2}')    # esp-idf BRANCH
AR_COMMIT=$(grep "arduino:" $filePath | awk '{print $3}')    # esp-idf COMMIT

#--------------------------------------------------------------
# CREATE release-info.txt > that will be added to PIO-Releae by https://github.com/twischi/platform-espressif32
#--------------------------------------------------------------
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) # Get current branch running Remote-Repository 
gitHubURL=$(git remote get-url origin)        # Get URL of running Remote-Repository 
IDF_REPO="espressif/esp-idf"                  # Source-Repository-Name of <esp-idf>
AR_REPO="espressif/arduino-esp32"             # Source-Repository-Name of <arduino-esp32>
#echo -e "      d) Creating release-info.txt used for publishing (creating...)"
#echo -e "         ...to: $(shortFP $OUT_PIO/)$eTG"release-info.txt"$eNO" 
cat <<EOL > "$OUT_PIO/../release-info.txt"
Framework built from resources:

-- $IDF_REPO
 * branch [$IDF_BRANCH]
   https://github.com/$IDF_REPO/tree/$IDF_BRANCH
 * commit [$IDF_COMMIT]
   https://github.com/$IDF_REPO/commits/$IDF_BRANCH/#:~:text=$IDF_COMMIT

-- $AR_REPO
 * branch [$AR_BRANCH]
   https://github.com/$AR_REPO/tree/$AR_BRANCH
 * commit [$AR_COMMIT]
   https://github.com/$AR_REPO/commits/$AR_BRANCH/#:~:text=$AR_COMMIT

Created with:
-- esp32-arduino-lib-builder
 * branch [$GIT_BRANCH]
   $gitHubURL
EOL
#--------------------------------------------------------------
# CREATE release-info.sh > that used import varialbe PIO-Releae by https://github.com/twischi/platform-espressif32
#--------------------------------------------------------------
#echo -e "         ...to: $(shortFP $OUT_PIO_Dist/)$eTG"pio-release-info.sh"$eNO"

pioIDF_verStr="$IDF_BRANCH_$IDF_COMMIT"         # Create IDF Version string

pioAR_verStr="$AR_BRANCH_$AR_COMMIT"            # Create AR Version from TAG

idfVersStr="$pioIDF_verStr-$pioAR_verStr"       # Create Version string
idfVersStr=${idfVersStr//\//_}                  # Replace '/' to '_' in string


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
rlVersionBuild="$idfVersStr"

# Version for PIO package.json:
rlVersionPkg="$(date +"%Y.%m.%d")"

# <esp-idf> - Used for the build:
rlIDF="$pioIDF_verStr"
rlIdfTag="$IDF_TAG"

# <arduino-esp32> - Used for the build:
rlAR="$pioAR_verStr"

# Build for this targets:
rlTagets="$targetsBuildList"
# -----------------------------------------------------
# Build with this <esp32-arduino-lib-builder>:
# -----------------------------------------------------
# $libBuildToolUrl
EOL
chmod +x $OUT_PIO_Dist/pio-release-info.sh


exit 0

OUT_PIO_Dist=$(realpath $OUT_PIO/../)/forRelease
#-----------------------------------------
# Message: Start Creating content
#-----------------------------------------
echo -e "      for Target(s):$eTG $TARGET $eNO"
echo -e "      a) Create PlatformIO 'framework-arduinoespressif32' from build (copying...)"
echo -e "         ...in: $(shortFP $OUT_PIO)"

#-----------------------------------------
# Message create archive
#-----------------------------------------
echo -e "      e) Creating Archive-File (compressing...)"
#---------------------------------------------------------
# Set variables for the archive file tar.gz or zip 
#---------------------------------------------------------
idfVersStr="$pioIDF_verStr-$pioAR_verStr"       # Create Version string
idfVersStr=${idfVersStr//\//_}                  # Remove '/' from string
pioArchFN="framework-arduinoespressif32-$idfVersStr.tar.gz"    # Name of the archive
echo -e "         ...in:            $(shortFP $OUT_PIO_Dist)"
echo -e "         ...arch-Filename:$eTG $pioArchFN $eNO"
pioArchFP="$OUT_PIO_Dist/$pioArchFN"                           # Full path of the archive
# ---------------------------------------------
# Create the Archive with tar
# ---------------------------------------------
cd $OUT_PIO/..         # Step to source-Folder
rm -f $pioArchFP       # Remove potential old file
mkdir -p $OUT_PIO_Dist # Make sure Folder exists
#          <target>     <source> in currtent dir 
tar -zcf $pioArchFP framework-arduinoespressif32/
cd $SH_ROOT            # Step back to script-Folder
# ---------------------------------------------
# Export Release-Info for git upload
# ---------------------------------------------
libBuildToolUrl=$(git remote get-url origin)
echo -e "      f) Create Relase-Info for git upload - File(creating...)"
# ..............................................
# Release-Info as text-file
# ..............................................
echo -e "         ...to: $(shortFP $OUT_PIO_Dist/)$eTG"pio-release-info.txt"$eNO"
targetsBuildList=$(cat $OUT_FOLDER/targetsBuildList.txt)
# Get list targets used for the build
rm -f $OUT_PIO_Dist/pio-release-info.txt  # Remove potential old file
cat <<EOL > $OUT_PIO_Dist/pio-release-info.txt
-----------------------------------------------------
PIO <framework-arduinoespressif32> 
-----------------------------------------------------
Filename:
$pioArchFN

Build-Tools-Version used in Filename:
$idfVersStr

Version for PIO package.json:
$(date +"%Y.%m.%d")

<esp-idf> - Used for the build:
$pioIDF_verStr

<arduino-esp32> - Used for the build:
$pioAR_verStr

Build for this targets:
$targetsBuildList
-----------------------------------------------------
Build with this <esp32-arduino-lib-builder>:
-----------------------------------------------------
$libBuildToolUrl
EOL


# ---------------------
echo -e "   PIO DONE!"
# ---------------------

# SUBSTITUTIONS
################
# cd out & '../components/arduino'    >>  $ArduionoCOMPS
#---
# cd out & 'tools/esp32-arduino-libs' >>  $AR_OWN_OUT/tools/esp32-arduino-libs
#---
# cd out & '..'                       >>  $SH_ROOT