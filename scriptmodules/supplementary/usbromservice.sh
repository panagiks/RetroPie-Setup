#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="usbromservice"
rp_module_desc="USB ROM Service"
rp_module_section="config"

function depends_usbromservice() {
    local depends=(rsync ntfs-3g exfat-fuse)
    if ! hasPackage usbmount 0.0.24; then
        depends+=(debhelper devscripts pmount lockfile-progs)
        getDepends "${depends[@]}"
        if [[ "$md_mode" == "install" ]]; then
            rp_callModule usbromservice sources
            rp_callModule usbromservice build
            rp_callModule usbromservice install
        fi
    fi
}

function sources_usbromservice() {
    gitPullOrClone "$md_build" https://github.com/RetroPie/usbmount.git systemd
}

function build_usbromservice() {
    dpkg-buildpackage
}

function install_usbromservice() {
    dpkg -i ../*_all.deb
}

function enable_usbromservice() {
    # copy our mount.d scripts over
    local file
    local dest
    for file in "$md_data/"*; do
        dest="/etc/usbmount/mount.d/${file##*/}"
        sed "s/USERTOBECHOSEN/$user/g" "$file" >"$dest"
        chmod +x "$dest"
    done

    iniConfig "=" '"' /etc/usbmount/usbmount.conf
    local fs
    for fs in ntfs exfat; do
        iniGet "FILESYSTEMS"
        if [[ "$ini_value" != *$fs* ]]; then
            iniSet "FILESYSTEMS" "$ini_value $fs"
        fi
    done
    iniGet "MOUNTOPTIONS"
    local uid=$(id -u $user)
    local gid=$(id -g $user)
    if [[ ! "$ini_value" =~ uid|gid ]]; then
        iniSet "MOUNTOPTIONS" "$ini_value,uid=$uid,gid=$gid"
    fi
}

function disable_usbromservice() {
    local file
    for file in "$md_data/"*; do
        file="/etc/usbmount/mount.d/${file##*/}"
        rm -f "$file"
    done
}

function remove_usbromservice() {
    disable_usbromservice
    apt-get remove -y usbmount
}

function gui_usbromservice() {
    while true; do
        cmd=(dialog --backtitle "$__backtitle" --menu "Choose from an option below." 22 86 16)
        options=(
            1 "Enable USB ROM Service"
            2 "Disable USB ROM Service"
            3 "Remove usbmount daemon"
        )
        choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choices" ]]; then
            case $choices in
                1)
                    rp_callModule "$md_id" depends
                    rp_callModule "$md_id" enable
                    printMsgs "dialog" "Enabled $md_desc"
                    ;;
                2)
                    rp_callModule "$md_id" disable
                    printMsgs "dialog" "Disabled $md_desc"
                    ;;
                3)
                    rp_callModule "$md_id" remove
                    printMsgs "dialog" "Removed $md_desc"
                    ;;
            esac
        else
            break
        fi
    done
}
