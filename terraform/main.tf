terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true
}

locals {
  ssh_public_key = file("${path.module}/${var.ssh_public_key_file}")
}

# --------- VM MASTER ---------
resource "proxmox_virtual_environment_vm" "k3s-master" {
  name        = "k3s-master"
  description = "K3s Master Node managed by Terraform"
  tags        = ["terraform", "k3s", "master"]
  vm_id       = 108
  node_name   = var.target_node

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores   = var.vm_defaults.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.vm_defaults.memory
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      domain  = "lab.local"
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "${var.network_config.base_ip}.${var.vm_ips["k3s-master"]}/${var.network_config.subnet}"
        gateway = var.network_config.gateway
      }
    }
    user_account {
      username = "ubuntu"
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.vm_defaults.disk_size
    interface    = "scsi0"
    file_format  = "raw"
  }

  on_boot = true
  started = true
}

# --------- VM WORKERS ---------
resource "proxmox_virtual_environment_vm" "k3s-workers" {
  count       = 2
  name        = "k3s-worker-${count.index + 1}"
  description = "K3s Worker Node ${count.index + 1} managed by Terraform"
  tags        = ["terraform", "k3s", "worker"]
  vm_id       = 109 + count.index
  node_name   = var.target_node

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores   = var.vm_defaults.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.vm_defaults.memory
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "192.168.1.${101 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      username = "ubuntu"
      password = "admin"
      keys     = [local.ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.vm_defaults.disk_size
    interface    = "scsi0"
    file_format  = "raw"
  }

  on_boot = true
  started = true
}

# --------- VM NFS ---------
resource "proxmox_virtual_environment_vm" "Vm-nfs" {
  name        = "Vm-nfs"
  description = "NFS Server managed by Terraform"
  tags        = ["terraform", "nfs"]
  vm_id       = 111
  node_name   = var.target_node

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores   = var.vm_defaults.cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.vm_defaults.memory
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "192.168.1.103/24"
        gateway = "192.168.1.1"
      }
    }
    user_account {
      username = "ubuntu"
      password = "admin"
      keys     = [local.ssh_public_key]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.vm_defaults.disk_size
    interface    = "scsi0"
    file_format  = "raw"
  }

  on_boot = true
  started = true
}