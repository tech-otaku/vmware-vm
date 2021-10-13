#!/usr/bin/env bash

# # # # # # # # # # # # # # # # 
# USAGE
#
# ./create-vmware-vm.sh -i ubuntu-18.04.5-desktop-amd64.iso -n 'Ubuntu Desktop 18.04'
# ./create-vmware-vm.sh -i ubuntu-20.04.1-desktop-amd64.iso -n 'Ubuntu Desktop 20.04' -c 3 -m 8192 -s 15
# yes y | ./create-vmware-vm.sh -i ubuntu-20.04.1-desktop-amd64.iso -n 'Ubuntu Desktop 20.04' -c 3 -m 8192 -s 15



# # # # # # # # # # # # # # # # 
# CUSTOMISATIONS
#
# VMPATH, ISOPATH and SHAREDHOST should be amended to reflect your environment.
#
    VMPATH=$(cat ./config.json | python3 -c "import sys, json; print(json.load(sys.stdin)['vmpath'])")
    ISOPATH=$(cat ./config.json | python3 -c "import sys, json; print(json.load(sys.stdin)['isopath'])")
    SHAREDHOST=$(cat ./config.json | python3 -c "import sys, json; print(json.load(sys.stdin)['sharedhost'])")
#    VMPATH="/Users/steve/VMware/VMs"											# The location on the host machine where the VM will be created.
#    ISOPATH="/Users/steve/VMware/OS Images"                                     # The location of the install images on the host machine .
#    SHAREDHOST="/Users/steve/.ssh"												# Path to the host's shared folder

#
#
# # # # # # # # # # # # # # # #



# Ensure the `tidy_up` function is executed every time the script terminates regardless of exit status
    trap tidy_up EXIT



# # # # # # # # # # # # # # # # 
# FUNCTION DECLARATIONS
#

# Function to execute when the script terminates
    function tidy_up {
        for disk in $(diskutil list | grep "disk image" | cut -d ' ' -f1); do
            diskutil eject $disk
        done

        tput cnorm  # Normal cursor
    }

# Function to display usage help
    function usage {
        cat << EOF
                    
    Syntax: 
    ./$(basename $0) -h
    ./$(basename $0) -i ISO -n NAME [-c CPUS] [-m MEMORY] [-s SIZE] [-x] 

    Options:
    -c CPUS      Number of processor cores to assign to the VM's guest OS. Default is 2 if omitted.
    -i ISO       The install image of the VM's guest OS. REQUIRED
    -n NAME      The VM's name. REQUIRED
    -m MEMORY    The amount of memory to assign to the VM's guest OS. Default is 4096 (MB) if omitted.
    -s SIZE      The size of the VM's virtual disk in gigabytes (GB). Default is 10GB if omitted.
    -u USERAC    The name of the user account to create. REQUIRED
    -x           Perform an interactive install. Default is unattended install (Easy Install) if omitted.

    Example: ./$(basename $0) -i ubuntu-20.04.1-desktop-amd64.iso -n 'Ubuntu Desktop 20.04' -u steve -c 4 -m 8192 -s 20 
    
EOF
    }

# Function to attach a disk image and mount its file system
    function mount_fs {
        local MOUNT_POINT
        local DEVICE_NODE

        MOUNT_POINT=$(mktemp -d)
        DEVICE_NODE=$(hdiutil attach -nomount -nobrowse "$2" | head -1 | awk '{print $1}')
        mount -t $1 $DEVICE_NODE $MOUNT_POINT

        echo "${MOUNT_POINT}"
    }

# Function to detach (eject) a disk image
    function detach_disk {
        # Normally, there is no need to explicitly unmount the file system before detaching the device as `hdiutil detach`(or `diskutil eject`) will
        # do this first, but the Ubuntu install images are hybrid ISOs which macOS seems to struggle with. In addition, these hybrid images can't be
        # detached using the mount point. The device node (i.e. /dev/disk6) must be used instead.

        local DEVICE_NODE

        DEVICE_NODE=$(hdiutil info | grep "$1" | awk '{print $1 }') 
        umount "$1"
        hdiutil detach $DEVICE_NODE
        rm -rf "$1"
    }



