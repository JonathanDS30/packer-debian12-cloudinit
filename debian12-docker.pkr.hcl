#########################################
# Packer Block : Manage plugins
#########################################
packer {
  required_version = ">= 1.8.0"

  required_plugins {
    proxmox = {
      version = "1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

#########################################
# Variables
#########################################
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "vm_name" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type = string
}

variable "memory" {
  type    = number
  default = 2048
}

variable "cores" {
  type    = number
  default = 2
}

variable "sockets" {
  type    = number
  default = 1
}

variable "iso_file" {
  type    = string
  default = "local:iso/debian-12.9.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha512:9ebe405c3404a005ce926e483bc6c6841b405c4d85e0c8a7b1707a7fe4957c617ae44bd807a57ec3e5c2d3e99f2101dfb26ef36b3720896906bdc3aaeec4cd80"
}

#########################################
# Source : Proxmox ISO Builder
#########################################
source "proxmox-iso" "debian12-docker" {

  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                     = var.proxmox_node
  vm_id                    = var.vm_id
  vm_name                  = var.vm_name
  template_name            = var.vm_name
  template_description     = "Debian 12 with Docker ready to use (${timestamp()})"

  onboot                   = true

  # ISO boot config
  boot_iso {
    type         = "scsi"
    iso_file     = var.iso_file
    iso_checksum = var.iso_checksum
    unmount      = true
  }

  boot                 = "order=scsi0;scsi1;net0"
  boot_wait            = "10s"

boot_command = [
  "<esc><wait>",
  "auto ",
  "priority=critical ",
  "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
  "<enter>"
]



  http_directory       = "http"
 http_bind_address     = "192.168.1.124"
  http_port_min        = 8098
  http_port_max        = 8098

  # Hardware
  memory               = var.memory
  cores                = var.cores
  sockets              = var.sockets

  # Disk config
  disks {
    type          = "scsi"
    disk_size     = "20G"
    storage_pool  = "local-lvm"
    format        = "raw"
    cache_mode    = "writeback"
    discard       = true
    ssd           = true
  }

  scsi_controller = "virtio-scsi-pci"


  # Network config
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr1"
    firewall = false
  }

  # Cloud Init
  cloud_init                 = true
  cloud_init_storage_pool    = "local-lvm"
  cloud_init_disk_type       = "scsi"

  # Enable QEMU Agent
  qemu_agent                 = true

  # Communicator SSH
  communicator               = "ssh"
  ssh_username               = var.ssh_username
  ssh_password               = var.ssh_password
  ssh_timeout                = "30m"
  ssh_pty                    = true
  ssh_handshake_attempts     = 15
}

#########################################
# Build Section
#########################################
build {

  name    = "debian12-docker-template"
  sources = [
    "source.proxmox-iso.debian12-docker"
  ]

  # Cloud-init readiness check
  provisioner "shell" {
    inline = [
      "systemctl enable cloud-init",
      "cloud-init clean --logs",
      "cloud-init status --wait"
    ]
  }

  # Docker install + setup
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y ca-certificates curl gnupg lsb-release",
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt-get update",
      "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "systemctl enable docker"
    ]
  }

  # Cleanup image
  provisioner "shell" {
    inline = [
      "rm -f /etc/ssh/ssh_host_*",
      "truncate -s 0 /etc/machine-id",
      "apt -y autoremove --purge",
      "apt -y clean",
      "apt -y autoclean",
      "cloud-init clean --logs",
      "rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sync"
    ]
  }

  # Cloud-init extra config file
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = [
      "cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"
    ]
  }
}

