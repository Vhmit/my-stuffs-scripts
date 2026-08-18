#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
# Copyright (C) 2026 Vhmit <viktor.9630@protonmail.com>
#

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Define a versão do make desejada (ajuste se necessário, ex: "4.3" ou "4.4")
LATEST_MAKE_VERSION="4.3"

sudo apt install software-properties-common -y
sudo apt update

# Install some packages
sudo apt-get install -y \
  wget adb apt-utils aria2 arj autoconf automake axel bc bison brotli \
  build-essential cabextract ccache clang cmake cpio curl device-tree-compiler \
  expat fastboot flex fontconfig g++ g++-multilib gawk gcc gcc-multilib \
  git-lfs gnupg gperf htop imagemagick jq libc6-dev libc6-dev-i386 \
  lib32z1-dev libcap-dev libexpat1-dev libgl1-mesa-dev \
  libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev \
  libssl-dev libtinyxml2-dev libtool libx11-dev \
  libxml-simple-perl libxml2 libxml2-utils libswitch-perl lz4 lzip '^lzma.*' \
  lzop m4 maven mpack nano ncftp openjdk-11-jdk p7zip-full \
  p7zip-rar patch patchelf pkg-config pngcrush pngquant \
  python3 python3-pip python3-pyelftools rar rclone re2c \
  repo rsync schedtool sharutils squashfs-tools subversion texinfo unace \
  unrar unzip uudeview w3m xsltproc xz-utils zip zlib1g-dev libncurses5-dev

# Install deps ncurses manually (AOSP Legacy)
echo -e "Installing libtinfo5 and libncurses5..."
BASE_URL="http://mirrors.kernel.org/ubuntu/pool/universe/n/ncurses/"
DEB_TINFO=$(curl -s $BASE_URL | grep -oE 'libtinfo5_[^"]+_amd64\.deb' | sort -V | tail -n 1)
DEB_NCURSES=$(curl -s $BASE_URL | grep -oE 'libncurses5_[^"]+_amd64\.deb' | sort -V | tail -n 1)

if [ -z "$DEB_TINFO" ] || [ -z "$DEB_NCURSES" ]; then
    echo "Error: Could not find the packages on the server."
    exit 1
fi

echo "Downloading: $DEB_TINFO"
wget -q "${BASE_URL}${DEB_TINFO}"
echo "Downloading: $DEB_NCURSES"
wget -q "${BASE_URL}${DEB_NCURSES}"
echo "Installing the packages..."
sudo apt install -y ./"$DEB_TINFO" ./"$DEB_NCURSES"
echo "Cleaning up temporary files..."
rm "$DEB_TINFO" "$DEB_NCURSES"

echo -e "Installing GitHub CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

if [[ "$(command -v make)" ]]; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        echo "Installing make ${LATEST_MAKE_VERSION} instead of ${makeversion}"
        if [ -f "$(dirname "$0")"/make.sh ]; then
            bash "$(dirname "$0")"/make.sh "${LATEST_MAKE_VERSION}"
        else
            echo "Warning: make.sh not found to update the GNU Make version."
        fi
    fi
fi

echo "Installing repo"
sudo curl --create-dirs -L -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+rx /usr/local/bin/repo