# # # # # # # # # # # # # # # # 
# DEFAULTS
#

    EASY="true"                                                                 # Perform an unattended (Easy) install
    CPUS="2"																	# The number of processor cores to assign to the VM
    MEMORY="4096"																# The amount of memory to assign to the VM
    SIZE="10GB"                                                                 # The size of the VM's virtual disk

    GUEST="ubuntu-64"															# The type of guest OS to install in the VM 
    VDISK="Virtual Disk.vmdk"													# The name of the VM's virtual disk. VMware Fusion's default is "Virtual Disk.vmdk"

    SCRIPTPATH=$(dirname "$0")													# This script's parent directory. Used when creating `autoinst.iso`



# # # # # # # # # # # # # # # # 
# COMMAND-LINE OPTIONS
#

# Exit with error if no command line options given
    if [[ ! $@ =~ ^\-.+ ]]; then
        printf "\nERROR: * * * No options given. * * *\n"
        usage
        exit 1
    fi

# Prevent an option that expects an argument, taking the next option as an argument if its argument is omitted. i.e. -d -n www -c 
    while getopts ':c:hi:m:n:s:u:x' opt; do
        if [[ $OPTARG =~ ^\-.? ]]; then
            printf "\nERROR: * * * '%s' is not valid argument for option '-%s'\n" $OPTARG $opt
            usage
            exit 1
        fi
    done

# Reset OPTIND so getopts can be called a second time
    OPTIND=1        

# Process command line options
    while getopts ':c:hi:m:n:s:u:x' opt; do
        case $opt in
            c) 
                CPUS=$OPTARG 
                ;;

            h)
                usage
                exit 0
                ;;
            i) 
                ISO=$OPTARG  
                ;;
            m) 
                MEMORY=$OPTARG 
                ;;
            n) 
                NAME=$OPTARG  
                ;;
            s) 
                SIZE=$(echo "${OPTARG//[!0-9]/}")GB
                ;;
            u) 
                USERAC=$OPTARG
                ;;
            x) 
    #            unset EASY 
                ;;
            :) 
                printf "\nERROR: * * * Argument missing from '-%s' option * * *\n" $OPTARG
                usage
                exit 1
                ;;
            ?) 
                printf "\nERROR: * * * Invalid option: '-%s' * * *\n" $OPTARG
                usage
                exit 1
                ;;
        esac
    done



# # # # # # # # # # # # # # # # 
# USAGE CHECKS
#

# ISO is missing
    if [ -z "$ISO" ] || [[ "$ISO" == -* ]]; then
        printf "\nERROR: * * * No install image was specified. * * *\n"
        usage
        exit 1
    else
        if [ ! -f "${ISOPATH}/${ISO}" ]; then
            printf "\nERROR: * * * Install image '%s' not found. * * *\n" "${ISO}"
            exit 1
        else 
            ISO="${ISOPATH}/${ISO}"
        fi
    fi

# NAME is missing
    if [ -z "$NAME" ] || [[ "$NAME" == -* ]]; then
        printf "\nERROR: * * * No VM name was specified. * * *\n"
        usage
        exit 1
    fi

# USERAC is missing
    if [ -z "$USERAC" ] || [[ "$USERAC" == -* ]]; then
        printf "\nERROR: * * * No user account name was specified. * * *\n"
        usage
        exit 1
    fi

#exit


if [ ! -d "${VMPATH}/${NAME}.vmwarevm" ]; then
	# Create the VM's parent folder
	mkdir "${VMPATH}/${NAME}.vmwarevm"
else
	clear
	echo "ERROR: The VM '${NAME}' at '${VMPATH}/${NAME}.vmwarevm' already exists." 
	echo -e "Please delete it from VMware Fusion's Virtual Machine Library selecting the 'Move to Trash' option and then re-run this script.\n"
	exit 1
	#read -p "VM '${VMPATH}/${NAME}.vmwarevm' already exists. Delete it (Y/n)? " DELETE
	#if [[ $DELETE =~ "Y" ]]; then
	#	if [ $( vmrun -T ws list | grep -q "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx") ]; then
	#		/Applications/VMware\ Fusion.app/Contents/Library/vmrun -T fusion stop "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
	#	fi
	#	rm -rf  "${VMPATH}/${NAME}.vmwarevm"
	#else
	#	exit 1
	#fi
