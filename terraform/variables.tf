variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
  type        = string
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  type        = string
}

variable "target_node" {
  description = "Node Proxmox cible"
  type        = string
}

variable "template_id" {
  description = "ID du template VM à cloner"
  type        = number
}

variable "vm_defaults" {
  description = "Configurations par défaut des VMs"
  type = object({
    cores     = number
    memory    = number
    disk_size = string
  })
}

variable "network_config" {
  description = "Configuration réseau"
  type = object({
    base_ip = string
    subnet  = string
    gateway = string
  })
}

variable "vm_ips" {
  description = "IPs des VMs"
  type = map(string)
  default = {
    "k3s-master"    = "100"
    "k3s-worker-1"  = "101"
    "k3s-worker-2"  = "102"
    "Vm-nfs"        = "110"
  }
}

variable "ssh_public_key_file" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "id_rsa.pub"
}

variable "vm_password" {
  description = "Mot de passe des comptes utilisateurs VM"
  type        = string
} 