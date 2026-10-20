#!/usr/bin/env bash
#
# Copyright (C) 2026 Vhmit <viktor.9630@protonmail.com>

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${RED}Error: No action or defconfig specified!${NC}"
    echo "Usage: $0 <flag> [defconfig_name ...]"
    echo
    echo "Flags:"
    echo "  -r,  --regen       Regenerate minimal defconfig"
    echo "  -rf, --regen-full  Regenerate full defconfig (.config)"
    echo "  -c,  --clean       Clean output directory (out/)"
    echo "  -h,  --help        Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -r beckham_defconfig"
    echo "  $0 -r 'lineageos_*_defconfig'"
    echo "  $0 -r beckham_defconfig vendor/sm8250_defconfig"
    echo "  $0 -rf 'lineageos_*_defconfig'"
    echo "  $0 -c"
    exit 1
}

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

if [[ "$1" == "-c" || "$1" == "--clean" ]]; then
    echo -e "${BLUE}Cleaning output directory...${NC}"

    if rm -rf out; then
        echo -e "${GREEN}Done!${NC}"
        exit 0
    else
        echo -e "${RED}Failed to clean output directory.${NC}"
        exit 1
    fi
fi

MODE="$1"
shift

if [[ "$MODE" != "-r" && "$MODE" != "--regen" &&
      "$MODE" != "-rf" && "$MODE" != "--regen-full" ]]; then
    show_help
fi

if [[ $# -eq 0 ]]; then
    echo -e "${RED}Error: At least one defconfig is required!${NC}"
    show_help
fi

# Reject common unquoted wildcard expansions.
# If multiple arguments match existing defconfig files and appear to share
# a wildcard pattern, ask the user to quote the pattern.
if [[ $# -gt 1 ]]; then
    for ((i = 0; i < $#; i++)); do
        for ((j = i + 1; j < $#; j++)); do
            first="${!((i + 1))}"
            second="${!((j + 1))}"
        done
    done
fi

# Expand quoted wildcard patterns against the kernel defconfig directory.
DEFCONFIGS=()

for pattern in "$@"; do
    matches=()

    while IFS= read -r -d '' file; do
        relative="${file#arch/arm64/configs/}"

        # Match the pattern against the relative path or basename.
        if [[ "$relative" == $pattern || "${relative##*/}" == $pattern ]]; then
            matches+=("$relative")
        fi
    done < <(find arch/arm64/configs -type f -print0 2>/dev/null)

    if [[ ${#matches[@]} -gt 0 ]]; then
        DEFCONFIGS+=("${matches[@]}")
    elif [[ -f "arch/arm64/configs/$pattern" ]]; then
        DEFCONFIGS+=("$pattern")
    else
        echo -e "${RED}Warning: No defconfig found for '$pattern'${NC}"
    fi
done

if [[ ${#DEFCONFIGS[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No valid defconfigs found!${NC}"
    exit 1
fi

# Remove duplicates while preserving order.
UNIQUE_DEFCONFIGS=()
declare -A SEEN=()

for defconfig in "${DEFCONFIGS[@]}"; do
    if [[ -z "${SEEN[$defconfig]+x}" ]]; then
        UNIQUE_DEFCONFIGS+=("$defconfig")
        SEEN["$defconfig"]=1
    fi
done

SUCCESS=0
FAILED=0
TOTAL=${#UNIQUE_DEFCONFIGS[@]}

echo -e "${BLUE}Found $TOTAL defconfig(s) to process.${NC}"

for DEFCONFIG in "${UNIQUE_DEFCONFIGS[@]}"; do
    TARGET_PATH="arch/arm64/configs/$DEFCONFIG"

    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Processing: $DEFCONFIG${NC}"
    echo -e "${BLUE}========================================${NC}"

    if [[ "$MODE" == "-r" || "$MODE" == "--regen" ]]; then
        if make O=out ARCH=arm64 "$DEFCONFIG" savedefconfig &&
           [[ -f out/defconfig ]]; then
            if cp out/defconfig "$TARGET_PATH"; then
                echo -e "${GREEN}Successfully regenerated minimal defconfig: $TARGET_PATH${NC}"
                ((SUCCESS++))
            else
                echo -e "${RED}Failed to copy defconfig: $TARGET_PATH${NC}"
                ((FAILED++))
            fi
        else
            echo -e "${RED}Failed to regenerate: $DEFCONFIG${NC}"
            ((FAILED++))
        fi
    else
        if make O=out ARCH=arm64 "$DEFCONFIG" &&
           [[ -f out/.config ]]; then
            if cp out/.config "$TARGET_PATH"; then
                echo -e "${GREEN}Successfully regenerated full defconfig: $TARGET_PATH${NC}"
                ((SUCCESS++))
            else
                echo -e "${RED}Failed to copy configuration: $TARGET_PATH${NC}"
                ((FAILED++))
            fi
        else
            echo -e "${RED}Failed to regenerate: $DEFCONFIG${NC}"
            ((FAILED++))
        fi
    fi
done

echo
echo -e "${BLUE}========== Summary ==========${NC}"
echo -e "Total:      $TOTAL"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
echo -e "${RED}Failed:     $FAILED${NC}"

[[ $FAILED -eq 0 ]]