fi



# # # # # # # # # # # # # # # # 
# VIRTUAL DISK
#

# Create a virtual disk in the VM's parent folder using `vmware-vdiskmanager` 
# -c = create
# -s = size
# -a = disk adapter type 
# -t = disk type [2 = pre-allocated contained in a single file]
# For other options go to https://www.vmware.com/support/ws45/doc/disks_vdiskmanager_run_ws.html 

    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -c -s ${SIZE} -a lsilogic -t 2 "${VMPATH}/${NAME}.vmwarevm/${VDISK}"



# # # # # # # # # # # # # # # # 
# .VMX CONFIGURATION FILE
#

cat vmx/main.vmx > "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

printf "\n\n\n" >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

if [ ! -z $EASY ]; then 

	cat vmx/easy-install.vmx >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

else

	cat vmx/interactive-install.vmx >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

fi

printf "\n\n\n" >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

cat << EOF >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
# * * * * ANYTHING APPEARING BELOW THIS LINE IS AUTO-ADDED BY VMWARE * * * *

EOF

sed -i '' \
-e "s|__CPUS__|$CPUS|g" \
-e "s|__GUEST__|$GUEST|g" \
-e "s|__ISO__|$ISO|g" \
-e "s|__MEMORY__|$MEMORY|g" \
-e "s|__NAME__|$NAME|g" \
-e "s|__SHAREDHOST__|$SHAREDHOST|g" \
-e "s|__VDISK__|$VDISK|g" \
-e "s|__VMPATH__|$VMPATH|g" \
"${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"



# # # # # # # # # # # # # # # # 
# AUTOINST.FLP AND AUTOINST.ISO
#

