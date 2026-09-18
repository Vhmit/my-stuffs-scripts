#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
# Copyright (C) 2026 Vhmit <viktor.9630@protonmail.com>
#

set -e

# Store project path
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# GNU Make version required
LATEST_MAKE_VERSION="4.3"

# Legacy ncurses version used by Ubuntu 22.04 (Jammy)
NCURSES_JAMMY_VERSION="6.3-2ubuntu0"

# Ubuntu package pool
NCURSES_BASE_URL="https://mirrors.kernel.org/ubuntu/pool/universe/n/ncurses/"

echo "Updating package lists..."
sudo apt update

echo "Installing dependencies..."

sudo apt-get install -y \
  software-properties-common wget adb apt-utils aria2 arj autoconf automake \
  axel bc bison brotli build-essential cabextract ccache clang cmake cpio curl \
  device-tree-compiler expat fastboot flex fontconfig g++ g++-multilib gawk \
  gcc gcc-multilib git-lfs gnupg gperf htop imagemagick jq libc6-dev \
  libc6-dev-i386 lib32z1-dev libcap-dev libexpat1-dev libgl1-mesa-dev \
  libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libssl-dev \
  libtinyxml2-dev libtool libx11-dev libxml-simple-perl libxml2 libxml2-utils \
  libswitch-perl lz4 lzip '^lzma.*' lzop m4 maven mpack nano ncftp \
  openjdk-11-jdk p7zip-full p7zip-rar patch patchelf pkg-config pngcrush \
  pngquant python3 python3-pip python3-pyelftools rar rclone re2c rsync \
  schedtool sharutils squashfs-tools subversion texinfo unace unrar unzip \
  uudeview w3m xsltproc xz-utils zip zlib1g-dev libncurses5-dev

# ============================================================
# Legacy ncurses libraries
#
# Ubuntu 24.04 no longer provides libtinfo5/libncurses5 in its
# normal repositories. Some old AOSP/TWRP prebuilts still need
# libtinfo.so.5 and libncurses.so.5.
#
# Fetch the newest Jammy revision:
#
#   6.3-2ubuntu0.1
#   6.3-2ubuntu0.2
#   6.3-2ubuntu0.3
#   6.3-2ubuntu0.4
#   ...
# ============================================================

echo
echo "Installing legacy ncurses libraries..."

ARCH="$(dpkg --print-architecture)"

get_latest_jammy_deb() {
    local package="$1"

    curl -fsSL "$NCURSES_BASE_URL" |
        grep -oE "${package}_${NCURSES_JAMMY_VERSION}\.[0-9]+_${ARCH}\.deb" |
        sort -Vu |
        tail -n 1
}

DEB_TINFO="$(get_latest_jammy_deb "libtinfo5")"
DEB_NCURSES="$(get_latest_jammy_deb "libncurses5")"

# Make sure both packages were found
if [[ -z "$DEB_TINFO" ]]; then
    echo "Error: Could not find libtinfo5 Jammy package."
    exit 1
fi

if [[ -z "$DEB_NCURSES" ]]; then
    echo "Error: Could not find libncurses5 Jammy package."
    exit 1
fi

echo "Latest Jammy packages found:"
echo "  $DEB_TINFO"
echo "  $DEB_NCURSES"

# Temporary directory prevents .deb files from being left
# in the project directory.
TMP_NCURSES_DIR="$(mktemp -d)"

cleanup_ncurses() {
    rm -rf "$TMP_NCURSES_DIR"
}

trap cleanup_ncurses EXIT

echo
echo "Downloading legacy ncurses packages..."

wget \
    --show-progress \
    -O "$TMP_NCURSES_DIR/$DEB_TINFO" \
    "${NCURSES_BASE_URL}${DEB_TINFO}"

wget \
    --show-progress \
    -O "$TMP_NCURSES_DIR/$DEB_NCURSES" \
    "${NCURSES_BASE_URL}${DEB_NCURSES}"

echo
echo "Installing legacy ncurses packages..."

sudo dpkg -i \
    "$TMP_NCURSES_DIR/$DEB_TINFO" \
    "$TMP_NCURSES_DIR/$DEB_NCURSES" || {
        echo "Resolving package dependencies..."
        sudo apt-get install -f -y
    }

echo
echo "Legacy ncurses libraries installed successfully."

# Remove temporary packages now instead of waiting for EXIT.
cleanup_ncurses

# Disable the EXIT trap because cleanup was already performed.
trap - EXIT


# ============================================================
# GitHub CLI
# ============================================================

echo
echo "Installing GitHub CLI..."

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null

sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

sudo apt update
sudo apt install -y gh


# ============================================================
# GNU Make
# ============================================================

echo
echo "Checking GNU Make..."

if command -v make >/dev/null 2>&1; then
    MAKE_VERSION="$(make --version | head -n 1 | awk '{print $3}')"

    if [[ "$MAKE_VERSION" != "$LATEST_MAKE_VERSION" ]]; then
        echo "GNU Make $MAKE_VERSION detected."
        echo "Installing GNU Make $LATEST_MAKE_VERSION..."

        if [[ -f "$PROJECT_DIR/make.sh" ]]; then
            bash "$PROJECT_DIR/make.sh" "$LATEST_MAKE_VERSION"
        else
            echo "Warning: make.sh not found."
            echo "Skipping GNU Make update."
        fi
    else
        echo "GNU Make $LATEST_MAKE_VERSION is already installed."
    fi
else
    echo "Warning: GNU Make was not found."
fi


# ============================================================
# Android repo tool
# ============================================================

echo
echo "Installing Android repo tool..."

sudo curl \
    --fail \
    --location \
    --create-dirs \
    --output /usr/local/bin/repo \
    https://storage.googleapis.com/git-repo-downloads/repo

sudo chmod a+rx /usr/local/bin/repo


# ============================================================
# Final verification
# ============================================================

echo
echo "Checking legacy ncurses libraries..."

if ldconfig -p | grep -q 'libtinfo\.so\.5'; then
    echo "libtinfo.so.5: OK"
else
    echo "Warning: libtinfo.so.5 was not found by ldconfig."
fi

if ldconfig -p | grep -q 'libncurses\.so\.5'; then
    echo "libncurses.so.5: OK"
else
    echo "Warning: libncurses.so.5 was not found by ldconfig."
fi

echo
echo "========================================"
echo " Dependencies installed successfully!"
echo "========================================"
