terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.6"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

locals {
  vm_base_config = {
    target_node = var.target_node
    clone       = var.template_name
    full_clone  = true
    os_type     = "cloud-init"
    cores       = var.vm_defaults.cores
    memory      = var.vm_defaults.memory
    ciuser      = "ubuntu"
    cipassword  = "admin"
    sshkeys     = file("${path.module}/${var.ssh_public_key_file}")
    boot        = "order=scsi0"
    scsihw      = "virtio-scsi-single"
    agent       = 1
  }
}

# --------- VM MASTER ---------
resource "proxmox_vm_qemu" "k3s-master" {
  name     = "k3s-master"
  vmid     = 108

  # Fusion avec la configuration de base
  target_node = local.vm_base_config.target_node
  clone       = local.vm_base_config.clone
  full_clone  = local.vm_base_config.full_clone
  os_type     = local.vm_base_config.os_type
  cores       = local.vm_base_config.cores
  memory      = local.vm_base_config.memory
  sshkeys     = local.vm_base_config.sshkeys
  ciuser      = local.vm_base_config.ciuser
  cipassword  = local.vm_base_config.cipassword
  boot        = local.vm_base_config.boot
  scsihw      = local.vm_base_config.scsihw
  agent       = local.vm_base_config.agent

  ipconfig0 = "ip=${var.network_config.base_ip}.${var.vm_ips["k3s-master"]}/${var.network_config.subnet},gw=${var.network_config.gateway}"

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = var.vm_defaults.disk_size
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

# --------- VM WORKERS ---------
resource "proxmox_vm_qemu" "k3s-workers" {
  count    = 2
  name     = "k3s-worker-${count.index + 1}"
  vmid     = 109 + count.index

  # Fusion avec la configuration de base
  target_node = local.vm_base_config.target_node
  clone       = local.vm_base_config.clone
  full_clone  = local.vm_base_config.full_clone
  os_type     = local.vm_base_config.os_type
  cores       = local.vm_base_config.cores
  memory      = local.vm_base_config.memory
  sshkeys     = local.vm_base_config.sshkeys
  ciuser      = local.vm_base_config.ciuser
  cipassword  = local.vm_base_config.cipassword
  boot        = local.vm_base_config.boot
  scsihw      = local.vm_base_config.scsihw
  agent       = local.vm_base_config.agent

  ipconfig0 = "ip=${var.network_config.base_ip}.${var.vm_ips["k3s-worker-${count.index + 1}"]}/${var.network_config.subnet},gw=${var.network_config.gateway}"

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = var.vm_defaults.disk_size
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  timeouts {
    create = "20m"
    delete = "20m"
  }
}
