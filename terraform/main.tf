terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "= 2.9.6"
    }
  }
}

# Configuration du provider Proxmox
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = true
}

# Configuration commune pour tous les VMs
locals {
  vm_settings = {
    cores      = 2          # Nombre de cores CPU
    memory     = 2048       # Mémoire RAM en MB
    disk_size  = "15G"      # Taille du disque
    target_node = "santoLAB" # Nom du node Proxmox
  }
}

# --------- VM MASTER ---------
resource "proxmox_vm_qemu" "k3s-master" {
  vmid        = 108
  name        = "k3s-master"
  target_node = var.vm_settings.target_node
  clone       = var.vm_settings.template
  full_clone  = true

  # Configuration système
  os_type = "cloud-init"
  cores   = var.vm_settings.cores
  memory  = var.vm_settings.memory

  # Configuration réseau
  ipconfig0 = "ip=${var.network_config.master_ip}/24,gw=${var.network_config.gateway}"
  sshkeys   = file("${path.module}/id_rsa.pub")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Configuration du disque
  disk {
    slot     = 0
    size     = var.vm_settings.disk_size
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-single"
  agent   = 1
}

# --------- VM WORKER 1 ---------
resource "proxmox_vm_qemu" "k3s-worker-1" {
  vmid        = 109
  name        = "k3s-worker-1"
  target_node = var.vm_settings.target_node
  clone       = var.vm_settings.template
  full_clone  = true

  os_type = "cloud-init"
  cores   = var.vm_settings.cores
  memory  = var.vm_settings.memory

  ipconfig0 = "ip=${var.network_config.worker1_ip}/24,gw=${var.network_config.gateway}"
  sshkeys   = file("${path.module}/id_rsa.pub")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = var.vm_settings.disk_size
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-single"
  agent   = 1
}

# --------- VM WORKER 2 ---------
resource "proxmox_vm_qemu" "k3s-worker-2" {
  vmid        = 110
  name        = "k3s-worker-2"
  target_node = local.vm_settings.target_node
  clone       = "packer-ubuntu"
  full_clone  = true

  os_type = "cloud-init"
  cores   = local.vm_settings.cores
  memory  = local.vm_settings.memory

  ipconfig0 = "ip=192.168.1.111/24,gw=192.168.1.1"
  sshkeys   = file("${path.module}/id_rsa.pub")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = local.vm_settings.disk_size
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-single"
  agent   = 1
}
