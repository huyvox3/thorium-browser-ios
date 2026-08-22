#!/bin/bash

# Thorium for iOS Build Environment Setup Script
# MUST BE RUN ON A MAC RUNNING macOS WITH XCODE INSTALLED

YEL='\033[1;33m' # Yellow
CYA='\033[1;96m' # Cyan
RED='\033[1;31m' # Red
GRE='\033[1;32m' # Green
c0='\033[0m' # Reset Text
bold='\033[1m' # Bold Text

# Error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "${RED}Failed $*"; }

# 1. OS check
if [ "$(uname)" != "Darwin" ]; then
    printf "${RED}${bold}ERROR: This script must be run on macOS (Darwin).${c0}\n"
    printf "${YEL}Chromium for iOS requires Xcode and Apple SDKs, which are only available on macOS.${c0}\n"
    exit 1
fi

# 2. Disk space check
free_space=$(df -g . | awk 'NR==2 {print $4}')
if [ "$free_space" -lt 100 ]; then
    printf "${RED}${bold}WARNING: You have only ${free_space}GB of free disk space.${c0}\n"
    printf "${YEL}Building Chromium for iOS requires at least 100-120GB of free space.${c0}\n"
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. Define workspace paths
WORK_DIR="$(pwd)"
CHROMIUM_DIR="$WORK_DIR/chromium"
DEPOT_TOOLS_DIR="$WORK_DIR/depot_tools"

printf "${CYA}===============================================${c0}\n"
printf "${bold}${GRE}Setting up Thorium-iOS Build Directory${c0}\n"
printf "${CYA}Workspace: $WORK_DIR${c0}\n"
printf "${CYA}===============================================${c0}\n\n"

# 4. Install depot_tools if not present
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    printf "${YEL}Cloning depot_tools...${c0}\n"
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR" || die "Failed to clone depot_tools"
else
    printf "${GRE}depot_tools already exists.${c0}\n"
fi

# Export depot_tools to PATH
export PATH="$DEPOT_TOOLS_DIR:$PATH"
export PATH="$DEPOT_TOOLS_DIR/python-bin:$PATH"

# 5. Fetch Chromium iOS Source Code
if [ ! -d "$CHROMIUM_DIR" ]; then
    printf "${YEL}Creating chromium directory...${c0}\n"
    mkdir -p "$CHROMIUM_DIR"
    cd "$CHROMIUM_DIR" || die "Cannot cd to $CHROMIUM_DIR"
    
    printf "${YEL}Fetching Chromium iOS codebase (This may take several hours)...${c0}\n"
    printf "${CYA}Running: fetch --no-history ios${c0}\n"
    fetch --no-history ios || die "Failed to fetch Chromium iOS source"
else
    printf "${GRE}Chromium source directory already exists at $CHROMIUM_DIR.${c0}\n"
    cd "$CHROMIUM_DIR" || die "Cannot cd to $CHROMIUM_DIR"
fi

# Make sure we are in chromium/src
if [ -d "src" ]; then
    cd src || die "Cannot cd to src"
fi

CR_SRC_DIR="$(pwd)"
printf "${GRE}Chromium source root is: $CR_SRC_DIR${c0}\n\n"

# 6. Apply Thorium optimizations to the iOS Chromium tree
printf "${YEL}Applying Thorium ARM64 configurations...${c0}\n"

# Clone Thorium patches repository if not present
if [ ! -d "$WORK_DIR/thorium" ]; then
    printf "${YEL}Cloning Thorium patches repository...${c0}\n"
    git clone --depth 1 https://github.com/Alex313031/thorium.git "$WORK_DIR/thorium" || die "Failed to clone Thorium"
fi

# Copy Thorium's ARM optimizations over the standard arm.gni
if [ -f "$WORK_DIR/thorium/arm/mac_arm.gni" ]; then
    cp -v "$WORK_DIR/thorium/arm/mac_arm.gni" "$CR_SRC_DIR/build/config/arm.gni" || die "Failed to copy arm.gni"
    printf "${GRE}Replaced build/config/arm.gni with Thorium ARM optimizations.${c0}\n"
else
    printf "${RED}WARNING: Thorium arm/mac_arm.gni not found. Skipping compiler target customization.${c0}\n"
fi

# Run hooks to update toolchains
printf "${YEL}Running gclient runhooks...${c0}\n"
gclient runhooks || die "Failed to run gclient runhooks"

# 7. Configure the build output directory
BUILD_OUT_DIR="$CR_SRC_DIR/out/Release-iphoneos"
printf "${YEL}Creating build folder: $BUILD_OUT_DIR...${c0}\n"
mkdir -p "$BUILD_OUT_DIR"

if [ -f "$WORK_DIR/ios_Release_args.gn" ]; then
    cp -v "$WORK_DIR/ios_Release_args.gn" "$BUILD_OUT_DIR/args.gn" || die "Failed to copy args.gn"
    printf "${GRE}Configured args.gn successfully.${c0}\n"
else
    printf "${RED}WARNING: ios_Release_args.gn template not found. You will need to configure GN arguments manually.${c0}\n"
fi

# Run GN gen to create build files
printf "${YEL}Generating Ninja build files...${c0}\n"
gn gen "$BUILD_OUT_DIR" || die "Failed to generate build files via gn gen"

printf "\n${bold}${GRE}================================================================${c0}\n"
printf "${bold}${GRE}SETUP COMPLETE!${c0}\n"
printf "${CYA}To start compiling Thorium-iOS, run the following commands:${c0}\n"
printf "${bold}${YEL}  cd $CR_SRC_DIR${c0}\n"
printf "${bold}${YEL}  export PATH=\"$DEPOT_TOOLS_DIR:\$PATH\"${c0}\n"
printf "${bold}${YEL}  autoninja -C out/Release-iphoneos chrome${c0}\n"
printf "${CYA}================================================================${c0}\n\n"
