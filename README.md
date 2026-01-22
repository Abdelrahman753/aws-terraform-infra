# Terraform AWS Infrastructure 

A comprehensive Infrastructure as Code (IaC) project using Terraform to provision a complete AWS infrastructure with VPC, subnets, security groups, EC2 instances, Internet Gateway, routing, and Ansible provisioning.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Modules](#modules)
- [Prerequisites](#prerequisites)
- [Configuration Files](#configuration-files)
- [How It Works](#how-it-works)
- [Deployment Guide](#deployment-guide)
- [Variables](#variables)
- [Outputs](#outputs)
- [Important Notes](#important-notes)

---

## 🎯 Project Overview

This Terraform project automates the deployment of a production-ready AWS infrastructure. It provisions:

- **VPC (Virtual Private Cloud)** - Isolated network environment
- **Subnet** - Network segments within the VPC
- **EC2 Instances** - Virtual servers (configurable count)
- **Security Groups** - Firewall rules for network access
- **Internet Gateway (IGW)** - Route traffic to the internet
- **Route Tables** - Define routing rules for traffic
- **Ansible Integration** - Automatic configuration of EC2 instances

The infrastructure supports multi-environment deployments (development, production) with dynamic security rules based on environment.

---

## 🏗️ Architecture
![Architecture Diagram](diagram.drawio.svg)

The diagram below illustrates the high-level AWS infrastructure and how the modules relate:

- **VPC:** An isolated virtual network that contains all resources.
- **Subnets:** Network segments inside the VPC where EC2 instances are launched.
- **Internet Gateway (IGW):** Attached to the VPC to allow internet access for public subnets.
- **Route Table:** Routes outbound traffic (0.0.0.0/0) via the IGW and is associated with the subnet.
- **Security Group:** Firewall rules that allow SSH and application traffic to the EC2 instances.
- **EC2 Instances:** Launched in the subnet, assigned public IPs, and configured via Ansible.
- **Ansible Provisioning:** Terraform generates an inventory from EC2 public IPs and runs the playbook to configure instances after launch.

Arrows in the diagram indicate creation order and data flow (for example: VPC → Subnet → EC2; EC2 → Ansible inventory).

## 📁 Project Structure

```
lab3/
├── root-module.tf              # Main module orchestration
├── variables.tf                # Input variables
├── locals.tf                   # Local values and computed variables
├── data.tf                     # Data sources (e.g., AMI lookup)
├── backend.tf                  # Terraform state backend (S3)
├── provuder.tf                 # AWS provider configuration
├── terraform.tfvars            # Variable values (development)
├── 1-terraform.tfvars          # Alternate variable values
├── terraform.tfvars.json       # JSON format variable values
│
├── vpc_module/                 # VPC Module
│   ├── vpc.tf                  # VPC resource
│   ├── variables.tf            # Module variables
│   └── output.tf               # Module outputs
│
├── subnet_module/              # Subnet Module
│   ├── subnet.tf               # Subnet resource
│   ├── variable.tf             # Module variables
│   └── output.tf               # Module outputs
│
├── ec2-module/                 # EC2 Module
│   ├── ec2.tf                  # EC2 instances & key pair
│   ├── vaeiables.tf            # Module variables
│   └── output.tf               # Module outputs
│
├── security_group/             # Security Group Module
│   ├── security_group.tf       # Security group with dynamic rules
│   ├── variables.tf            # Module variables
│   └── output.tf               # Module outputs
│
├── IGW/                        # Internet Gateway Module
│   ├── IGW.tf                  # Internet Gateway resource
│   ├── variable.tf             # Module variables
│   └── outputs.tf              # Module outputs
│
├── route_table/                # Route Table Module
│   ├── route_table.tf          # Route table with dynamic routes
│   ├── variables.tf            # Module variables
│   └── outputs.tf              # Module outputs
│
└── ansible/                    # Ansible Integration
    ├── main.tf                 # Inventory generation & provisioning
    ├── playbook.yaml           # Ansible tasks
    ├── variables.tf            # Module variables
    └── invintory.ini           # Generated inventory file
```

---

## 🧩 Modules Explained

### 1. **VPC Module** (`vpc_module/`)

Creates an isolated network environment in AWS.

**How it works:**
- Creates an AWS VPC with specified CIDR block
- Tags it with project name and environment
- Contains commented lifecycle rule to prevent accidental destruction

**Inputs:**
- `cidr_block` - CIDR notation (e.g., "10.0.0.0/16")
- `project_name` - Name for tagging
- `env` - Environment label

**Output:**
- `vpc_id` - VPC identifier

**Key Code:**
```terraform
resource "aws_vpc" "imported_vpc" {
    cidr_block = var.cidr_block
    tags = {
        Name        = var.project_name
        Environment = var.env
    }
}
```

---

### 2. **Subnet Module** (`subnet_module/`)

Creates a subnet within the VPC.

**How it works:**
- Creates a subnet with specified CIDR block
- Associates with the VPC via `vpc_id`
- Places in a specific availability zone

**Inputs:**
- `vpc_id` - VPC to place subnet in
- `subnet_cider` - Subnet CIDR block (typo in variable name)
- `region` - AWS region

**Output:**
- `subnet_id` - Subnet identifier

**Key Code:**
```terraform
resource "aws_subnet" "subnet1" {
    vpc_id            = var.vpc_id
    cidr_block        = var.subnet_cider
    availability_zone = "${var.region}a"  # Zone a of specified region
}
```

---

### 3. **EC2 Module** (`ec2-module/`)

Provisions EC2 instances and SSH key pair.

**How it works:**
- Creates configurable number of EC2 instances using `count`
- Generates SSH key pair from existing public key
- Enables public IP assignment for instances
- Instances are tagged with environment, project, and owner info

**Inputs:**
- `base_instance_count` - Number of instances to create
- `ami` - Amazon Machine Image ID (Ubuntu)
- `instance_type` - Instance type (e.g., "t2.micro")
- `subnet_id` - Subnet for instances
- `security_group_id` - Security group to attach
- `key_name` - SSH key pair name
- `project_name`, `env`, `owner` - Tagging

**Output:**
- `ec2-ip` - Public IP addresses of all instances

**Key Code:**
```terraform
resource "aws_instance" "ec2_instance" {
    count = var.base_instance_count
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id     = var.subnet_id
    vpc_security_group_ids = [var.security_group_id]
    key_name      = var.key_name
    associate_public_ip_address = true
    tags = {
        Name    = "${var.env}-ec2-instance-${count.index + 1}"
        Project = var.project_name
        Owner   = var.owner
    }
}

resource "aws_key_pair" "ec2_key" {
    key_name   = "terraform-key"
    public_key = file("/home/abdo/.ssh/id_rsa.pub")
}
```

---

### 4. **Security Group Module** (`security_group/`)

Manages firewall rules for network traffic.

**How it works:**
- Creates security group with dynamic ingress and egress rules
- Supports multiple rules defined as list of objects
- Uses `dynamic` blocks for flexible rule configuration

**Inputs:**
- `Security-name` - Name of the security group
- `vpc_id` - VPC to attach to
- `ingress_rules` - List of inbound rules
- `egress_rules` - List of outbound rules
- `env` - Environment label

**Output:**
- `security_group_id` - Security group identifier

**Key Code:**
```terraform
resource "aws_security_group" "Security-group" {
    name   = "SG-${var.Security-name}"
    vpc_id = var.vpc_id

    dynamic "ingress" {
        for_each = var.ingress_rules
        content {
            from_port   = ingress.value.from_port
            to_port     = ingress.value.to_port
            protocol    = ingress.value.protocol
            cidr_blocks = ingress.value.cidr_blocks
        }
    }

    dynamic "egress" {
        for_each = var.egress_rules
        content {
            from_port   = egress.value.from_port
            to_port     = egress.value.to_port
            protocol    = egress.value.protocol
            cidr_blocks = egress.value.cidr_blocks
        }
    }
}
```

---

### 5. **Internet Gateway (IGW) Module** (`IGW/`)

Enables communication between VPC and the internet.

**How it works:**
- Creates an Internet Gateway
- Attaches it to the VPC
- Allows traffic from VPC to reach the internet

**Inputs:**
- `vpc_id` - VPC to attach to
- `name` - Name tag

**Output:**
- `igw_id` - Internet Gateway identifier

**Key Code:**
```terraform
resource "aws_internet_gateway" "gw" {
    vpc_id = var.vpc_id
    tags = {
        Name = var.name
    }
}
```

---

### 6. **Route Table Module** (`route_table/`)

Defines routing rules for traffic within the VPC.

**How it works:**
- Creates route table with dynamic routes
- Each route specifies destination CIDR and gateway
- Associates route table with specified subnets
- Routes traffic from instances to Internet Gateway

**Inputs:**
- `vpc_id` - VPC to create route table in
- `name` - Name tag
- `routes` - List of route definitions
- `subnet_ids` - Subnets to associate with

**Output:**
- `route_table_id` - Route table identifier

**Key Code:**
```terraform
resource "aws_route_table" "public" {
    vpc_id = var.vpc_id

    dynamic "route" {
        for_each = var.routes
        content {
            cidr_block     = route.value.cidr_block
            gateway_id     = lookup(route.value, "gateway_id", null)
            nat_gateway_id = lookup(route.value, "nat_gateway_id", null)
        }
    }
}

resource "aws_route_table_association" "this" {
    for_each = toset(var.subnet_ids)
    subnet_id      = each.value
    route_table_id = aws_route_table.public.id
}
```

---

### 7. **Ansible Module** (`ansible/`)

Automatically configures EC2 instances after creation.

**How it works:**
- Generates Ansible inventory file from EC2 public IPs
- Waits 180 seconds for instances to be ready (SSH service startup)
- Runs Ansible playbook to configure instances
- Uses local-exec provisioner to execute commands on deployment machine

**Inputs:**
- `public_ips` - List of EC2 public IP addresses

**Key Code:**
```terraform
resource "local_file" "inventory" {
    filename = "${path.module}/inventory.ini"
    content  = <<-EOT
[web]
%{for idx, ip in var.public_ips~}
web${idx + 1} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/abdo/.ssh/id_rsa
%{endfor~}
EOT
}

resource "null_resource" "provision_ec2" {
    provisioner "local-exec" {
        command = "sleep 180 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/inventory.ini ${path.module}/playbook.yaml -f 1 -v"
    }
}
```

---

## 📝 Configuration Files

### **root-module.tf**

Orchestrates all modules and defines dependencies.

**Key Functions:**
- Instantiates all modules with proper input variables
- Defines module dependencies using `depends_on`
- Establishes data flow between modules

**Module Chain:**
1. VPC Module (creates base network)
2. Subnet Module (depends on VPC)
3. Security Group Module (depends on VPC)
4. EC2 Module (depends on Subnet & Security Group)
5. IGW Module (depends on VPC)
6. Route Table Module (depends on VPC & IGW)
7. Ansible Module (depends on EC2)

---

### **variables.tf**

Defines all input variables for the project.

**Key Variables:**
- `region` - AWS region for deployment
- `access_key` - AWS access credentials
- `secret_key` - AWS secret credentials
- `cidr_block` - VPC CIDR notation
- `subnet_cidr` - Subnet CIDR notation
- `instance_type` - EC2 instance type
- `base_instance_count` - Number of EC2 instances
- `env` - Environment (production/development)
- `project_name`, `vpc_name`, `owner` - Naming

---

### **locals.tf**

Defines computed values and configuration constants.

**Key Locals:**
```terraform
locals {
    security_group_name = "my_security_group"
    vpc_id              = module.imported_vpc.vpc_id
    key_name            = "terraform-key"

    # Environment-based port selection
    allowed_ports = var.env == "production" ? 
        var.allowed_ports_map["https"] :  # Port 443
        var.allowed_ports_map["http"]     # Port 80

    # Ingress rules (SSH + HTTP/HTTPS based on env)
    ingress_rules = [
        {
            from_port   = local.allowed_ports
            to_port     = local.allowed_ports
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]

    # Egress rules (allow all outbound traffic)
    egress_rules = [
        {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]
}
```

---

### **data.tf**

Fetches data sources from AWS.

**Ubuntu AMI Lookup:**
```terraform
data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"]  # Canonical (Ubuntu owner)
    
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}
```

**Why?** Automatically uses latest Ubuntu AMI without hardcoding ID.

---

### **backend.tf**

Configures Terraform state storage.

**S3 Backend:**
```terraform
terraform {
    backend "s3" {
        bucket = "nti-state-bucket"
        key    = "terraform/terraform.tfstate"
        region = "us-east-1"
    }
}
```

**Benefits:**
- State stored remotely (not on local machine)
- Team collaboration enabled
- State versioning and protection
- Prevents accidental state loss

---

### **provuder.tf**

Configures AWS provider.

**Primary Provider (us-east-1):**
```terraform
provider "aws" {
    region     = var.region
    access_key = var.access_key
    secret_key = var.secret_key
}
```

**Secondary Provider (us-east-2) - Not used in this project:**
```terraform
provider "aws" {
    alias      = "vpc2"
    region     = "us-east-2"
    access_key = var.access_key
    secret_key = var.secret_key
}
```

---

## 🔄 How It Works

### Deployment Flow:

1. **Initialization Phase**
   ```bash
   terraform init
   ```
   - Downloads required providers (AWS, local, null)
   - Initializes backend connection (S3)
   - Creates `.terraform` directory

2. **VPC Setup**
   - Creates VPC with CIDR block (e.g., 10.0.0.0/16)
   - Stores VPC ID in outputs

3. **Network Creation**
   - Creates subnet in availability zone (e.g., us-east-1a)
   - Subnet CIDR block is subset of VPC (e.g., 10.0.1.0/24)

4. **Security Configuration**
   - Creates security group with:
     - Inbound: SSH (22), HTTP/HTTPS (80 or 443 based on env)
     - Outbound: All traffic allowed
   - Uses `locals.tf` for environment-based port selection

5. **Internet Connectivity**
   - Creates Internet Gateway
   - Attaches to VPC
   - Creates route table with default route (0.0.0.0/0) → IGW
   - Associates route table with subnet

6. **EC2 Instance Launch**
   - Looks up latest Ubuntu AMI
   - Creates SSH key pair (uses existing public key)
   - Launches EC2 instances (count = base_instance_count)
   - Assigns public IPs
   - Applies security group

7. **Provisioning**
   - Extracts EC2 public IPs
   - Generates Ansible inventory file
   - Waits 180 seconds for SSH to be ready
   - Runs Ansible playbook to configure instances

### Data Dependencies:

```
variables.tf → locals.tf → root-module.tf
                  ↓
              VPC Module
                  ↓
     ┌────────────┴────────────┐
     ↓                          ↓
Subnet Module          Security Group Module
     ↓                          ↓
     └────────────┬────────────┘
                  ↓
            EC2 Module
                  ↓
            Ansible Module
```

---

## 🚀 Deployment Guide

### Prerequisites

- Terraform installed (v1.0+)
- AWS account with credentials
- AWS CLI configured
- SSH key pair generated (`~/.ssh/id_rsa.pub`)
- Ansible installed (for provisioning)
- S3 bucket created for Terraform state

### Step 1: Configure Variables

Create or edit `terraform.tfvars`:

```hcl
region                = "us-east-1"
access_key            = "YOUR_AWS_ACCESS_KEY"
secret_key            = "YOUR_AWS_SECRET_KEY"
cidr_block            = "10.0.0.0/16"
subnet_cidr           = "10.0.1.0/24"
instance_type         = "t2.micro"
vpc_name              = "lab3-vpc"
base_instance_count   = 2
env                   = "development"
project_name          = "lab3-project"
owner                 = "your-name"
allowed_ports_map     = {
    "http"  = 80
    "https" = 443
}
```

### Step 2: Initialize Terraform

```bash
cd /home/abdo/nti/terraform/lab3
terraform init
```

### Step 3: Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the execution plan to see what resources will be created.

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

Wait for completion (typically 5-10 minutes).

### Step 5: Verify Deployment

```bash
terraform output
```

View created resources and EC2 IPs.

### Step 6: Access EC2 Instances

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
```

### Cleanup: Destroy Infrastructure

```bash
terraform destroy
```

Confirm when prompted.

---

## 📤 Outputs

After `terraform apply`, use `terraform output` to view:

- **VPC ID** - Created VPC identifier
- **Subnet ID** - Created subnet identifier
- **EC2 IPs** - Public IP addresses of instances
- **Security Group ID** - Created security group identifier
- **IGW ID** - Internet Gateway identifier

---

## ⚙️ Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `region` | string | AWS region | `"us-east-1"` |
| `access_key` | string | AWS access key | `"AKIA..."` |
| `secret_key` | string | AWS secret key | `"wJal..."` |
| `cidr_block` | string | VPC CIDR block | `"10.0.0.0/16"` |
| `subnet_cidr` | string | Subnet CIDR block | `"10.0.1.0/24"` |
| `instance_type` | string | EC2 instance type | `"t2.micro"` |
| `vpc_name` | string | VPC name | `"lab3-vpc"` |
| `base_instance_count` | number | Number of EC2s | `2` |
| `env` | string | Environment | `"development"` |
| `project_name` | string | Project name | `"lab3-project"` |
| `owner` | string | Resource owner | `"abdo"` |
| `allowed_ports_map` | map | Port mapping | `{http=80, https=443}` |

---

## ⚠️ Important Notes

1. **AWS Credentials**: Store credentials securely. Never commit to version control.

2. **SSH Key**: Ensure `/home/abdo/.ssh/id_rsa.pub` exists before deployment.

3. **S3 Backend**: The bucket `nti-state-bucket` must exist in `us-east-1`.

4. **Costs**: This infrastructure will incur AWS charges. Use `terraform destroy` when not needed.

5. **Typo Alert**: There's a typo in `ec2-module/vaeiables.tf` (should be `variables.tf`).

6. **Environment-Based Security**: 
   - Production = HTTPS (443)
   - Development = HTTP (80)
   - SSH always enabled (22)

7. **SSH Access**: All ingress rules allow from `0.0.0.0/0` (anywhere). Restrict in production.

8. **Lifecycle Rules**: Commented out lifecycle rules can be uncommented for:
   - VPC: Prevent accidental destruction
   - EC2: Create before destroy for zero downtime

9. **Ansible Provisioning**: 180-second wait allows EC2 SSH service to start.

10. **Module Dependencies**: `depends_on` explicitly defines creation order.

