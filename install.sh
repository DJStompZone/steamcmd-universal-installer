#!/usr/bin/env bash

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
    else
        echo "Operating system not supported! Attempting to build from source."
        OS="unknown"
    fi

    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        IS_WSL=true
    else
        IS_WSL=false
    fi
}

recommend_wsl_windows_install() {
    echo "It appears you're running this script on WSL, which is unsupported."
    echo "It is recommended to install the Windows version of SteamCMD instead."
    echo "Please download SteamCMD for Windows from the following link:"
    echo "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
    echo "After extracting, you can run SteamCMD directly from Windows."
    exit 0
}

install_steamcmd_debian() {
    echo "Detected $OS $VERSION_ID"

    if [[ "$VERSION_ID" == "bookworm" ]]; then
        echo "Using configuration: deb12"
        sudo apt update
        sudo apt install software-properties-common
        sudo apt-add-repository non-free
        sudo dpkg --add-architecture i386
        sudo apt update
        sudo apt install steamcmd -y
    else
        echo "Using configuration: deb"
        sudo add-apt-repository multiverse
        sudo dpkg --add-architecture i386
        sudo apt update
        sudo apt install steamcmd -y
    fi
}

install_steamcmd_ubuntu() {
    echo "Using configuration: ubuntu"
    sudo add-apt-repository multiverse
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install steamcmd -y
}

# I use arch, btw
install_steamcmd_arch_btw() {
    echo "Using configuration: arch"

    sudo pacman -Syy base-devel --noconfirm
    git clone https://aur.archlinux.org/steamcmd.git
    cd steamcmd
    makepkg -si
}

install_steamcmd_gentoo() {
    echo "Using configuration: gentoo"

    sudo emerge --ask games-server/steamcmd
}

install_steamcmd_docker() {
    echo "Using configuration: docker"

    docker run -it --name=steamcmd cm2network/steamcmd bash
}

install_steamcmd_macos() {
    echo "Using configuration: macos"

    mkdir ~/Steam && cd ~/Steam
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
}

# As a last resort, try building from src
build_steamcmd_from_source() {
    echo "Fallback: attempting to build SteamCMD from source. Your mileage may vary."

    # Try to install deps if we can
    case $OS in
        ubuntu|debian)
            sudo apt-get install build-essential curl tar lib32gcc-s1 -y
            ;;
        arch)
            sudo pacman -S base-devel curl tar --noconfirm
            ;;
        gentoo)
            sudo emerge --ask sys-devel/gcc app-arch/tar
            ;;
        *)
            echo "Attempting to proceed with generic build process. This will most likely fail if you do not have the build tools for your OS installed."
            ;;
    esac

    # Escalate to the steam user or su up
    sudo -iu steam <<EOF
    mkdir ~/Steam && cd ~/Steam
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
EOF
}

detect_os

if [ "$IS_WSL" = true ]; then
    recommend_wsl_windows_install
fi

case $OS in
    ubuntu)
        install_steamcmd_ubuntu
        ;;
    debian)
        install_steamcmd_debian
        ;;
    arch)
        install_steamcmd_arch_btw
        ;;
    gentoo)
        install_steamcmd_gentoo
        ;;
    docker)
        install_steamcmd_docker
        ;;
    darwin)
        install_steamcmd_macos
        ;;
    *)
        echo "Unrecognized or unsupported operating system."
        build_steamcmd_from_source
        ;;
esac

echo "SteamCMD installation process completed."