if [ ! -z $EASY ]; then 

    [ -f "${SCRIPTPATH}/autoinst/autoinst.flp" ] && rm -f "${SCRIPTPATH}/autoinst/autoinst.flp"
    [ -f "${SCRIPTPATH}/autoinst/autoinst.iso" ] && rm -f "${SCRIPTPATH}/autoinst/autoinst.iso"
    [ -f "${SCRIPTPATH}/autoinst/mkisofs" ] && rm -f "${SCRIPTPATH}/autoinst/mkisofs"
    [ -f "${SCRIPTPATH}/autoinst/cdrom/CONFIG.SH" ] && rm -f "${SCRIPTPATH}/autoinst/cdrom/CONFIG.SH"
    [ -f "${SCRIPTPATH}/autoinst/cdrom/USERCONF.SH" ] && rm -f "${SCRIPTPATH}/autoinst/cdrom/USERCONF.SH"
    [ -d "${SCRIPTPATH}/autoinst/cdrom/CUSTOM" ] && rm -rf "${SCRIPTPATH}/autoinst/cdrom/CUSTOM"
    [ -d "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX" ] && rm -rf "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX"
    [ -f "${SCRIPTPATH}/autoinst/cdrom/UPGRA32" ] && rm -f "${SCRIPTPATH}/autoinst/cdrom/UPGRA32"
    [ -f "${SCRIPTPATH}/autoinst/cdrom/UPGRA64" ] && rm -f "${SCRIPTPATH}/autoinst/cdrom/UPGRA64"
    [ -f "${SCRIPTPATH}/autoinst/cdrom/UPGRADE.SH" ] && rm -f "${SCRIPTPATH}/autoinst/cdrom/UPGRADE.SH"
    [ -f "${SCRIPTPATH}/autoinst/floppy/PRESEED.CFG" ] && rm -f "${SCRIPTPATH}/autoinst/floppy/PRESEED.CFG"

    mkdir "${SCRIPTPATH}/autoinst/cdrom/CUSTOM"
    mkdir "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX"

    cp -p "${SCRIPTPATH}/autoinst/user/preseed.cfg" "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp"
    sed -i '' "s/_USERFULLNAME_/$(echo $USERAC | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')/" "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp"
    sed -i '' "s/_USERNAME_/$(echo $USERAC | awk '{print tolower(substr($0,1))}')/g" "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp"

    # Modify autoinst.flp
    cp "${SCRIPTPATH}/autoinst/source/autoinst.flp.original" "${SCRIPTPATH}/autoinst/autoinst.img"

    MOUNT_POINT=$(mount_fs msdos "${SCRIPTPATH}/autoinst/autoinst.img")
    #MOUNT_POINT=$(mktemp -d)
    #DISK_TO_MOUNT=$(hdiutil attach -nomount -nobrowse "${SCRIPTPATH}/autoinst/autoinst.img" | head -1 | awk '{print $1}')
    #mount -t msdos $DISK_TO_MOUNT $MOUNT_POINT

    cp -p "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp" $MOUNT_POINT/PRESEED.CFG

    detach_disk $MOUNT_POINT
    #umount $MOUNT_POINT
    #rm -rf $MOUNT_POINT
    #diskutil eject $MOUNT_POINT
    
    mv "${SCRIPTPATH}/autoinst/autoinst.img" "${SCRIPTPATH}/autoinst/autoinst.flp"
    cp -p "${SCRIPTPATH}/autoinst/autoinst.flp" "${VMPATH}/${NAME}.vmwarevm/autoinst.flp"

    # Create non-bootable floppy
    cp -p "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp" "${SCRIPTPATH}/autoinst/floppy/PRESEED.CFG"
    #hdiutil create -size 1440k -fs "MS-DOS FAT12" -layout NONE -srcfolder floppy -format UDRW -volname 'NO NAME' -ov autoinst.dmg
    #mv autoinst.dmg "${VMPATH}/${NAME}.vmwarevm/autoinst.flp"
    #cp autoinst.flp "${VMPATH}/${NAME}.vmwarevm/autoinst.flp"

    # Create autoinst.iso
    # The only difference between these files is that both isolinux.cfg.16.04 and isolinux.cfg.18.04 contain 'boot=casper' and the rest do not.
    if [[ $ISO == *"ubuntu-21.10"* ]]; then 
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.21.10" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    elif [[ $ISO == *"ubuntu-21.04"* ]]; then 
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.21.04" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    elif [[ $ISO == *"ubuntu-20.10"* ]]; then 
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.20.10" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    elif [[ $ISO == *"ubuntu-20.04"* ]]; then 
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.20.04" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    elif [[ $ISO == *"ubuntu-18"* ]]; then
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.18.04" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    elif [[ $ISO == *"ubuntu-16"* ]]; then
        cp -p "${SCRIPTPATH}/autoinst/source/isolinux.cfg.16.04" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.CFG"
    fi

    cp -p "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp" "${SCRIPTPATH}/autoinst/cdrom/CUSTOM/PRESEED.CFG"
    cp -p "${SCRIPTPATH}/autoinst/source/config.sh" "${SCRIPTPATH}/autoinst/cdrom/CONFIG.SH"
    cp -p "${SCRIPTPATH}/autoinst/user/userconf.sh" "${SCRIPTPATH}/autoinst/cdrom/USERCONF.SH"

    # Copy files from Ubuntu Desktop installation iso
    MOUNT_POINT=$(mount_fs cd9660 "$ISO")
    #MOUNT_POINT=$(mktemp -d)
    #DISK_TO_MOUNT=$(hdiutil attach -nomount -nobrowse -readonly "$ISO" | head -1 | awk '{print $1}')
    #mount -t cd9660 $DISK_TO_MOUNT $MOUNT_POINT

    cp -p "${MOUNT_POINT}/casper/initrd" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/INITRD"
    cp -p "${MOUNT_POINT}/casper/vmlinuz" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/VMLINUZ"

    detach_disk $MOUNT_POINT
    #umount $MOUNT_POINT
    #rm -rf $MOUNT_POINT
    #diskutil eject $MOUNT_POINT

    # Copy files from `linux.iso`
    MOUNT_POINT=$(mount_fs cd9660 "/Applications/VMware Fusion.app/Contents/Library/isoimages/linux.iso")
    #MOUNT_POINT=$(mktemp -d)
    #DISK_TO_MOUNT=$(hdiutil attach -nomount -nobrowse -readonly "/Applications/VMware Fusion.app/Contents/Library/isoimages/linux.iso" | head -1 | awk '{print $1}')
    #mount -t cd9660 $DISK_TO_MOUNT $MOUNT_POINT

    cp -p "${MOUNT_POINT}/vmware-tools-upgrader-32" "${SCRIPTPATH}/autoinst/cdrom/UPGRA32"
    cp -p "${MOUNT_POINT}/vmware-tools-upgrader-64" "${SCRIPTPATH}/autoinst/cdrom/UPGRA64"
    cp -p "${MOUNT_POINT}/run_upgrader.sh" "${SCRIPTPATH}/autoinst/cdrom/UPGRADE.SH"

    detach_disk $MOUNT_POINT
    #umount $MOUNT_POINT
    #rm -rf $MOUNT_POINT
    #diskutil eject $MOUNT_POINT

    cp -p "/Applications/VMware Fusion.app/Contents/Resources/isolinux.bin" "${SCRIPTPATH}/autoinst/cdrom/ISOLINUX/ISOLINUX.BIN"

    cp -p "/Applications/VMware Fusion.app/Contents/Library/mkisofs" "${SCRIPTPATH}/autoinst/mkisofs"

    pushd "${SCRIPTPATH}/autoinst"

    # autoinst.iso
	./mkisofs -o 'autoinst.iso' -b 'ISOLINUX/ISOLINUX.BIN' -c 'ISOLINUX/BOOT.CAT' -m .DS_Store -V 'CDROM' -no-emul-boot  -boot-load-size 4 -boot-info-table 'cdrom'
    cp -p autoinst.iso "${VMPATH}/${NAME}.vmwarevm/autoinst.iso"

	popd

    rm -f "${SCRIPTPATH}/autoinst/user/preseed.cfg.tmp"

