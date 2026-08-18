#!/bin/bash
#
# Copyright (C) 2026 Vhmit <viktor.9630@protonmail.com>

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage help
show_help() {
    echo -e "${RED}Error: No action or defconfig specified!${NC}"
    echo -e "Usage: $0 <flag> [defconfig_name]"
    echo -e ""
    echo -e "Flags:"
    echo -e "  -r,  --regen       Regenerate minimal defconfig"
    echo -e "  -rf, --regen-full  Regenerate full defconfig (.config)"
    echo -e "  -c,  --clean       Clean output directory (out/)"
    echo -e "  -h,  --help        Show this help message"
    echo -e ""
    echo -e "Examples:"
    echo -e "  $0 -r beckham_defconfig"
    echo -e "  $0 --regen-full vendor/sm8250_defconfig"
    echo -e "  $0 -c"
    exit 1
}

# Check if no arguments were provided or if help was explicitly requested
if [[ -z "$1" || "$1" = "-h" || "$1" = "--help" ]]; then
    show_help
fi

# Handle clean flag independently as it does not require a defconfig
if [[ $1 = "-c" || $1 = "--clean" ]]; then
    echo -e "${BLUE}Cleaning output directory...${NC}"
    rm -rf out
    echo -e "${GREEN}Done!${NC}"
    exit 0
fi

# Require defconfig for regen operations
if [[ -z "$2" ]]; then
    echo -e "${RED}Error: Missing defconfig name for operation '$1'!${NC}\n"
    show_help
fi

DEFCONFIG="$2"

# Function to locate where the defconfig file exists
find_defconfig_path() {
    if [[ -f "arch/arm64/configs/$DEFCONFIG" ]]; then
        echo "arch/arm64/configs/$DEFCONFIG"
    elif [[ -f "arch/arm64/configs/vendor/$DEFCONFIG" ]]; then
        echo "arch/arm64/configs/vendor/$DEFCONFIG"
    else
        # Default fallback path if it doesn't exist anywhere yet
        echo "arch/arm64/configs/$DEFCONFIG"
    fi
}

TARGET_PATH=$(find_defconfig_path)

if [[ $1 = "-r" || $1 = "--regen" ]]; then
    make O=out ARCH=arm64 $DEFCONFIG savedefconfig
    cp out/defconfig "$TARGET_PATH"
    echo -e "\n${GREEN}Successfully regenerated defconfig ($DEFCONFIG) at $TARGET_PATH${NC}"
    exit 0
fi

if [[ $1 = "-rf" || $1 = "--regen-full" ]]; then
    make O=out ARCH=arm64 $DEFCONFIG
    cp out/.config "$TARGET_PATH"
    echo -e "\n${GREEN}Successfully regenerated full defconfig ($DEFCONFIG) at $TARGET_PATH${NC}"
    exit 0
fi

# Fallback if an unknown flag was passed
show_help
