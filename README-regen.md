## How to use

Usage: ./regen.sh <flag> [defconfig_name]

Flags:
  -r,  --regen       Regenerate minimal defconfig
  -rf, --regen-full  Regenerate full defconfig (.config)
  -c,  --clean       Clean output directory (out/)
  -h,  --help        Show this help message

Examples:
  ./regen.sh -r beckham_defconfig
  ./regen.sh --regen-full vendor/sm8250_defconfig
  ./regen.sh -c

```
wget https://raw.githubusercontent.com/Vhmit/my-stuffs-scripts/regen.sh && chmod +x regen.sh
```
