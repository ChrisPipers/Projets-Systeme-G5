#! /bin/sh
set -e

# grub-mkconfig helper script.
# Copyright (C) 2006,2007,2008,2009,2010  Free Software Foundation, Inc.
#
# GRUB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GRUB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GRUB.  If not, see <http://www.gnu.org/licenses/>.

prefix="/usr"
exec_prefix="/usr"
datarootdir="/usr/share"

. "$pkgdatadir/grub-mkconfig_lib"

export TEXTDOMAIN=grub2
export TEXTDOMAINDIR="${datarootdir}/locale"

CLASS="--class gnu-linux --class gnu --class os"

if [ "x${GRUB_DISTRIBUTOR}" = "x" ] ; then
  OS=GNU/Linux
else
  OS="${GRUB_DISTRIBUTOR}"
  CLASS="--class $(echo ${GRUB_DISTRIBUTOR} | tr 'A-Z' 'a-z' | cut -d' ' -f1|LC_ALL=C sed 's,[^[:alnum:]_],_,g') ${CLASS}"
fi

# loop-AES arranges things so that /dev/loop/X can be our root device, but
# the initrds that Linux uses don't like that.
case ${GRUB_DEVICE} in
  /dev/loop/*|/dev/loop[0-9])
    GRUB_DEVICE=`losetup ${GRUB_DEVICE} | sed -e "s/^[^(]*(\([^)]\+\)).*/\1/"`
  ;;
esac

# btrfs may reside on multiple devices. We cannot pass them as value of root= parameter
# and mounting btrfs requires user space scanning, so force UUID in this case.
if [ "x${GRUB_DEVICE_UUID}" = "x" ] || [ "x${GRUB_DISABLE_LINUX_UUID}" = "xtrue" ] \
    || ! test -e "/dev/disk/by-uuid/${GRUB_DEVICE_UUID}" \
    || ( test -e "${GRUB_DEVICE}" && uses_abstraction "${GRUB_DEVICE}" lvm ); then
  LINUX_ROOT_DEVICE=${GRUB_DEVICE}
else
  LINUX_ROOT_DEVICE=UUID=${GRUB_DEVICE_UUID}
fi

if [ "x$GRUB_CONMODE" != "x" ]; then
  GRUB_CMDLINE_LINUX="conmode=${GRUB_CONMODE} ${GRUB_CMDLINE_LINUX}"
fi

case x"$GRUB_FS" in
    xbtrfs)
	if [ "x${SUSE_BTRFS_SNAPSHOT_BOOTING}" = "xtrue" ]; then
	GRUB_CMDLINE_LINUX="${GRUB_CMDLINE_LINUX} \${extra_cmdline}"
	else
	rootsubvol="`make_system_path_relative_to_its_root /`"
	rootsubvol="${rootsubvol#/}"
	if [ "x${rootsubvol}" != x ] && [ "x$SUSE_REMOVE_LINUX_ROOT_PARAM" != "xtrue" ]; then
	    GRUB_CMDLINE_LINUX="rootflags=subvol=${rootsubvol} ${GRUB_CMDLINE_LINUX}"
	fi
	fi;;
    xzfs)
	rpool=`${grub_probe} --device ${GRUB_DEVICE} --target=fs_label 2>/dev/null || true`
	bootfs="`make_system_path_relative_to_its_root / | sed -e "s,@$,,"`"
	LINUX_ROOT_DEVICE="ZFS=${rpool}${bootfs}"
	;;
esac

if [ "x$SUSE_REMOVE_LINUX_ROOT_PARAM" = "xtrue" ]; then
  LINUX_ROOT_DEVICE=""
fi

title_correction_code=

hotkey=1
incr_hotkey()
{
  [ -z "$hotkey" ] && return
  expr $hotkey + 1
}
print_hotkey()
{
  keys="123456789abdfgijklmnoprtuvwyz"
  if [ -z "$hotkey" ]||[ $hotkey -eq 0 ]||[ $hotkey -gt 30 ]; then
    return
  fi
  echo "--hotkey=$(expr substr $keys $hotkey 1)"
}

