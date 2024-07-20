#!/bin/bash

# Copyright (C) 2023-2024 Alexander Barris
# GNU GPLv3 - All Rights Reserved

# ====
# ACK: This script modifies then builds an EL8 kernel that should be bootable on Apple Silicon
#      The big difference is RHEL7/8 compiled their ARM kernel with 64kb paging. This script
#      modified the kernel config and enables 4kb paging; the default for RHEL9 (probably for
#      this reason). I have NO intention of making this apart of Asahi Linux. This is for VMs.
# ====
# ACK: My primary target is AlmaLinux for no particular reason. It wouldn't be that hard to get
#      working on any other EL clone or RHEL itself...
# ====
# ACK: This can run on macOS through a Docker container. I recommend OrbStack.
# ====

KERNSRPM=$(dnf info --disablerepo=* --enablerepo=baseos kernel | grep Source | cut -f9 -d' ')
RPMBUILD="/root/rpmbuild"

#==============================#
# ----- Helper Functions ----- #
#==============================#
# print_info(): Prints an informative message to the console
function print_info() {
    echo "[INFO] ${1}"
}
# print_fail(): Prints a failure message to the console
function print_fail() {
    echo "[FAIL] ${1}"
    exit 1
}
# usage(): Displays the usage
function usage() {
    echo "usage: $(basename \$0) [-b] [-h]"
    echo ""
    echo "ACK: This script MUST be ran on a el8 system or container."
    echo "     I recommend the ascelr8 container or a patched el8 install"
    echo "ACK: This script is meant for Apple Silicon Macs."
    echo ""
    echo "OPTIONS"
    echo "[-b]:     Builds the modified kernel"
    echo "[-h]:     Displays this help/usage dialog"
    echo ""
    echo "Copyright (C) 2023-2024 Alexander Barris"
    echo "Licensed GNU GPLv3 - All Rights Reserved"
    echo ""
    echo "No penguins were harmed nor apples smashed in the making of this script."
    echo "But maybe a couple of hours of sleep and sanity have been lost. No promises."
}

function check_system() {
    echo "idk yet"
}

#==============================#
# ----- Script Functions ----- #
#==============================#
# change_config(): Modify packaged kernel config
function change_config() {
    local setting=${1}
    local option=${2}

    # Make sure a valid setting was given
    if ! grep -q ${setting} ${RPMBUILD}/SOURCES/kernel-aarch64.config; then
        print_fail "Unknown kernel config setting: ${setting}"
    fi

    # Modify both the kernel and kernel-debug configs
    # They need to (for the most part) match otherwise things get mad
    case ${option} in
        "y")
            print_info "Changing kernel setting ${setting} to 'y'"
            sed -i "s/.*${setting}.*/${setting}=y/" ${RPMBUILD}/SOURCES/kernel-aarch64.config
            sed -i "s/.*${setting}.*/${setting}=y/" ${RPMBUILD}/SOURCES/kernel-aarch64-debug.config
            ;;
        "n")
            print_info "Changing kernel setting ${setting} to 'n'"
            sed -i "s/.*${setting}.*/${setting}=n/" ${RPMBUILD}/SOURCES/kernel-aarch64.config
            sed -i "s/.*${setting}.*/${setting}=n/" ${RPMBUILD}/SOURCES/kernel-aarch64-debug.config
            ;;
        "x")
            print_info "Changing kernel setting ${setting} to 'is not set'"
            sed -i "s/.*${setting}.*/# ${setting} is not set/" ${RPMBUILD}/SOURCES/kernel-aarch64.config
            sed -i "s/.*${setting}.*/# ${setting} is not set/" ${RPMBUILD}/SOURCES/kernel-aarch64-debug.config
            ;;
        *)
            print_fail "Unknown config option: ${option}"
            ;;
    esac
}

# download_kernel(): Download the latest kernel SRPM
function download_kernel() {
    # Download SRPM
    if [[ -f ${RPMBUILD}/${KERNSRPM} ]]; then
        print_info "Kernel Source RPM already downloaded."
    else
        print_info "Downloading ${KERNSRPM}"
        dnf download --disablerepo=* --enablerepo=baseos --source kernel || print_fail "Failed to download kernel.srpm!"
        mv ${KERNSRPM} ${RPMBUILD}
    fi

    # Install SRPM
    if [[ -f ${RPMBUILD}/SPECS/kernel.spec ]]; then
        print_info "Kernel Source RPM already installed."
    else
        print_info "Installing ${KERNSRPM}"
        rpm -i ./${KERNSRPM} || print_fail "Failed to install kernel.srpm!"
    fi
}

#============================#
# ----- Main Functions ----- #
#============================#
function build_kernel() {
    #check_system

    # Download kernel
    download_kernel

    # Backup vendor files
    cp ${RPMBUILD}/SPECS/kernel.spec ${RPMBUILD}/SPECS/kernel.spec.distro
    cp ${RPMBUILD}/SOURCES/kernel-aarch64.config ${RPMBUILD}/SOURCES/kernel-aarch64.config.distro
    cp ${RPMBUILD}/SOURCES/kernel-aarch64-debug.config ${RPMBUILD}/SOURCES/kernel-aarch64.config-debug.distro

    # Kernel config changes
    # TODO: This should probably just be a .patch file
    change_config "CONFIG_ARM64_4K_PAGES" "y"
    change_config "CONFIG_ARM64_PA_BITS_48" "y"
    change_config "CONFIG_ARM64_64K_PAGES" "x"
    change_config "CONFIG_ARM64_PA_BITS_52" "x"
    #cp ${RPMBUILD}/SPECS/kernel.spec ${RPMBUILD}/BUILD/${KERNSRPM//.src*}/linux-*/.config

    # Kernel spec changes; my special branding
    sed -i "s/.*define buildid.*/%define buildid \.awlsome/" ${RPMBUILD}/SPECS/kernel.spec

    # Rebuild the kernel SRPM
    rpmbuild -bs ${RPMBUILD}/SPECS/kernel.spec

    # Build the kernel
    # Takes about 10 minutes on my M1 Pro (10c). Not too shabby!
    # TODO: Better logging for sure
    mock -r site-defaults --rebuild --with=baseonly --without=debug --without=debuginfo --without=kabichk ${RPMBUILD}/SRPMS/${KERNSRPM//.el*}.el8.awlsome.src.rpm

    # TODO: Copy files to /opt/rpms!
}

#============================#
# ----- Main Execution ----- #
#============================#
# TODO: Check for no arguments
while getopts 'bh' OPT; do
    case "${OPT}" in
        b)
            build_kernel
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