fi



# # # # # # # # # # # # # # # # 
# INSTALL GUEST OS
#

/Applications/VMware\ Fusion.app/Contents/Library/vmrun -T fusion start "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"

#clear

printf "\n* * * DO NOT CLOSE THIS SHELL * * * \n\nExecution of script '${0##*/}' is paused and will continue after installation of the guest OS has completed and the VM has powered-off:\n\n"

date1=$(date +%s)
tput civis  # Hide cursor 
while /Applications/VMware\ Fusion.app/Contents/Library/vmrun -T fusion list | grep -q "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"; do
    # See https://superuser.com/a/901013
    echo -ne "Elapsed time: $(date -ujf "%s" $(($(date +%s) - $date1)) +%M:%S)\r"
done
printf "\033[2K\r"
tput cnorm  # Normal cursor



# # # # # # # # # # # # # # # # 
# FINISH-UP
#

read -p "$(echo -e 'VM has powered-off. Run Post-Install Cleanup (y/N)? ')" POSTINST
if [[ ! $POSTINST =~ "N" ]]; then
	if [ ! $( /Applications/VMware\ Fusion.app/Contents/Library/vmrun -T ws list | grep -q "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx") ]; then
		echo "Running Post-Install Cleanup..."
		read -p "Remove SATA CD/DVD drives from VM (y/N)? " SATA
		if [[ ! $SATA =~ "N" ]]; then
			mv "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx" "${VMPATH}/${NAME}.vmwarevm/${NAME}.tmp"
#			grep -vE "sata" "${VMPATH}/${NAME}.vmwarevm/${NAME}.tmp" > "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
            sed -r 's/^(.*)sata/\1#sata/g' "${VMPATH}/${NAME}.vmwarevm/${NAME}.tmp" > "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
			echo "SATA CD/DVD drives removed."
		fi
		read -p "Enable 'Use full resolution for Retina display' for VM (y/N)? " RETINA
		if [[ ! $RETINA =~ "N" ]]; then
			echo "gui.fitGuestUsingNativeDisplayResolution = \"TRUE\"" >> "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
			echo "'Use full resolution for Retina display' enabled."
		fi
	fi

	read -p "Power-on VM (y/N)? " POWERON
	if [[ ! $POWERON =~ "N" ]]; then
        echo "Powering-on VM"
		/Applications/VMware\ Fusion.app/Contents/Library/vmrun -T fusion start "${VMPATH}/${NAME}.vmwarevm/${NAME}.vmx"
	fi
fi