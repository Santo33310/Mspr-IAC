variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
  default     = "https://192.168.1.4:8006/api2/json"
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  type        = string
  sensitive   = true
}

variable "template_name" {
  description = "Nom du template à utiliser"
  type        = string
  default     = "packer-ubuntu"
}

variable "target_node" {
  description = "Node Proxmox cible"
  type        = string
  default     = "santoLAB"
}

variable "vm_defaults" {
  description = "Configurations par défaut des VMs"
  type = object({
    cores   = number
    memory  = number
    disk_size = string
  })
  default = {
    cores     = 2
    memory    = 2048
    disk_size = "15G"
  }
}

variable "network_config" {
  description = "Configuration réseau"
  type = object({
    gateway = string
    subnet  = string
    base_ip = string
  })
  default = {
    gateway = "192.168.1.1"
    subnet  = "24"
    base_ip = "192.168.1"
  }
}

variable "vm_ips" {
  description = "IPs des VMs"
  type = map(string)
  default = {
    "k3s-master"   = "18"
    "k3s-worker-1" = "19"
    "k3s-worker-2" = "20"
  }
}

variable "ssh_public_key_file" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "id_rsa.pub"
} 