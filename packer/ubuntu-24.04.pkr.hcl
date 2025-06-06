# Ubuntu Server Noble Numbat (24.04)
# ---
# Packer Template to create an Ubuntu Server (Noble) on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
    default = null
}

variable "proxmox_api_token_id" {
    type = string
    default = null
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
    default = null
}

# Resource Definition for the VM Template
source "proxmox-iso" "ubuntu-server-noble-template" {
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    insecure_skip_tls_verify = true
    
    # VM General Settings
    node = "santoLAB"
    vm_id = "113"
    vm_name = "ubuntu-server-noble-template"
    template_description = "Ubuntu Server Noble (24.04) Image"
    template_name = "packer-ubuntu"

    # VM OS Settings
    iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true
    scsi_controller = "virtio-scsi-pci"
    os = "l26"

    # VM Hard Disk Settings
    disks {
        disk_size = "10G"
        format = "raw"
        storage_pool = "local-lvm"
        storage_pool_type = "lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot_wait = "10s"

    # PACKER Autoinstall Settings
    http_directory = "http"
    http_bind_address = "192.168.1.90"
    ssh_username = "ubuntu"
    ssh_password = "admin"
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {
    name = "ubuntu-server-noble"
    sources = ["source.proxmox-iso.ubuntu-server-noble-template"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove",
            "sudo apt -y purge",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
    }
}