linux_entry ()
{
  os="$1"
  version="$2"
  type="$3"
  args="$4"

  if [ -n "${linux_root_device_thisversion}" ]; then
    root_device="root=${linux_root_device_thisversion}"
  else
    root_device=""
  fi

  if [ -z "$boot_device_id" ]; then
      boot_device_id="$(grub_get_device_id "${GRUB_DEVICE}")"
  fi
  if [ x$type != xsimple ] ; then
      case $type in
	  recovery)
	      title="$(gettext_printf "%s, with Linux %s (recovery mode)" "${os}" "${version}")" ;;
	  *)
	      title="$(gettext_printf "%s, with Linux %s" "${os}" "${version}")" ;;
      esac
      if [ x"$title" = x"$GRUB_ACTUAL_DEFAULT" ] || [ x"Previous Linux versions>$title" = x"$GRUB_ACTUAL_DEFAULT" ]; then
	  replacement_title="$(echo "Advanced options for ${OS}" | sed 's,>,>>,g')>$(echo "$title" | sed 's,>,>>,g')"
	  quoted="$(echo "$GRUB_ACTUAL_DEFAULT" | grub_quote)"
	  title_correction_code="${title_correction_code}if [ \"x\$default\" = '$quoted' ]; then default='$(echo "$replacement_title" | grub_quote)'; fi;"
	  grub_warn "$(gettext_printf "Please don't use old title \`%s' for GRUB_DEFAULT, use \`%s' (for versions before 2.00) or \`%s' (for 2.00 or later)" "$GRUB_ACTUAL_DEFAULT" "$replacement_title" "gnulinux-advanced-$boot_device_id>gnulinux-$version-$type-$boot_device_id")"
      fi
      echo "menuentry '$(echo "$title" | grub_quote)' $(print_hotkey) ${CLASS} \$menuentry_id_option 'gnulinux-$version-$type-$boot_device_id' {" | sed "s/^/$submenu_indentation/"
      hotkey=$(incr_hotkey)
  else
      echo "menuentry '$(echo "$os" | grub_quote)' $(print_hotkey) ${CLASS} \$menuentry_id_option 'gnulinux-simple-$boot_device_id' {" | sed "s/^/$submenu_indentation/"
      hotkey=$(incr_hotkey)
  fi      
  if [ x$type != xrecovery ] ; then
      save_default_entry | grub_add_tab
  fi

  # Use ELILO's generic "efifb" when it's known to be available.
  # FIXME: We need an interface to select vesafb in case efifb can't be used.
  if [ "x$GRUB_GFXPAYLOAD_LINUX" = x ]; then
      echo "	load_video" | sed "s/^/$submenu_indentation/"
      if grep -qx "CONFIG_FB_EFI=y" "${config}" 2> /dev/null \
	  && grep -qx "CONFIG_VT_HW_CONSOLE_BINDING=y" "${config}" 2> /dev/null; then
	  echo "	set gfxpayload=keep" | sed "s/^/$submenu_indentation/"
      fi
  else
      if [ "x$GRUB_GFXPAYLOAD_LINUX" != xtext ]; then
	  echo "	load_video" | sed "s/^/$submenu_indentation/"
      fi
      echo "	set gfxpayload=$GRUB_GFXPAYLOAD_LINUX" | sed "s/^/$submenu_indentation/"
  fi

  echo "	insmod gzio" | sed "s/^/$submenu_indentation/"

 if [ $PLATFORM != emu ]; then # 'search' does not work for now
  if [ x$dirname = x/ ]; then
    if [ -z "${prepare_root_cache}" ]; then
      prepare_root_cache="$(prepare_grub_to_access_device ${GRUB_DEVICE} | grub_add_tab)"
    fi
    printf '%s\n' "${prepare_root_cache}" | sed "s/^/$submenu_indentation/"
  else
    if [ -z "${prepare_boot_cache}" ]; then
      prepare_boot_cache="$(prepare_grub_to_access_device ${GRUB_DEVICE_BOOT} | grub_add_tab)"
    fi
    printf '%s\n' "${prepare_boot_cache}" | sed "s/^/$submenu_indentation/"
  fi
 fi
  message="$(gettext_printf "Loading Linux %s ..." ${version})"
  if [ -d /sys/firmware/efi ] && [ "x${GRUB_USE_LINUXEFI}" = "xtrue" ]; then
    sed "s/^/$submenu_indentation/" << EOF
	echo	'$(echo "$message" | grub_quote)'
	linuxefi ${rel_dirname}/${basename} ${root_device} ro ${args}
EOF
  else
    sed "s/^/$submenu_indentation/" << EOF
	echo	'$(echo "$message" | grub_quote)'
	linux	${rel_dirname}/${basename} ${root_device} ${args}
EOF
  fi
  if test -n "${initrd}" ; then
    # TRANSLATORS: ramdisk isn't identifier. Should be translated.
    message="$(gettext_printf "Loading initial ramdisk ...")"
    if [ -d /sys/firmware/efi ] && [ "x${GRUB_USE_LINUXEFI}" = "xtrue" ]; then
      sed "s/^/$submenu_indentation/" << EOF
	echo	'$(echo "$message" | grub_quote)'
	initrdefi ${rel_dirname}/${initrd}
EOF
    else
      sed "s/^/$submenu_indentation/" << EOF
	echo	'$(echo "$message" | grub_quote)'
	initrd	${rel_dirname}/${initrd}
EOF
    fi
  fi
  sed "s/^/$submenu_indentation/" << EOF
}
EOF
}

machine=`uname -m`
case "x$machine" in
    xi?86 | xx86_64) klist="/boot/vmlinuz-* /vmlinuz-* /boot/kernel-*" ;;
    xaarch64) klist="/boot/Image-* /Image-* /boot/kernel-*" ;;
    xarm*) klist="/boot/zImage-* /zImage-* /boot/kernel-*" ;;
    xs390 | xs390x)  klist="/boot/image-* /boot/kernel-*" ;;
    *) klist="/boot/vmlinuz-* /boot/vmlinux-* /vmlinuz-* /vmlinux-* \
		/boot/kernel-*" ;;
esac
list=
for i in $klist ; do
    if grub_file_is_not_garbage "$i" ; then list="$list $i" ; fi
done

case "$machine" in
    i?86) GENKERNEL_ARCH="x86" ;;
    mips|mips64) GENKERNEL_ARCH="mips" ;;
    mipsel|mips64el) GENKERNEL_ARCH="mipsel" ;;
    arm*) GENKERNEL_ARCH="arm" ;;
    *) GENKERNEL_ARCH="$machine" ;;
esac

PLATFORM="native"
if [ -d /sys/firmware/efi ]&&[ "x${GRUB_USE_LINUXEFI}" = "xtrue" ]; then
    PLATFORM="efi"
else
    case "$machine" in
        s390*) PLATFORM="emu" ;;
    esac
fi

prepare_boot_cache=
prepare_root_cache=
boot_device_id=
title_correction_code=

# Extra indentation to add to menu entries in a submenu. We're not in a submenu
# yet, so it's empty. In a submenu it will be equal to '\t' (one tab).
submenu_indentation=""

is_top_level=true
while [ "x$list" != "x" ] ; do
  linux=`version_find_latest $list`
  gettext_printf "Found linux image: %s\n" "$linux" >&2
  basename=`basename $linux`
  dirname=`dirname $linux`
  rel_dirname=`make_system_path_relative_to_its_root $dirname`
  if [ $PLATFORM != "emu" ]; then
    hotkey=0
  else
    if [ "x${SUSE_BTRFS_SNAPSHOT_BOOTING}" = "xtrue" ] &&
       [ "x${GRUB_FS}" = "xbtrfs" ] ; then
       rel_dirname="\${btrfs_subvol}$dirname"
    else
       rel_dirname="$dirname"
    fi
  fi
  version=`echo $basename | sed -e "s,^[^0-9]*-,,g"`
  alt_version=`echo $version | sed -e "s,\.old$,,g"`
  linux_root_device_thisversion="${LINUX_ROOT_DEVICE}"

  initrd=
  for i in "initrd.img-${version}" "initrd-${version}.img" "initrd-${version}.gz" \
	   "initrd-${version}" "initramfs-${version}.img" \
	   "initrd.img-${alt_version}" "initrd-${alt_version}.img" \
	   "initrd-${alt_version}" "initramfs-${alt_version}.img" \
	   "initramfs-genkernel-${version}" \
	   "initramfs-genkernel-${alt_version}" \
	   "initramfs-genkernel-${GENKERNEL_ARCH}-${version}" \
	   "initramfs-genkernel-${GENKERNEL_ARCH}-${alt_version}"; do
    if test -e "${dirname}/${i}" ; then
      initrd="$i"
      break
    fi
  done

  config=
  for i in "${dirname}/config-${version}" "${dirname}/config-${alt_version}" "/etc/kernels/kernel-config-${version}" ; do
    if test -e "${i}" ; then
      config="${i}"
      break
    fi
  done

  # try to get the kernel config if $linux is a symlink
  if test -z "${config}" ; then
    lnk_version=`basename \`readlink -f $linux\` | sed -e "s,^[^0-9]*-,,g"`
    if (test -n ${lnk_version} && test -e "${dirname}/config-${lnk_version}") ; then
      config="${dirname}/config-${lnk_version}"
    fi
  fi

  # check if we are in xen domU
  if [ ! -e /proc/xen/xsd_port -a -e /proc/xen ]; then
    # we're running on xen domU guest
    dmi=/sys/class/dmi/id
    if [ -r "${dmi}/product_name" -a -r "${dmi}/sys_vendor" ]; then
      product_name=`cat ${dmi}/product_name`
      sys_vendor=`cat ${dmi}/sys_vendor`
      if test "${sys_vendor}" = "Xen" -a "${product_name}" = "HVM domU"; then
        # xen HVM guest
        xen_pv_domU=false
      fi
    fi
  else
    # we're running on baremetal or xen dom0
    xen_pv_domU=false
  fi

  if test "$xen_pv_domU" = "false" ; then
    # prevent xen kernel without pv_opt support from booting
    if (grep -qx "CONFIG_XEN=y" "${config}" 2> /dev/null && ! grep -qx "CONFIG_PARAVIRT=y" "${config}" 2> /dev/null); then
      echo "Skip xenlinux kernel $linux" >&2
      list=`echo $list | tr ' ' '\n' | grep -vx $linux | tr '\n' ' '`
      continue
    fi
  fi

  initramfs=
  if test -n "${config}" ; then
      initramfs=`grep CONFIG_INITRAMFS_SOURCE= "${config}" | cut -f2 -d= | tr -d \"`
  fi

  if test -n "${initrd}" ; then
    gettext_printf "Found initrd image: %s\n" "${dirname}/${initrd}" >&2
  elif test -z "${initramfs}" ; then
    # "UUID=" and "ZFS=" magic is parsed by initrd or initramfs.  Since there's
    # no initrd or builtin initramfs, it can't work here.
    linux_root_device_thisversion=${GRUB_DEVICE}
  fi

  if [ "x$is_top_level" = xtrue ] && [ "x${GRUB_DISABLE_SUBMENU}" != xy ]; then
    linux_entry "${OS}" "${version}" simple \
    "${GRUB_CMDLINE_LINUX} ${GRUB_CMDLINE_LINUX_DEFAULT}"

    submenu_indentation="$grub_tab"
    
    if [ -z "$boot_device_id" ]; then
	boot_device_id="$(grub_get_device_id "${GRUB_DEVICE}")"
    fi
    # TRANSLATORS: %s is replaced with an OS name
    echo "submenu '$(gettext_printf "Advanced options for %s" "${OS}" | grub_quote)' $(print_hotkey) \$menuentry_id_option 'gnulinux-advanced-$boot_device_id' {"
    hotkey=$(incr_hotkey)
    is_top_level=false
  fi

  linux_entry "${OS}" "${version}" advanced \
              "${GRUB_CMDLINE_LINUX} ${GRUB_CMDLINE_LINUX_DEFAULT}"
  if [ "x${GRUB_DISABLE_RECOVERY}" != "xtrue" ]; then
    linux_entry "${OS}" "${version}" recovery \
                "${GRUB_CMDLINE_LINUX} ${GRUB_CMDLINE_LINUX_RECOVERY}"
  fi

  list=`echo $list | tr ' ' '\n' | fgrep -vx "$linux" | tr '\n' ' '`
done

# If at least one kernel was found, then we need to
# add a closing '}' for the submenu command.
if [ x"$is_top_level" != xtrue ]; then
  echo '}'
fi

echo "$title_correction_code"
