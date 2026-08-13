# Operations Documentation

This document covers deployment procedures, variable configuration, troubleshooting, and day-to-day operations of the Terraform Enterprise development environment.

## Pre-Deployment Checklist

Before deploying, ensure the following are in place:

- [ ] **AWS Account Access**
  - AWS credentials configured (environment variables, credentials file, or IAM role)
  - Appropriate IAM permissions (see Prerequisites section)
  
- [ ] **Terraform Installation**
  - Terraform ≥ 0.12 installed and available in PATH
  - `terraform` command works: `terraform version`

- [ ] **SSH Key Pair**
  - Local SSH key exists (e.g., `~/.ssh/id_rsa`)
  - If not: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""`

- [ ] **Route53 Zone**
  - Pre-existing hosted zone in AWS Route53 (example: `connor-fryar.sbx.hashidemos.io`)
  - Zone must be accessible to AWS account running Terraform

- [ ] **Docker Hub Credentials**
  - Credentials for `images.releases.hashicorp.com` (HashiCorp's Docker registry)
  - Will need these later when starting TFE container

- [ ] **TFE License**
  - Valid Terraform Enterprise license key (string or file path)
  - Must provide this to `docker-compose.yaml` before container starts

## Deployment Walkthrough

### Step 1: Prepare Working Directory

```bash
cd /path/to/terraform-enterprise-dev-env
```

### Step 2: Initialize Terraform

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Finding hashicorp/random versions matching "3.7.2"...
- Installing hashicorp/aws v6.27.0...
- Installing hashicorp/random v3.7.2...
...
Terraform has been successfully initialized!
```

**What This Does:**
- Downloads provider plugins to `.terraform/` directory
- Creates `.terraform.lock.hcl` if not present (or uses existing)
- Initializes backend (local by default)

### Step 3: Configure Variables

Create `terraform.tfvars` file with required variables:

```bash
cat > terraform.tfvars << 'EOF'
# Required variables
subdomain  = "docker"
public_key = file("~/.ssh/id_rsa.pub")

# Optional variables (showing defaults; uncomment to override)
# InstanceName         = "deprecated"
# InstanceType         = "t3.medium"
# EBSSize              = 50
# EBSType              = "gp3"
# yourname             = "connor-fryar"
# domain               = "sbx.hashidemos.io"
# availability_zone    = "us-east-1a"
EOF
```

**Required Variables:**
- **subdomain:** Subdomain prefix for Route53 record (e.g., "docker" → "docker.connor-fryar.sbx.hashidemos.io")
- **public_key:** SSH public key for EC2 access (use `file()` function to read local file)

**Optional Variables:**
- **InstanceType:** EC2 instance type (default: "t3.medium")
- **EBSSize:** EBS volume size in GiB, < 100 (default: 50)
- **EBSType:** EBS volume type (default: "gp3")
- **yourname:** Name/identity part of domain (default: "connor-fryar")
- **domain:** Base Route53 domain (default: "sbx.hashidemos.io")
- **availability_zone:** AWS AZ for instance (default: "us-east-1a")

**⚠️ Important:**
- `terraform.tfvars` is excluded by `.gitignore` (good for security)
- Never commit sensitive values to Git

### Step 4: Validate Configuration

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

**Troubleshooting:**
- If validation fails, check `var.tf` for required variables and `terraform.tfvars` for values
- Ensure Route53 zone exists in AWS (data source will fail during plan if not)

### Step 5: Format Check

```bash
terraform fmt -check
```

**Expected Output:**
```
(no output = success, code 0)
```

**Alternative (auto-fix):**
```bash
terraform fmt -recursive  # Fix all .tf files
```

### Step 6: Generate Execution Plan

```bash
terraform plan
```

**Expected Output:**
```
Terraform will perform the following actions:

  # aws_internet_gateway.gw will be created
  + resource "aws_internet_gateway" "gw" {
      + id  = (known after apply)
      + vpc_id = (known after apply)
      ...
    }

  # ... (many more resources)

Plan: 24 to add, 0 to change, 0 to destroy.
```

