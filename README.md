# Projet MSPR-IAC

## Objectif

Ce projet a pour but de déployer automatiquement une infrastructure complète pour un cluster Kubernetes léger (K3s) avec stockage partagé (NFS) et quelques applications, en utilisant des outils d'infrastructure as code (IaC) : **Packer**, **Terraform** et **Ansible**.  

---

## Guide d'installation rapide (Windows + Proxmox)

### 1. Prérequis

- **Accès à un cluster Proxmox** (avec droits pour créer des VMs)
- **Un PC sous Windows**

### 2. Installer les outils nécessaires

#### a. Packer & Terraform (sous Windows)

Télécharge et installe :
- [Packer](https://developer.hashicorp.com/packer/install)
- [Terraform](https://developer.hashicorp.com/terraform/install)

Ajoute-les au PATH si besoin (ou place les exécutables dans le dossier du projet).

#### b. Ansible (via WSL)

1. Installe [WSL](https://learn.microsoft.com/fr-fr/windows/wsl/install) :
   - Ouvre PowerShell en administrateur et lance :
     ```powershell
     wsl --install
     ```
2. Ouvre Ubuntu (WSL) et installe Ansible :
   ```sh
   sudo apt update
   sudo apt install ansible -y
   ```

### 3. Préparer le projet

- Clone ou copie ce dossier sur ton PC Windows.
- Pour Ansible, copie le dossier `ansible/` dans ton home WSL (ex : `/home/tonuser/ansible`).
- Donne tous les droits sur les fichiers (dans WSL) :
  ```sh
  chmod -R 777 ~/ansible
  ```

### 4. Déploiement étape par étape

#### a. Créer l'image Ubuntu avec Packer

Dans un terminal Windows (cmd ou PowerShell) :
```sh
packer build -var-file=variables.pkrvars.hcl ubuntu-24.04.pkr.hcl
```

#### b. Déployer les VMs avec Terraform

Toujours dans un terminal Windows :
```sh
terraform init
terraform apply
```

#### Cibler uniquement certaines VMs avec Terraform

Vous pouvez choisir de créer uniquement le master, les workers ou le serveur NFS avec la commande `-target` :

- **Créer uniquement le master :**
  ```sh
  terraform apply -target=proxmox_virtual_environment_vm.k3s-master
  ```
- **Créer uniquement les workers :**
  ```sh
  terraform apply -target=proxmox_virtual_environment_vm.k3s-workers
  ```
- **Créer uniquement le serveur NFS :**
  ```sh
  terraform apply -target=proxmox_virtual_environment_vm.Vm-nfs
  ```

Vous pouvez combiner plusieurs `-target` pour lancer plusieurs ressources en même temps.

#### c. Configurer les VMs avec Ansible

Dans WSL (Ubuntu) :
```sh
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-become-pass
```

#### Exécuter uniquement certains rôles avec Ansible (tags)

Le playbook Ansible supporte plusieurs tags pour exécuter seulement certains rôles :

- **Lancer uniquement le master :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags master
  ```
- **Lancer uniquement les workers :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags workers
  ```
- **Lancer uniquement les addons Kubernetes :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags addons
  ```
- **Lancer uniquement le serveur NFS :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags nfs
  ```
- **Lancer tout le cluster (master + workers) :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags cluster
  ```
- **Lancer tout (cluster + addons + nfs) :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags all
  ```

> **Astuce :**
> Vous pouvez combiner plusieurs tags avec une virgule, par exemple :
> `--tags "master,addons"`

---

### Résumé

1. Installe Packer & Terraform sur Windows, Ansible sur WSL.
2. Lance Packer puis Terraform depuis Windows.
3. Lance Ansible depuis WSL, après avoir copié le dossier ansible dedans.

---

**C'est tout !**
Pas besoin de sécurité avancée, tout est prêt pour tester et comprendre l'infra.

---

## Architecture

- **Packer** : Crée une image Ubuntu 24.04 prête pour le cloud-init, utilisée comme base pour toutes les machines virtuelles.
- **Terraform** : Déploie les machines virtuelles (1 master K3s, 2 workers, 1 serveur NFS) sur un cluster Proxmox.
- **Ansible** : Configure les machines :
  - Installe et configure le cluster K3s (Kubernetes léger)
  - Déploie un serveur NFS pour le stockage partagé
  - Installe des addons Kubernetes (MetalLB, Ingress, NFS provisioner, Odoo...)

---

## Paramètres et valeurs utilisés dans ce projet

- **Cluster Proxmox** : `santoLab`
- **Nom de l'image Packer** : `ubuntu-server-noble-template`
- **Réseau utilisé** : `192.168.1.0/24`
- **Bridge réseau Proxmox** : `vmbr0`
- **Utilisateur par défaut sur les VMs** : `ubuntu` (mot de passe : `admin`)
- **VMs déployées** :
  - Master K3s : `k3s-master` — IP : `192.168.1.100`
  - Worker 1 : `k3s-worker-1` — IP : `192.168.1.101`
  - Worker 2 : `k3s-worker-2` — IP : `192.168.1.102`
  - Serveur NFS : `Vm-nfs` — IP : `192.168.1.103`
- **Stockage NFS** : Exporté depuis le serveur NFS (`/srv/nfs`) et monté dans les pods Kubernetes via le NFS provisioner, dans le dossier `/srv/nfs` sur les pods.
- **Odoo** :
  - LoadBalancer exposé sur l'IP : `192.168.1.201`
  - Ingress hostname : `odoo.local`
    **User & password**
    - user : user@example.com
    - password : HDC8wiWCht

---

## Déroulement détaillé du déploiement

### 1. Création de l'image de base avec **Packer**

Packer permet d'automatiser la création d'une image système prête à l'emploi pour nos VMs Proxmox.

- **Fichier principal :** `ubuntu-24.04.pkr.hcl` (template Packer)
- **Fichier de variables :** `variables.pkrvars.hcl`
- **Arborescence du dossier `packer/` :**
  ```
  packer/
  ├── ubuntu-24.04.pkr.hcl         # Template principal Packer
  ├── variables.pkrvars.hcl        # Variables pour le build
  ├── http/                        # Fichiers pour cloud-init
  ├── files/                       # Fichiers de config à injecter
  └── ...
  ```
   **Commande de Validate :**
  ```sh
  packer validate -var-file=variables.pkrvars.hcl ubuntu-24.04.pkr.hcl
- **Commande de build :**
  ```sh
  packer build -var-file=variables.pkrvars.hcl ubuntu-24.04.pkr.hcl
  ```

### 2. Déploiement des VMs avec **Terraform**

Terraform permet de décrire et de provisionner l'infrastructure (VMs, réseau, etc.) sur Proxmox de façon déclarative.

- **Fichier principal :** `main.tf`
- **Fichier de variables :** `variables.tf`
- **Fichier de valeurs :** `terraform.tfvars`
- **Arborescence du dossier `terraform/` :**
  ```
  terraform/
  ├── main.tf              # Définition des ressources
  ├── variables.tf         # Déclaration des variables
  ├── terraform.tfvars     # Valeurs concrètes des variables
  ├── id_rsa.pub           # Clé SSH publique injectée dans les VMs
  └── ...
  ```
- **Commandes de déploiement :**
  ```sh
  terraform init
  terraform apply
  ```
  Après cette étape, les VMs sont créées et prêtes à être configurées.

### 3. Configuration logicielle des VMs avec **Ansible**

Ansible automatise la configuration logicielle des VMs : installation de K3s, configuration du cluster, configuration du stockage externe, déploiement des addons, etc.

- **Inventaire :** `inventory/hosts.ini`
- **Playbook principal :** `playbooks/site.yml`
- **Rôles :**
  - `roles/k3s_master/` : installation et configuration du master K3s
  - `roles/k3s_worker/` : installation des workers K3s
  - `roles/nfs_server/` : installation et configuration du serveur NFS
  - `roles/k8s_addons/` : installation de MetalLB, Ingress, NFS provisioner, Odoo...
- **Arborescence du dossier `ansible/` :**
  ```
  ansible/
  ├── inventory/
  │   └── hosts.ini           # Inventaire des VMs
  ├── playbooks/
  │   └── site.yml            # Playbook principal
  ├── roles/
  │   ├── k3s_master/
  │   ├── k3s_worker/
  │   ├── nfs_server/
  │   └── k8s_addons/
  └── ...
  ```
- **Commande d'exécution :**
  ```sh
  ansible-playbook -i inventory/hosts.ini playbooks/site.yml
  Debug ```

---

## Fonctionnalités déployées

- **Cluster K3s** (Kubernetes léger) avec 1 master et 2 workers
- **Stockage partagé NFS** pour les volumes persistants, exporté depuis `/srv/nfs` sur le serveur NFS et monté dans les pods Kubernetes dans `/srv/nfs`
- **Addons Kubernetes** :
  - MetalLB (LoadBalancer) : permet d'exposer des services sur le réseau local, par exemple Odoo sur `192.168.1.201`
  - Ingress Nginx : permet d'accéder à Odoo via le nom de domaine local `odoo.local`
  - NFS provisioner : provisionne dynamiquement des volumes persistants sur le stockage NFS
  - Odoo (application de démonstration) : accessible via le LoadBalancer (`192.168.1.201`) ou via l'Ingress (`http://odoo.local`)

---

## Kubernetes : commandes utiles

- **Lister les nœuds du cluster**
  ```sh
  kubectl get nodes -o wide
  ```
- **Lister les pods**
  ```sh
  kubectl get pods -A -o wide
  ```
- **Lister les services**
  ```sh
  kubectl get svc -A
  ```
- **Lister les volumes persistants (PVC)**
  ```sh
  kubectl get pvc -A
  ```

---

## Structure globale du projet

```
.
├── packer/      # Création de l'image Ubuntu cloud-init
├── terraform/   # Déploiement des VMs sur Proxmox
├── ansible/     # Configuration logicielle des VMs et du cluster
└── docs/        # Documentation (captures d'écran)
```

--- 