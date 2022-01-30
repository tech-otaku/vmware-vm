# create-vmware-vm.sh

__WARNING:__ This is still a work-in-progress.

### Purpose
Create a VMware Fusion virtual machine (VM) on a macOS host and perform an unattended install (Easy Install) of a Ubuntu Desktop guest OS all from the macOS command line with minimal user interaction.

### Background
VirtualBox has a command-line tool named `VBoxManage` to create virtual machines and install a guest OS. VMware Fusion's command-line tool `vmrun` cannot create virtual machines. Instead a combination of `mkisofs`, `vmrun` and `vmware-vdiskmanager` is required to create a new virtual machine and install a guest OS.

### Workflow
The tasks performed by `create-vmware-vm.sh` can be broken-down as follows:
+ Create a new parent directory for the VM with the suffix `.vmwarevm` on the host machine.  
+ Use `vmware-vdiskmanager` to create a new virtual disk.
+ Create a configuration file (`.vmx`) and associate the virtual disk with the VM.
+ Modify the contents of `autoinst.flp` and create the `autoinst.iso` image used for an unattended install (Easy Install).
+ Use `vmrun` to start the VM and begin the installation of the guest OS.
+ Pause execution until the guest OS has been installed and the VM has been powered off, then continue with a re-configuration of  the `.vmx` file. Pausing execution is achieved by continual polling of the VM's state using `vmrun -T ws list`.

### Preparation
Before running the script you should:
+ Edit the `VMPATH`, `ISOPATH` and `SHAREDHOST` variables at the top of the script to reflect your environment.
+ Edit the `autoinst/user/preseed.cfg` to suit your configuration needs.
+ Edit the `autoinst/user/userconf.sh` to suit your configuration needs.


### Usage
`./create-vmware-vm.sh -h`

`./create-vmware-vm.sh -i ubuntu-20.04.1-desktop-amd64.iso -n 'Ubuntu Desktop 20.04.1' -u steve -c 4 -r 8192 -s 20`

### Options

Use `./create-vmware-vm.sh -h` to see an explanation of the options and their usage.

In addition, the `-x` option which instructs the script to perform an interactive install is ignored. Currently, only an unattended install (Easy Install) can be performed.

### Customising the Guest OS Configuration 

There are three files responsible for customising the guest OS configuration during installation: `autoinst/user/preseed.cfg`, `autoinst/source/config.sh` and `autoinst/user/userconf.sh`. All three can be amended to suit your configuration needs, but take note of when in the workflow they are actioned.

##### preseed.cfg

This file is actioned during the install of the guest Ubuntu OS.

It can be used to configure language, country, locale, keyboard etc. which by default is set to a US configuration. It also contains the Ubiquity installer's preseed key `ubiquity/success_command` and the Debian installer's preseed key `preseed/late_command` which specify commands to be run when the install completes successfully. 

In the version of the `preseed.cfg` file generated by VMware Fusion these commands create an `/etc/rc.local` file dedicated to installing VMware Tools which is executed on the first boot after installation. The version used by the script has some additional steps that run `config.sh` which is responsible for managing `userconf.sh`.

##### config.sh

This script is run immediateley after the successful installation of the guest Ubuntu OS, but before the initial user login. It's execution is triggered by the preseed key `ubiquity/success_command`/`preseed/late_command` in the file `preseed.cfg`.

##### userconf.sh

This scipt is run the first time the user logs in.

This file is copied to the home directory of the user created during installation of the guest OS (the one configured in `autoinst/user/preseed.cfg`) by the `config.sh` script. It can be used to configure the user's settings such as mouse preferences, keyboard shortcuts, screen lock, Terminal and Files application configurations, install applications and fonts etc. It is run only once - after initial login - and is executed by the Unity launcher `userconf.desktop`.


### Unattended (Easy) Install
The script performs an unattended install and essentially mimicks the behaviour of VMware Fusion when checking _Use Easy Install_ in the VMware Fusion GUI. As part of the unattended install process the script creates two disk images named `autoinst.flp` and `autoinst.iso`. Once created, both disk images are copied to the VM's parent directory (.vmwarevm) and then deleted once the guest OS has been installed.

To see how these disk images are created it's useful to understand the directory structure the script runs in and how various files are sourced. 

NOTES:

- Any of the directories and files below **NOT** included in the repository are excluded because they are sourced or created on the fly during script execution.

- `/tmp/LINUX/` is the mount point for `/Applications/VMware Fusion.app/Contents/Library/isoimages/linux.iso`

- `/tmp/UBUNTU/` is the mount point for the Ubuntu installer image provided by the `-i` option i.e. `-i ubuntu-20.04.1-desktop-amd64.iso`


