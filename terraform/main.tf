resource "proxmox_vm_qemu" "k3s-master" {
  name        = "k3s-master"
  target_node = "pve"
  clone       = "VM-Ini"
  ...
}
