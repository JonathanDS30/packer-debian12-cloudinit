# Proxmox API connection settings
# URL of the Proxmox API endpoint
proxmox_api_url = "https://192.168.1.253:8006/api2/json"

# Name of the Proxmox node where the template will be created
proxmox_node    = "SRV-PMX"

# VM template configuration
vm_id           = 9000                # Unique identifier for the VM template
vm_name         = "Debian-12-Docker"  # Name of the VM template that will be created

# SSH credentials for provisioning
# These credentials are only used during the build process and should be changed after deployment
ssh_username    = "root"
ssh_password    = "packer"
