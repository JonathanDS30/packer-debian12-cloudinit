# 🐧 Packer Proxmox Debian 12 Cloud-Init Template

This repository contains a **Packer** project designed to automate the creation of a **Debian 12.9** virtual machine template for **Proxmox VE**. The template is fully compatible with **Cloud-Init**, making it easy to deploy and configure new VMs dynamically with minimal effort.

> ⚡️ **No Ansible used!**  
> Everything is handled by Packer and Cloud-Init configuration to keep the process simple and efficient.

---

## 🚀 Project Overview

This project builds a **Debian 12.9** image and converts it into a **Cloud-Init–ready Proxmox template**. The template can then be cloned to deploy multiple VMs with custom user credentials, SSH keys, network configurations, and more.

### Key Features
- ✅ Automated Debian 12.9 installation using **preseed**.
- ✅ Cloud-Init pre-configured for **dynamic provisioning** (user credentials, networking, SSH keys).
- ✅ Proxmox **optimized** VM template, ready to deploy.
- ✅ Separate variable files for **credentials** and **configuration**, following **best practices**.
- ✅ Easy customization: ISO path, HTTP bind address, VM specs, etc. via variables.

---

## 🏗️ How It Works

- **Packer** builds a Proxmox VM from an ISO.
- Debian is installed automatically using a **preseed.cfg** file.
- Cloud-Init is pre-configured (via `99-pve.cfg`).
- Once the VM is provisioned, it's converted into a reusable **Proxmox template**.

---

## 📁 Project Structure

```
.
│   .gitignore                        # Git ignore rules (excluding sensitive files like credentials)
│   debian12-docker.pkr.hcl          # Main Packer configuration file
│   LICENSE                          # Project license (MIT or other)
│   README.md                        # Project documentation
│   template-credentials.pkrvars.hcl # Template credentials example file (safe to share)
│   template-variables.pkrvars.hcl   # Template variables example file (safe to share)
│   variables.pkrvars.hcl            # Non-sensitive project variables (Proxmox config, VM specs, etc.)
│
├───files
│       99-pve.cfg                   # Cloud-Init default configuration (user and datasource setup)
│
├───http
│       preseed.cfg                  # Preseed file for automated Debian 12 installation (unattended install)


```

## 🔧 Prerequisites

- Proxmox VE 7.x or later.
- Packer **v1.8.0+** installed.
- Debian 12.9 ISO uploaded to your Proxmox storage.
- Proxmox API Token with appropriate permissions.
- Linux/MacOS/WSL environment (preferred for running Packer).

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/JonathanDS30/packer-debian12-cloudinit.git
cd packer-debian12-cloudinit
```

### 2. Initialize Packer
```
packer init .
```

### 3. Create your variables files

Start by **renaming the example files** provided in the repository:
```
cp template-credentials.pkrvars.hcl credentials.pkrvars.hcl
cp template-variables.pkrvars.hcl variables.pkrvars.hcl
```


#### `credentials.pkrvars.hcl`

```
proxmox_api_token_id     = "root@pam!packer"
proxmox_api_token_secret = "YOUR_SECRET_TOKEN"
```

> ⚠️ **Never commit this file!**  
> It contains your **Proxmox API credentials**, which are sensitive information.

#### `variables.pkrvars.hcl`

This file contains the **configuration of your Proxmox environment** and **VM template settings**.  
You should **update the placeholder values** with your actual setup.

```
# Proxmox API connection settings
# URL of the Proxmox API endpoint
proxmox_api_url = "https://IP_address:8006/api2/json"

# Name of the Proxmox node where the template will be created
proxmox_node    = "your-node-name-here"

# VM template configuration
vm_id           = 9000                 # Unique identifier for the VM template
vm_name         = "your-vm-name-here"  # Name of the VM template that will be created

# SSH credentials for provisioning
# These credentials are only used during the build process and should be changed after deployment
ssh_username    = "root"
ssh_password    = "packer"
```

⚠️ **Note**: These SSH credentials are used during the provisioning process.  
You should consider changing or removing them after deployment to enhance security.

### 4. Validate the configuration
```
packer validate -var-file=variables.pkrvars.hcl -var-file=credentials.pkrvars.hcl debian12-docker.pkr.hcl
```

### 5. Build the Proxmox template
```
packer build -var-file=variables.pkrvars.hcl -var-file=credentials.pkrvars.hcl debian12-docker.pkr.hcl
```

## ☁️ Cloud-Init Ready Template

Once the template is built and registered in Proxmox, you can clone it and configure:

- **ciuser** (user)
- **cipassword** or SSH keys
- **ipconfig0** (network config)
- **DNS, hostname, and more...**

### Example Proxmox CLI to deploy from the template:
```
qm clone 9000 9100 --name my-debian12-vm --full
qm set 9100 --ciuser devops --cipassword MySecurePass
qm set 9100 --ipconfig0 ip=192.168.1.101/24,gw=192.168.1.1
qm start 9100
```

## 🙌 Credits

Created with ❤️ by JonathanDS30
Built for personal learning and lab automation on **Proxmox VE**.