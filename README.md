# proxmox-tools

Collection of useful tools for proxmox

- renumber_vm.sh
    A script to renumber the vmid.
    This is not proxmox's recommended way of changing the vmid
    but this script aviods having to clone the disk(s).

    You still need to delete, modify vzdump 