```
|-- autoisnt/
    |-- autoinst.flp                Created by create-vmware-vm.sh
    |-- autoinst.iso                Created by create-vmware-vm.sh
    |-- cdrom/
        |-- CONFIG.SH               autoinst/source/config.sh                                           
        |-- CUSTOM/                                         
            |-- PRESEED.CFG         autoinst/user/preseed.cfg	
        |-- ISOLINUX/                                    
            |-- INITRD              /tmp/UBUNTU/casper/initrd 
            |-- ISOLINUX.BIN        /Applications/VMware Fusion.app/Contents/Resources/isolinux.bin       
            |-- ISOLINUX.CFG        autoinst/source/isolinux.cfg.16.04, autoinst/source/isolinux.cfg.18.04, autoinst/source/isolinux.cfg.20.04 or autoinst/source/isolinux.cfg.21.04,           
            |-- VMLINUZ             /tmp/UBUNTU/casper/vmlinuz
        |-- UPGRA32                 /tmp/LINUX/vmware-tools-upgrader-32
        |-- UPGRA64                 /tmp/LINUX/vmware-tools-upgrader-64
        |-- UPGRADE.SH              /tmp/LINUX/run_upgrader.sh
    |-- floppy
        |-- PRESEED.CFG             autoinst/user/preseed.cfg
    |-- mkisofs                     /Applications/VMware Fusion.app/Contents/Library/mkisofs
    |-- source
        |-- autoinst.flp.original   Original autoinst.flp created by VMware Fusion for Ubuntu Desktop guest OS install
        |-- config.sh
        |-- isolinux.cfg.16.04      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 16.04 guest OS install
        |-- isolinux.cfg.18.04      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 18.04 guest OS install
        |-- isolinux.cfg.20.04      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 20.04 guest OS install
        |-- isolinux.cfg.20.10      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 20.10 guest OS install
        |-- isolinux.cfg.21.04      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 21.04 guest OS install
        |-- isolinux.cfg.21.10      /CDROM/ISOLINUX/ISOLINUX.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop 21.10 guest OS install
    |-- user
        |-- preseed.cfg             Modified version of /CDROM/CUSTOM/PRESEED.CFG from original autoinst.iso created by VMware Fusion for Ubuntu Desktop guest OS install
        |-- userconf.sh
|-- config.json
|-- create-vmware-vm.sh
```

##### autoinst.flp

The script creates `autoinst/autoinst.flp` by modifying the contents of `autoinst/source/autoinst.flp.original` to include the updated `autoinst/user/preseed.cfg`. This is the structure of `autoinst.flp` when mounted by macOS:

```
NO NAME/                                                                             
   |-- PRESEED.CFG
```

While this is not necessary, it may be useful to know that `autoinst.flp` can be mounted in macOS, but first its extension must be changed to `.img`. From the Finder it can be mounted using `DiskImageMounter.app` (the default) or from Terminal using `hdiutil attach /path/to/autoinst.img`. The mount point is `/Volumes/NO NAME` and it appears on the Desktop as `NO NAME`.


##### autoinst.iso

The script creates `autoinst.iso` using the `mkisofs` binary and the `autoinst/cdrom` directory as the source tree. This is the structure of `autoinst.iso` when mounted by macOS:

```
CDROM/   
  |-- CONFIG.SH                                      
  |-- CUSTOM/                                         
      |-- PRESEED.CFG            
  |-- ISOLINUX/
      |-- BOOT.CAT                  Created by mkisofs and not included in the source tree                                          
      |-- INITRD
      |-- ISOLINUX.BIN     
      |-- ISOLINUX.CFG        
      |-- VMLINUZ
  |-- UPGRA32
  |-- UPGRA64
  |-- UPGRADE.SH 
  |-- USERCONF.SH 
```

Like `autoinst.flp`, `autoinst.iso` can also be mounted in macOS - if required - using `DiskImageMounter.app` from the Finder or `hdiutil attach /path/to/autoinst.iso` from Terminal. The mount point is `/Volumes/CDROM` and it appears on the Desktop as `CDROM`.



In VMware Fusion, an unattended install requires two additional files: `autoinst.flp` and `autoinst.iso`. These two files alone will not trigger an unattended install, but adding these lines to the `.vmx` configuration file will:

````
floppy0.present = "FALSE"         # Implied TRUE if omitted. Must explicitly be set to FALSE if not using `autoinst.flp`
#floppy0.present = "TRUE"										
#floppy0.fileType = "file"
#floppy0.fileName = "autoinst.flp"
#floppy0.clientDevice = "FALSE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "autoinst.iso"
````
`create-vmware-vm.sh` will add these lines to the `.vmx` configuration file and use `mkisofs` to create `autoinst.iso` which it moves to the VM's parent directory. `autoinst.iso` is created from the contents of the `make-autoinst-iso/CDROM/` directory which contains two files that can be edited to configure the install: `make-autoinst-iso/CDROM/CUSTOM/PRESEED.CFG` and `make-autoinst-iso/CDROM/CONFIG.SH`



<img src="https://raw.githubusercontent.com/tech-otaku/vmware-vm/main/Ubuntu%20Desktop%2020.04.png" width="795" height="564">

### Tested With
_Host_
+ macOS Catalina (10.15.7)
+ macOS Big Sur (11.6)
+ VMware Fusion Pro (12.1.2)

_Guest OS_
+ Ubuntu Desktop 18.04.5 LTS (Bionic Beaver) [`ubuntu-18.04.5-desktop-amd64.iso`]
+ Ubuntu Desktop 20.04.3 LTS (Focal Fossa) [`ubuntu-20.04.3-desktop-amd64.iso`]
+ Ubuntu Desktop 20.10 (Groovy Gorrilla) [`ubuntu-20.10-desktop-amd64.iso`]
+ Ubuntu Desktop 21.04 (Hirsute Hippo) [`ubuntu-21.04-desktop-amd64.iso`]
+ Ubuntu Desktop 21.10 Beta (Impish Indir) [`ubuntu-21.10-beta-desktop-amd64.iso`]