**Review Carefully:**
- Verify resource counts match expectations (~24 resources)
- Check AMI ID is for Ubuntu 24.04 amd64
- Verify domain name is correct

**Save Plan to File (optional):**
```bash
terraform plan -out=tfplan
```

### Step 7: Apply Configuration

```bash
terraform apply
```

**Interactive Prompt:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

**Or Apply Saved Plan (non-interactive):**
```bash
terraform apply tfplan
```

**Expected Duration:** 3-5 minutes for resource creation

**Expected Output:**
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-0123456789abcdef0]
aws_subnet.mainSubnet: Creating...
...
random_pet.pet: Creating...
random_pet.pet: Creation complete after 0s [id=sunny-badger]
aws_instance.TestInstanceInstance: Creating...
aws_instance.TestInstanceInstance: Still creating... [10s elapsed]
aws_instance.TestInstanceInstance: Still creating... [20s elapsed]
...
aws_instance.TestInstanceInstance: Creation complete after 45s [id=i-0123456789abcdef0]
aws_route53_record.ARecordTestInstance: Creating...
aws_route53_record.ARecordTestInstance: Creation complete after 1s [domain_name=docker.connor-fryar.sbx.hashidemos.io]

Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
```

### Step 8: Retrieve Outputs

```bash
terraform output
```

**Expected Output:**
```
AMI_Data = {
  "architecture" = "x86_64"
  "id" = "ami-0123456789abcdef0"
  ...
}
Instance_data = {
  "ami" = "ami-0123456789abcdef0"
  "availability_zone" = "us-east-1a"
  "private_ip" = "10.0.10.42"
  "public_ip" = "203.0.113.42"
  ...
}
domain_name = "deprecated"
public_ip_address = "203.0.113.42"
route53 = {
  "id" = "Z0123456789ABCDEF"
  "name" = "connor-fryar.sbx.hashidemos.io"
  ...
}
```

**Useful Outputs:**
- `public_ip_address`: Use for SSH access
- `domain_name`: User-friendly identifier
- `Instance_data.public_ip`: Same as `public_ip_address`

### Step 9: Connect to Instance

```bash
# Get public IP
PUBLIC_IP=$(terraform output -raw public_ip_address)

# SSH into instance
ssh -i ~/.ssh/id_rsa ubuntu@${PUBLIC_IP}
```

**Expected:**
```
ubuntu@sunny-badger:~$
```

You're now connected to the EC2 instance.

### Step 10: Verify Setup

On the connected instance, verify Docker and Certbot:

```bash
# Check Docker installation
docker --version
# Expected: Docker version 20.10.x or later

# Check Certbot installation
certbot --version
# Expected: certbot 2.x.x or later

# Check certificates were created
sudo ls -la /etc/letsencrypt/live/docker.connor-fryar.sbx.hashidemos.io/
# Expected: fullchain.pem, privkey.pem, chain.pem, cert.pem
```

### Step 11: Configure Docker Compose

The `docker-compose.yaml` file requires configuration before TFE container starts:

```bash
# On the EC2 instance
# 1. Create directories for TFE data
mkdir -p certs data

# 2. Copy Certbot certificates to certs directory
sudo cp /etc/letsencrypt/live/docker.connor-fryar.sbx.hashidemos.io/fullchain.pem certs/cert.pem
sudo cp /etc/letsencrypt/live/docker.connor-fryar.sbx.hashidemos.io/fullchain.pem certs/bundle.pem
sudo cp /etc/letsencrypt/live/docker.connor-fryar.sbx.hashidemos.io/privkey.pem certs/key.pem

# 3. Set permissions
sudo chown -R ubuntu:ubuntu certs/
```

Edit `docker-compose.yaml` to provide required environment variables:

```yaml
environment:
  TFE_LICENSE: "your-license-key-here"  # ← Required
  TFE_HOSTNAME: "docker.connor-fryar.sbx.hashidemos.io"  # ← Required
  TFE_ENCRYPTION_PASSWORD: 'your-secure-password-here'  # ← Required (long, random)
  # ... rest of config
