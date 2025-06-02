#Declaration des variables
variable "proxmox_api_url" {
  type    = string
  default = null
}

variable "proxmox_api_token_id" {
  type    = string
  default = null
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  default   = null
}
# Ubuntu Server Noble Numbat
packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-server" {
  # Connexion Proxmox (utilise les variables)
  proxmox_url = "${var.proxmox_api_url}" 
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true
  
  # Paramètres généraux VM
  node                 = "santoLAB"
  vm_id                = "113"
  vm_name              = "ubuntu-server"
  template_description = "Ubuntu 24.04 LTS"
  template_name        = "packer-ubuntu"

  # Configuration ISO 
  boot_iso {
    iso_file         = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
    iso_storage_pool = "local"
    unmount     = true
  }

  # Paramètres système
  qemu_agent       = true
  scsi_controller  = "virtio-scsi-pci"
  cores            = 1
  memory           = 2048
  os               = "l26"

  # Disque
  disks {
    disk_size         = "20G"
    format            = "raw"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    type              = "virtio"
  }

  # Réseau
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # Cloud-Init
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # Commandes de boot
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot_wait = "5s"

  # Autoinstall
  http_directory    = "http"
  http_bind_address = "192.168.1.90"
  ssh_username      = "ubuntu"
  ssh_password      = "admin"
  ssh_timeout       = "20m"
}

build {
  name    = "ubuntu-server"
  sources = ["source.proxmox-iso.ubuntu-server"]

  # provisioner "shell" {
  #   inline = [
  #     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
  #     "sudo rm /etc/ssh/ssh_host_*",
  #     "sudo truncate -s 0 /etc/machine-id",
  #     "sudo apt -y autoremove --purge",
  #     "sudo apt -y clean",
  #     "sudo apt -y autoclean",
  #     "sudo cloud-init clean",
  #     "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
  #     "sudo rm -f /etc/netplan/00-installer-config.yaml",
  #     "sudo sync"
  #   ]
  # }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # provisioner "shell" {
  #   inline = [
  #     "echo 'Pause de 3 minutes avant conversion en template...'",
  #     "sleep 180"
  #   ]
  # }
}