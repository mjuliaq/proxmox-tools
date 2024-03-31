#!/bin/bash
# 
# This script renumbers the vm ID in proxmox. Run as root.
#
# The vm should be stopped during the change. This is not Proxmox's recommended procedure.
#
# Original idea: https://forum.proxmox.com/threads/changing-vmid-of-a-vm.63161/
#
# 
# TODO check vm is not running, support for moving backups


echo Input the vm id to change
read oldVMID
case $oldVMID in
    ''|*[!0-9]*)
        echo "vmID should be numbers only";
        echo "Exiting";
        exit;;
    *)
        echo Old VMID - $oldVMID ;;
esac
echo
echo Input the new vm id
read newVMID

# Check the new vm id is not already in use 
case $newVMID in
    ''|*[!0-9]*)
        echo "vmID should be numbers only";
        echo "Exiting";
        exit;;
    *)
 	if test -f /etc/pve/qemu-server/$newVMID.conf; then
  		echo "VMID: $newVMID configuration file already exist";
		echo "STOP!";
		exit;
	fi
        echo New VMID - $newVMID ;;
esac
echo

# check the new disk name does not exist.
newlv="$(lvs --noheadings -o lv_name,vg_name | grep "vm-"$newVMID"-disk" | awk -F ' ' '{print $1}' | uniq)"
case $newlv in
    "")
	# Destination volume is available
        echo ;;
    *)
        echo "Destination disk exists";
	echo "STOP!";
	exit ;;
esac

# get the volume group name where the logical volumes for this vm live
vgNAME="$(lvs --noheadings -o lv_name,vg_name | grep "vm-"$oldVMID"-disk" | awk -F ' ' '{print $2}' | uniq)"
case $vgNAME in
    "")
        echo Machine not in Volume Group. Exiting
        exit;;
    *)
        echo Volume Group - $vgNAME ;;
esac

for i in $(lvs -a|grep $vgNAME | awk '{print $1}' | grep "vm-"$oldVMID"-disk");
do
#	echo "Renaming $vgNAME/vm-$oldVMID-disk-$(echo $i | awk '{print substr($0,length,1)}') to vm-$newVMID-disk-$(echo $i | awk '{print substr($0,length,1)}')";
	lvrename $vgNAME/vm-$oldVMID-disk-$(echo $i | awk '{print substr($0,length,1)}') vm-$newVMID-disk-$(echo $i | awk '{print substr($0,length,1)}');
done;

echo ""
echo "Replacing $oldVMID with $newVMID in /etc/pve/qemu-server/$oldVMID.conf"
echo ""
sed -i "s/$oldVMID/$newVMID/g" /etc/pve/qemu-server/$oldVMID.conf;

echo ""
echo "Renaming /etc/pve/qemu-server/$oldVMID.conf to /etc/pve/qemu-server/$newVMID.conf"
echo ""
mv /etc/pve/qemu-server/$oldVMID.conf /etc/pve/qemu-server/$newVMID.conf;

echo "Done"
echo ""