```

**Required Variables:**
- **TFE_LICENSE:** Base64-encoded license string (from Terraform Enterprise account)
- **TFE_HOSTNAME:** Fully qualified domain name (must match DNS record)
- **TFE_ENCRYPTION_PASSWORD:** Strong encryption key for TFE data (generate: `openssl rand -hex 32`)

### Step 12: Authenticate with Docker Registry

```bash
# Log in to HashiCorp Docker registry
docker login images.releases.hashicorp.com

# Provide credentials:
# Username: terraform
# Password: (your token from HashiCorp account)
```

### Step 13: Start TFE Container

```bash
# Navigate to directory containing docker-compose.yaml
cd /path/to/docker-compose.yaml

# Start container
docker-compose up -d

# Check container status
docker ps
```

**Expected Output:**
```
CONTAINER ID   IMAGE                              COMMAND              STATUS              PORTS
abc123def456   .../terraform-enterprise:#.#.#     "/entrypoint.sh"     Up 2 minutes        0.0.0.0:80->80/tcp, ...
```

### Step 14: Access TFE

Once container is running:

1. **Web UI:** `https://docker.connor-fryar.sbx.hashidemos.io/`
   - Initial setup wizard should appear
   - Accept SSL certificate warning (self-signed or Let's Encrypt)

2. **Admin Console:** `https://docker.connor-fryar.sbx.hashidemos.io:8443/`
   - Requires IACT (Initial Admin Creation Token)
   - Get token: `docker exec -it $(docker ps -aq) /bin/bash -c 'echo https://${TFE_HOSTNAME}/admin/account/new?token=$(tfectl admin token)'`

3. **Retrieve Admin Token:**
   ```bash
   docker exec -it $(docker ps -aq) /bin/bash -c 'echo https://${TFE_HOSTNAME}/admin/account/new?token=$(tfectl admin token)'
   ```

   **Output Example:**
   ```
   https://docker.connor-fryar.sbx.hashidemos.io/admin/account/new?token=absQSKDL.atlasv1.FhcWFPZQ8Xk7...
   ```

   Visit this URL in browser to create initial admin user.

## Input Variables Reference

Complete reference of all input variables:

### EC2 Instance Variables

#### `InstanceName`
- **Type:** `string`
- **Default:** `"deprecated"`
- **Required:** No
- **Description:** Display name for EC2 instance
- **Example:** `InstanceName = "terraform-enterprise-dev"`

#### `InstanceType`
- **Type:** `string`
- **Default:** `"t3.medium"`
- **Required:** No
- **Description:** EC2 instance type
- **Valid Values:** Any AWS instance type (recommended: t3.medium or larger for TFE)
- **Examples:**
  ```hcl
  InstanceType = "t3.medium"    # 2 vCPU, 8 GiB (default, dev/test)
  InstanceType = "t3.large"     # 2 vCPU, 8 GiB (alternative)
  InstanceType = "t3.xlarge"    # 4 vCPU, 16 GiB (more powerful)
  ```

### EBS Volume Variables

#### `EBSSize`
- **Type:** `number`
- **Default:** `50`
- **Required:** No
- **Description:** Root EBS volume size in GiB
- **Constraints:** Must be < 100 (validation rule enforced)
- **Examples:**
  ```hcl
  EBSSize = 50    # 50 GiB (default, suitable for dev)
  EBSSize = 100   # Would fail validation (must be < 100)
  ```

#### `EBSType`
- **Type:** `string`
- **Default:** `"gp3"`
- **Required:** No
- **Description:** EBS volume type
- **Valid Values:** `"gp2"`, `"gp3"`, `"io1"`, `"io2"`
- **Recommendations:**
  ```hcl
  EBSType = "gp3"   # General purpose (default, good for dev)
  EBSType = "gp2"   # Older general purpose, less flexible
  EBSType = "io1"   # High IOPS (expensive, not needed for dev)
  ```

### Route53 / DNS Variables

#### `subdomain` ⚠️ **Required**
- **Type:** `string`
- **Default:** None (must be provided)
- **Required:** **Yes**
- **Description:** Subdomain portion of Route53 record
- **Used In:** `${subdomain}.${yourname}.${domain}`
- **Example:**
  ```hcl
  subdomain = "docker"
  # Results in: docker.connor-fryar.sbx.hashidemos.io
  ```

#### `yourname`
- **Type:** `string`
- **Default:** `"connor-fryar"`
- **Required:** No
- **Description:** Name/identity portion of domain
- **Used In:** `${subdomain}.${yourname}.${domain}`
- **Example:**
  ```hcl
  yourname = "myname"
  # Results in: docker.myname.sbx.hashidemos.io
  ```

#### `domain`
- **Type:** `string`
- **Default:** `"sbx.hashidemos.io"`
- **Required:** No
- **Description:** Base Route53 hosted zone domain
- **Important:** Must match a pre-existing Route53 zone in AWS account
- **Example:**
  ```hcl
  domain = "sbx.hashidemos.io"
  # Pre-existing zone: sbx.hashidemos.io (must exist)
  ```

**Domain Construction Example:**
```hcl
# Input variables:
subdomain  = "docker"
yourname   = "connor-fryar"
domain     = "sbx.hashidemos.io"

# Computed domain name (local value):
local.domain_name = "docker.connor-fryar.sbx.hashidemos.io"

# Route53 A record points to instance public IP
```

### Infrastructure Placement Variables

#### `availability_zone`
- **Type:** `string`
- **Default:** `"us-east-1a"`
- **Required:** No
- **Description:** AWS availability zone for instance placement
- **Valid Values:** Any AZ in us-east-1 region
- **Examples:**
  ```hcl
  availability_zone = "us-east-1a"  # Default
  availability_zone = "us-east-1b"  # Alternative AZ
  availability_zone = "us-east-1c"  # Another alternative
  ```

### SSH Access Variables

#### `public_key` ⚠️ **Required**
- **Type:** `string`
- **Default:** None (must be provided)
- **Required:** **Yes**
- **Description:** SSH public key for EC2 access
- **Format:** Standard SSH public key (usually contents of `~/.ssh/id_rsa.pub`)
- **Examples:**
  ```hcl
  # Option 1: Read from file
  public_key = file("~/.ssh/id_rsa.pub")

  # Option 2: Inline (not recommended)
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... email@example.com"
  ```

**How to Generate:**
```bash
# If you don't have an SSH key:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# View your public key:
cat ~/.ssh/id_rsa.pub
```

## Outputs Reference

### Primary Outputs

#### `domain_name`
- **Description:** Instance name tag
- **Value:** Variable `InstanceName` (default: "deprecated")
- **Use:** For identifying instance in UI
- **Terraform Reference:** `output.domain_name`

#### `public_ip_address`
- **Description:** EC2 instance public IP address
- **Value:** `aws_instance.TestInstanceInstance.public_ip`
- **Use:** For SSH access and web browser access
- **Example:** `203.0.113.42`
- **Terraform Reference:** `output.public_ip_address`

### Data Outputs

#### `AMI_Data`
- **Description:** AMI metadata for the selected Ubuntu image
- **Contents:**
  ```
  id          - AMI ID (e.g., "ami-0123456789abcdef0")
  architecture - Image architecture ("x86_64" for amd64)
  name        - Full AMI name
  owners      - Owner account
  state       - Image state ("available")
  ```
- **Use:** For debugging AMI selection or creating snapshots

#### `Instance_data`
- **Description:** EC2 instance metadata queried after creation
- **Contents:**
  ```
  ami                 - AMI ID used to launch instance
  availability_zone   - AZ where instance runs
  private_ip          - Private IP in VPC (10.0.10.x range)
  public_ip           - Public IP for internet access
  security_groups     - Attached security group IDs
  subnet_id           - Subnet where instance runs
  vpc_id              - VPC where instance runs
  key_name            - SSH key pair name
  instance_type       - Instance type (t3.medium)
  ```
- **Use:** For debugging and infrastructure verification

#### `route53`
- **Description:** Route53 hosted zone metadata
- **Contents:**
  ```
  id          - Zone ID (e.g., "Z0123456789ABCDEF")
  name        - Zone name ("connor-fryar.sbx.hashidemos.io")
  private_zone - Boolean (false for public)
  nameservers - List of nameservers
  ```
- **Use:** For DNS verification and zone configuration

### Accessing Outputs

```bash
# Show all outputs
terraform output

# Show specific output
terraform output -json domain_name
terraform output -raw public_ip_address

# Access in shell
IP=$(terraform output -raw public_ip_address)
echo "SSH: ssh -i ~/.ssh/id_rsa ubuntu@${IP}"
```

## Troubleshooting

### Plan/Apply Fails with Route53 Zone Not Found

**Error:**
```
Error: No Route53 zones found
```

**Cause:** Pre-existing Route53 zone doesn't exist or name is incorrect

**Solution:**
1. Verify zone exists in AWS console (Route53 > Hosted Zones)
2. Confirm zone name matches `var.domain` in `terraform.tfvars`
3. Check AWS credentials are for correct account

**Verify Zone Exists:**
```bash
aws route53 list-hosted-zones-by-name
# Look for: connor-fryar.sbx.hashidemos.io
```

---

### AMI Lookup Fails

**Error:**
```
Error: no AMI found matching filter criteria
```

**Cause:** HashiCorp Ubuntu AMI not available or filter changed

**Solution:**
1. Verify owner account ID: 888995627335 (in ec2.tf)
2. Check region: us-east-1
3. Verify AMI name pattern: `hc-base-ubuntu-2404-amd64-*`

**Manual AMI Lookup:**
```bash
aws ec2 describe-images \
  --owners 888995627335 \
  --filters "Name=name,Values=hc-base-ubuntu-2404-amd64-*" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1]'
```

---

### SSH Connection Refused

**Error:**
```
ssh: connect to host 203.0.113.42 port 22 refused (Connection refused)
```

**Causes:**
1. EC2 instance still starting (cloud-init running)
2. Security group doesn't allow port 22
3. Wrong IP address
4. Network connectivity issue

**Solutions:**
1. Wait 2-3 minutes after `terraform apply` for instance startup
2. Verify security group rule (should allow 22/TCP from 0.0.0.0/0)
3. Re-check IP: `terraform output -raw public_ip_address`
4. Test connectivity: `ping -c 1 <ip>` (ICMP may be blocked by security group)

**Verify Security Group:**
```bash
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?GroupName==`TestInstanceSG`].IpPermissions'
```

---

### Docker Container Won't Start

**Symptoms:**
- Container exits immediately after start
- `docker ps` shows no running container

**Check Logs:**
```bash
docker logs $(docker ps -aq) 2>&1 | tail -50
```

**Common Issues:**

1. **Missing TFE_LICENSE:**
   ```
   Error: TFE_LICENSE not provided
   ```
   Solution: Set `TFE_LICENSE` in docker-compose.yaml

2. **Missing Certificates:**
   ```
   Error: certificate file not found
   ```
   Solution: Ensure `certs/` directory has cert.pem, key.pem, bundle.pem

3. **Port Already in Use:**
   ```
   Error: bind: address already in use
   ```
   Solution: Stop other containers or change port mapping in docker-compose.yaml

---

### TFE Admin Token Retrieval Fails

**Error:**
```
docker: no matching container found
```

**Cause:** TFE container not running or container ID changed

**Solution:**
1. Check container is running: `docker ps`
2. If not running, check logs: `docker logs -f`
3. Once running, retry token retrieval:
   ```bash
   docker exec -it $(docker ps -aq) /bin/bash -c 'echo https://${TFE_HOSTNAME}/admin/account/new?token=$(tfectl admin token)'
   ```

---

### DNS Name Not Resolving

**Error:**
```
Failed to resolve docker.connor-fryar.sbx.hashidemos.io
```

**Causes:**
1. Route53 A record creation failed
2. DNS propagation delay
3. Local DNS cache

**Solutions:**
1. Verify record exists: `terraform output route53`
2. Query Route53: 
   ```bash
   aws route53 list-resource-record-sets \
     --hosted-zone-id Z0123456789ABCDEF | grep docker
   ```
3. Wait 5-10 minutes for DNS propagation
4. Clear local DNS cache: `sudo dscacheutil -flushcache` (macOS)

---

### Terraform State Corruption

**Error:**
```
json.UnmarshalTypeError: cannot unmarshal number into Go value
```

**Cause:** Corrupted `terraform.tfstate` or `.terraform.lock.hcl`

**Solution:**
1. Backup current state: `cp terraform.tfstate terraform.tfstate.backup`
2. Reset Terraform: `rm -rf .terraform .terraform.lock.hcl`
3. Re-initialize: `terraform init`
4. If state still corrupted, manually inspect `terraform.tfstate` (JSON format)

---

### Out of Memory on EC2

**Symptoms:**
- Container stops unexpectedly
- `docker logs` shows OOM errors
- EC2 becomes unresponsive

**Cause:** t3.medium (8 GB RAM) insufficient for TFE + Docker

**Solution:** Upgrade instance type
```bash
# Modify terraform.tfvars
InstanceType = "t3.large"  # 8 vCPU, 16 GB

# Recreate instance (requires downtime)
terraform destroy -auto-approve && terraform apply -auto-approve
```

---

### EC2 Instance Tags Not Updated

**Symptom:** Changing `InstanceName` variable doesn't update EC2 tags

**Reason:** `lifecycle { ignore_changes = all }` in ec2.tf prevents tag updates

**Workaround:** Manual tag update via AWS CLI
```bash
INSTANCE_ID=$(terraform output -json Instance_data | jq -r '.id')
aws ec2 create-tags --resources ${INSTANCE_ID} --tags Key=Name,Value=my-new-name
```

Or recreate instance:
```bash
terraform destroy && terraform apply
```

---

## State Management

### Local Backend Inspection

Current state stored in `terraform.tfstate` (JSON):

```bash
# View state summary
terraform show

# View specific resource
terraform state show aws_instance.TestInstanceInstance

# List all resources in state
terraform state list
```

### State Backup

Terraform automatically creates backups in `terraform.tfstate.backup`

To manually backup:
```bash
cp terraform.tfstate terraform.tfstate.$(date +%Y%m%d-%H%M%S).backup
```

### State Cleanup (After Destroy)

If infrastructure is destroyed but state file remains:

```bash
# Option 1: Destroy infrastructure
terraform destroy

# Option 2: If manually destroyed outside Terraform, refresh state
terraform refresh

# Option 3: Remove state file completely
rm terraform.tfstate terraform.tfstate.backup
```

---

## Maintenance Windows

### Routine Tasks

**Weekly:**
- Monitor EC2 CPU/memory usage in AWS console
- Check TFE application logs: `docker logs <container_id>`

**Monthly:**
- Review and rotate TFE encryption password
- Verify SSL certificate (Certbot auto-renews, verify renewal logs)
- Check AWS cost (Route53, EC2, EBS)

**Quarterly:**
- Test disaster recovery (destroy and redeploy)
- Review and update Terraform version if newer available
- Review this documentation for accuracy

### Backup Procedures

To backup TFE application data:

```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>

# Stop container (optional, for consistency)
docker-compose down

# Backup data directory
tar -czf tfe-data-backup-$(date +%Y%m%d).tar.gz data/ certs/

# Backup Terraform state (on local machine)
cd /path/to/terraform-enterprise-dev-env
tar -czf terraform-state-backup-$(date +%Y%m%d).tar.gz terraform.tfstate*
```

### Disaster Recovery

To restore from backup:

```bash
# On local machine, restore Terraform state
cd /path/to/terraform-enterprise-dev-env
tar -xzf terraform-state-backup-YYYYMMDD.tar.gz

# Verify state is valid
terraform plan

# If infrastructure was deleted externally:
terraform apply -auto-approve

# On EC2 instance, restore data
ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>
tar -xzf tfe-data-backup-YYYYMMDD.tar.gz
docker-compose up -d
```

---

## Related Documentation

- **Architecture Details:** See [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md)
- **Maintenance Guide:** See [`docs/MAINTENANCE.md`](../MAINTENANCE.md)
- **Quick Start:** See [`README.md`](../README.md)

---

**Last Updated:** Generated from operational analysis.
