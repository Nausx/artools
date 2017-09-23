#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_preset(){
    local p=${tmp_dir}/${kernel}.preset
    cp ${DATADIR}/linux.preset $p
    sed -e "s|@kernel@|$kernel|g" \
        -e "s|@arch@|${target_arch}|g"\
        -i $p
    echo $p
}

write_bootloader_conf(){
    local conf="${modules_dir}/bootloader.conf" efi_boot_loader='grub'
    msg2 "Writing %s ..." "${conf##*/}"
    source "$(get_preset)"
    echo '---' > "$conf"
    echo "efiBootLoader: \"${efi_boot_loader}\"" >> "$conf"
    echo "kernel: \"${ALL_kver#*/boot}\"" >> "$conf"
    echo "img: \"${default_image#*/boot}\"" >> "$conf"
    echo "fallback: \"${fallback_image#*/boot}\"" >> "$conf"
    echo 'timeout: "10"' >> "$conf"
    echo "kernelLine: \", with ${kernel}\"" >> "$conf"
    echo "fallbackKernelLine: \", with ${kernel} (fallback initramfs)\"" >> "$conf"
    echo 'grubInstall: "grub-install"' >> "$conf"
    echo 'grubMkconfig: "grub-mkconfig"' >> "$conf"
    echo 'grubCfg: "/boot/grub/grub.cfg"' >> "$conf"
    echo '#efiBootloaderId: "dirname"' >> "$conf"
}

write_servicescfg_conf(){
    local conf="${modules_dir}/servicescfg.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo '---' >  "$conf"
    echo '' >> "$conf"
    echo 'services:' >> "$conf"
    echo '    enabled:' >> "$conf"
    for s in ${openrc_boot[@]};do
        echo "      - name: $s" >> "$conf"
        echo '        runlevel: boot' >> "$conf"
    done
    for s in ${openrc_default[@]};do
        echo "      - name: $s" >> "$conf"
        echo '        runlevel: default' >> "$conf"
    done
}

write_initcpio_conf(){
    local conf="${modules_dir}/initcpio.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "kernel: ${kernel}" >> "$conf"
}

write_users_conf(){
    local conf="${modules_dir}/users.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "defaultGroups:" >> "$conf"
    local IFS=','
    for g in ${addgroups[@]};do
        echo "    - $g" >> "$conf"
    done
    unset IFS
    echo "autologinGroup:  autologin" >> "$conf"
    echo "doAutologin:     false" >> "$conf" # can be either 'true' or 'false'
    echo "sudoersGroup:    wheel" >> "$conf"
    echo "setRootPassword: true" >> "$conf" # must be true, else some options get hidden
    echo "doReusePassword: false" >> "$conf" # only used in old 'users' module
    echo "availableShells: /bin/bash, /bin/zsh" >> "$conf" # only used in new 'users' module
    echo "avatarFilePath:  ~/.face" >> "$conf" # mostly used file-name for avatar
}

get_yaml(){
    echo "netgroups-${initsys}.yaml"
}

write_netinstall_conf(){
    local conf="${modules_dir}/netinstall.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "groupsUrl: ${netgroups}/$(get_yaml)" >> "$conf"
}

write_settings_conf(){
    local conf="$1/etc/calamares/settings.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "modules-search: [ local ]" >> "$conf"
    echo '' >> "$conf"
    echo "sequence:" >> "$conf"
    echo "    - show:" >> "$conf"
    echo "        - welcome" >> "$conf"
    echo "        - locale" >> "$conf"
    echo "        - keyboard" >> "$conf"
    echo "        - partition" >> "$conf"
    echo "        - users" >> "$conf" && write_users_conf
    echo "        - netinstall" >> "$conf" && write_netinstall_conf
    echo "        - summary" >> "$conf"
    echo "    - exec:" >> "$conf"
    echo "        - partition" >> "$conf"
    echo "        - mount" >> "$conf"
    echo "        - chrootcfg" >> "$conf"
    echo "        - networkcfg" >> "$conf"
    echo "        - machineid" >> "$conf"
    echo "        - fstab" >> "$conf"
    echo "        - locale" >> "$conf"
    echo "        - keyboard" >> "$conf"
    echo "        - localecfg" >> "$conf"
    echo "        - luksopenswaphookcfg" >> "$conf"
    echo "        - luksbootkeyfile" >> "$conf"
    echo "        - initcpiocfg" >> "$conf"
    echo "        - initcpio" >> "$conf" && write_initcpio_conf
    echo "        - users" >> "$conf"
    echo "        - displaymanager" >> "$conf"
    echo "        - hwclock" >> "$conf"
    case ${initsys} in
        'openrc') echo "        - servicescfg" >> "$conf" && write_servicescfg_conf ;;
    esac
    echo "        - grubcfg" >> "$conf"
    echo "        - bootloader" >> "$conf" && write_bootloader_conf
    echo "        - postcfg" >> "$conf"
    echo "        - umount" >> "$conf"
    echo "    - show:" >> "$conf"
    echo "        - finished" >> "$conf"
    echo '' >> "$conf"
    echo "branding: ${os_id}" >> "$conf"
    echo '' >> "$conf"
    echo "prompt-install: false" >> "$conf"
    echo '' >> "$conf"
    echo "dont-chroot: false" >> "$conf"
}

configure_calamares(){
    info "Configuring [Calamares]"
    modules_dir=$1/etc/calamares/modules
    prepare_dir "${modules_dir}"
    write_settings_conf "$1"
    info "Done configuring [Calamares]"
}
