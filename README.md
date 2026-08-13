# Terraform Enterprise Development Environment

This Terraform configuration provisions a complete development and testing environment for **Terraform Enterprise (TFE)** on AWS, containerized with Docker.

## Project Overview

This repository manages the AWS infrastructure required to run Terraform Enterprise v#.#.# in a development/test setup. The configuration creates a single EC2 instance in a public subnet, with DNS routing via Route53, automatic SSL certificate provisioning, and Docker orchestration.

**Infrastructure Components:**
- **Compute:** EC2 instance (default: t3.medium, Ubuntu 24.04 LTS)
- **Networking:** VPC with public subnet, internet gateway, and security group
- **DNS:** Route53 A record pointing to the instance public IP
- **Storage:** Configurable EBS volume (default: 50 GiB gp3)
- **Security:** SSL/TLS certificates via Let's Encrypt (Certbot)
- **Container Orchestration:** Docker with docker-compose for TFE service

**Typical Use Cases:**
- Development and testing of Terraform Enterprise features
- Internal testing environments for teams evaluating TFE
- Learning and experimentation with TFE configuration and deployment

## Repository Structure

```
.
├── README.md                    # This file
├── docs/                        # Detailed documentation
│   ├── ARCHITECTURE.md         # Architecture, resources, and relationships
│   ├── OPERATIONS.md           # Deployment, variables, and troubleshooting
│   └── MAINTENANCE.md          # Guidelines for repository maintainers
│
├── Terraform Configuration
│   ├── providers.tf            # Provider configuration (AWS, Random)
│   ├── var.tf                  # Input variables
│   ├── outputs.tf              # Primary outputs
│   ├── ec2outputs.tf           # EC2 and AMI data outputs
│   ├── route53outputs.tf       # Route53 zone data outputs
│   ├── vpc.tf                  # VPC, subnet, IGW, and routing
│   ├── ec2.tf                  # EC2 instance, AMI lookup, key pair
│   ├── securitygroup.tf        # Security group and ingress/egress rules
│   ├── route53.tf              # Route53 zone lookup and A record
│   ├── random-pet.tf           # Random resource for instance naming
│   └── compute.tf              # Commented TFE configuration template
│
├── Supporting Files
│   ├── docker-compose.yaml     # TFE container configuration
│   ├── userdata.sh             # EC2 bootstrap script (Docker, Certbot setup)
│   ├── manual commands.txt     # Ad-hoc Docker and admin setup commands
│   └── Resource notes/         # AWS resource reference examples
│
├── State Management
│   ├── terraform.tfstate       # Local Terraform state (current)
│   ├── terraform.tfstate.backup # State backup
│   └── .terraform.lock.hcl     # Provider lock file
│
└── Configuration
    ├── .gitignore              # Git exclusion patterns
    └── .git/                   # Git repository metadata
```

## Quick Start

### Prerequisites

- **Terraform:** Any version ≥ 0.12 (no explicit version constraint defined)
- **AWS Account:** With appropriate IAM permissions
- **AWS Credentials:** Configured via environment variables or AWS credentials file
- **Public SSH Key:** For EC2 key pair injection
- **Route53 Zone:** Pre-existing domain `*.sbx.hashidemos.io` (by default)

### Basic Deployment

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Create a `terraform.tfvars` file** with required variables:
   ```hcl
   subdomain      = "docker"
   public_key     = file("~/.ssh/id_rsa.pub")
   ```

3. **Validate the configuration:**
   ```bash
   terraform validate
   terraform fmt -check
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Access the deployed infrastructure:**
   - Retrieve outputs:
     ```bash
     terraform output
     ```
   - Connect via SSH:
     ```bash
     ssh -i ~/.ssh/id_rsa ubuntu@<public_ip_address>
     ```

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────┐
│  AWS VPC (10.0.0.0/16)                              │
│  ┌───────────────────────────────────────────────┐  │
│  │  Public Subnet (10.0.10.0/24)                 │  │
│  │  ┌─────────────────────────────────────────┐  │  │
│  │  │  EC2 Instance (Ubuntu 24.04 LTS)        │  │  │
│  │  │  ├─ Docker Engine                       │  │  │
│  │  │  ├─ Terraform Enterprise (#.#.#)        │  │  │
│  │  │  ├─ Let's Encrypt SSL Certificate       │  │  │
│  │  │  └─ EBS Volume (gp3)                    │  │  │
│  │  └─────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────┘  │
│         ↓ (Internet Gateway)                        │
│  Public IP / DNS A Record                          │
└─────────────────────────────────────────────────────┘
         ↓
   Route53 (connor-fryar.sbx.hashidemos.io)
         ↓
   External Clients
```

### Resource Composition

| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| **aws_vpc** | Main VPC | CIDR: 10.0.0.0/16 |
| **aws_subnet** | Public subnet | CIDR: 10.0.10.0/24, Auto-assign public IP |
| **aws_internet_gateway** | Internet access | Attached to VPC |
| **aws_route_table** | Routing rules | Route 0.0.0.0/0 to IGW |
| **aws_security_group** | Network ACLs | Inbound: 22, 80, 443, 8080, 8443, 9091 |
| **aws_instance** | Compute | Ubuntu 24.04 amd64, SSH key pair, EBS config |
| **aws_key_pair** | SSH access | Public key injected at launch |
| **aws_route53_record** | DNS A record | Points to instance public IP |
| **random_pet** | Instance naming | Generates unique random name tag |

### Data Sources

- **aws_ami (Ubuntu):** Looks up latest HashiCorp-maintained Ubuntu 24.04 AMI
- **aws_instance:** Queries instance metadata after creation
- **aws_route53_zone:** Looks up pre-existing Route53 zone by domain name

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for detailed resource dependencies and relationships.

## Terraform and Provider Requirements

| Requirement | Constraint | Current Version |
|-------------|-----------|-----------------|
| Terraform | None specified (≥ 0.12 compatible) | Any |
| AWS Provider | ~> 6.0 | 6.27.0 |
| Random Provider | 3.7.2 | 3.7.2 |

**Note:** No explicit `required_version` block exists. To pin Terraform versions, add a `versions.tf` file or require_version block in `providers.tf`.

## State and Backend

**Current Configuration:** Local backend (default)

- **State files:** `terraform.tfstate` and `terraform.tfstate.backup`
- **Organization:** Single root module, no workspaces
- **Persistence:** State is tracked in version control (⚠️ see Observations)

**Important Notes:**
- State files contain sensitive data (keys, IPs, secrets)
- No remote backend configured (all state local to machine)
- No environment separation; all resources share a single state file
- No state locking mechanism

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for recommendations on state management.

## Variables

### Input Variables

| Variable | Type | Default | Required | Purpose |
|----------|------|---------|----------|---------|
| **InstanceName** | string | "deprecated" | No | EC2 instance name tag |
| **InstanceType** | string | "t3.medium" | No | EC2 instance type (2 vCPU, 8 GiB RAM recommended) |
| **EBSSize** | number | 50 | No | EBS volume size in GiB (must be < 100) |
| **EBSType** | string | "gp3" | No | EBS volume type (gp2, gp3, io1, io2) |
| **subdomain** | string | — | **Yes** | Subdomain portion of Route53 domain |
| **yourname** | string | "connor-fryar" | No | Name/identity portion of domain |
| **domain** | string | "sbx.hashidemos.io" | No | Base Route53 zone domain |
| **availability_zone** | string | "us-east-1a" | No | AWS availability zone |
| **public_key** | string | — | **Yes** | SSH public key for EC2 key pair |

### Variable Notes

- **subdomain** and **public_key** are required (no default values)
- **EBSSize** has validation: must be < 100 GiB
- Domain components are combined via local value: `${subdomain}.${yourname}.${domain}`
- Variables are typically supplied via `terraform.tfvars` or `-var` flags

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for examples and detailed variable descriptions.

## Outputs

| Output | Source | Purpose |
|--------|--------|---------|
| **domain_name** | `var.InstanceName` | Instance name for identification |
| **public_ip_address** | `aws_instance.TestInstanceInstance.public_ip` | Public IP for SSH and web access |
| **AMI_Data** | `data.aws_ami.Ubuntu["amd64"]` | AMI metadata (ID, architecture, etc.) |
| **Instance_data** | `data.aws_instance.TestInstanceInstanceData` | Instance metadata after creation |
| **route53** | `data.aws_route53_zone.hashidemos` | Route53 zone information |

## Execution Workflow

### Standard Terraform Commands

All commands assume the current working directory is the repository root.

```bash
# Initialize Terraform (download providers, create .terraform/)
terraform init

# Validate configuration syntax and logic
terraform validate

# Format check (ensure code follows Terraform style guide)
terraform fmt -check

# Generate execution plan (review before apply)
terraform plan

# Apply configuration (provision infrastructure)
terraform apply

# Show current state
terraform show

# Output current outputs
terraform output
```

### No CI/CD Pipeline

**Finding:** No automated deployment pipeline is configured in this repository.

- No GitHub Actions workflows (`.github/workflows/`)
- No GitLab CI pipeline (`.gitlab-ci.yml`)
- No Jenkins pipeline
- No cloud-native CI/CD integration

All Terraform execution is **manual** and local to the engineer's machine.

### Post-Deployment Steps

After `terraform apply` completes:

1. **SSH into instance:**
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@<public_ip_output>
   ```

2. **Monitor Docker container startup:**
   ```bash
   docker ps                    # Check if TFE container is running
   docker logs -f $(docker ps -q)  # Stream TFE logs
   ```

3. **Access TFE:**
   - Web UI: `https://<domain_name>/` (configured domain)
   - Admin console: `https://<domain_name>:8443/` (port 8443)

4. **Retrieve admin token** (see [`manual commands.txt`](manual commands.txt)):
   ```bash
   docker exec -it $(docker ps -aq) /bin/bash -c 'echo https://${TFE_HOSTNAME}/admin/account/new?token=$(tfectl admin token)'
   ```

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for detailed deployment procedures and troubleshooting.

## Environment Management

**Single Environment:** This configuration represents a single development/test environment.

- No environment separation (dev, staging, prod)
- All resources in root module
- Hard-coded values: AWS region (us-east-1), domain base
- All configuration in `var.tf`; no separate tfvars files per environment
- `.gitignore` excludes `*.tfvars`, though none currently exist in repo

To add environment separation in the future, consider:
- Creating `environments/` subdirectory with environment-specific `tfvars` files
- Using Terraform workspaces for state isolation
- Implementing module-based architecture

## Authentication and Credentials

### AWS Authentication

**Method:** Environment variables or AWS credentials file (standard Terraform AWS provider behavior)

**Required Setup:**
```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 2: AWS credentials file (~/.aws/credentials)
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key

# Option 3: IAM role (if running on EC2)
# Automatically detected by AWS provider
```

**Required IAM Permissions:**
- EC2: `CreateInstances`, `DescribeInstances`, `CreateKeyPair`, `AssociateAddress`
- VPC: `CreateVpc`, `CreateSubnet`, `CreateInternetGateway`, `CreateSecurityGroup`
- Route53: `ChangeResourceRecordSets`, `ListHostedZonesByName`
- Security Groups: `AuthorizeSecurityGroupIngress`, `AuthorizeSecurityGroupEgress`

### SSH Authentication

**Method:** Public/private key pair

**Setup:**
1. Generate local SSH key (if not present):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```

2. Provide public key to Terraform:
   ```hcl
   public_key = file("~/.ssh/id_rsa.pub")
   ```

3. Connect to instance:
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>
   ```

### TFE License and Configuration

**Not handled by Terraform:**
- TFE license must be provided separately (set `TFE_LICENSE` in docker-compose.yaml before container startup)
- Hostname, encryption password, and other TFE settings are configured in `docker-compose.yaml`

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for TFE-specific configuration details.

## Dependencies and External Systems

### AWS Services

- **EC2:** Instance provisioning, key pair management, AMI lookup
- **VPC:** Networking infrastructure (VPC, subnet, security groups, routing)
- **Route53:** DNS zone lookup and A record management
- **IAM:** Authentication and authorization (implicit)

### External Resources

- **Route53 Zone:** Pre-existing hosted zone `*.sbx.hashidemos.io` must exist in the AWS account
- **HashiCorp AMI Account:** Ubuntu AMI lookup depends on HashiCorp-maintained images (account ID: 888995627335)

### Local Dependencies

- **Docker:** Required on EC2 for TFE container runtime
- **Docker Compose:** Used for TFE service orchestration
- **Let's Encrypt:** Certbot fetches certificates during EC2 bootstrap
- **SSH:** Required for post-deployment access and management

## Operational Considerations

### Resource Lifecycle

**EC2 Instance Lifecycle Rule:**
```hcl
lifecycle {
  ignore_changes = all
}
```

**Impact:** The EC2 instance is created initially by Terraform, but subsequent changes to the instance (manual updates, Docker container modifications, certificate renewals, etc.) are **not tracked or managed** by Terraform.

**Implication:** Once created, the instance drifts from Terraform management. To apply new configurations, the instance must be destroyed and recreated.

### Explicit Dependencies

**Route53 A Record:**
```hcl
depends_on = [aws_instance.TestInstanceInstance]
```

Ensures the instance exists and has a public IP before DNS record creation.

### Port Allocations

Security group allows inbound traffic on these ports:
- **22:** SSH (administration)
- **80:** HTTP (web traffic)
- **443:** HTTPS (web traffic, TFE UI)
- **8080:** Additional application port
- **8443:** TFE admin console port
- **9091:** Metrics/monitoring port

All outbound traffic is allowed (egress policy: allow all).

### Data Source Dependencies

- **AMI Lookup:** Depends on HashiCorp-maintained Ubuntu 24.04 AMI availability
- **Route53 Zone:** Depends on pre-existing hosted zone in Route53

### Cross-Resource Dependencies

```
aws_security_group
  ├─ → aws_vpc (vpc_id)
  └─ → (security group ingress/egress rules)

aws_instance
  ├─ → aws_subnet (subnet_id)
  ├─ → aws_security_group (security_groups)
  ├─ → aws_key_pair (key_name)
  └─ → userdata.sh (local file)

aws_route53_record
  ├─ → aws_route53_zone (zone_id)
  ├─ → aws_instance (public_ip via local.domain_name)
  └─ → depends_on: aws_instance (explicit)
```

## Observations / Potential Follow-Up

### ⚠️ State Files Tracked in Version Control

**Location:** `terraform.tfstate`, `terraform.tfstate.backup`

**Issue:** State files are committed to the Git repository. This is a security risk because:
- State files contain sensitive data (encryption keys, tokens, passwords)
- Any person with repository access can view infrastructure details
- Rotated credentials remain visible in Git history

**Recommendation:** Move to remote backend (Terraform Cloud, Terraform Enterprise, S3 with DynamoDB locking, or another state backend) and exclude `*.tfstate*` from version control.

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

### 🔍 Hard-Coded Domain Name

**Locations:**
- `userdata.sh` line 15: `DOMAIN="docker.connor-fryar.sbx.hashidemos.io"`
- `route53.tf` line 5: `name = "connor-fryar.sbx.hashidemos.io"` (in data source filter)

**Issue:** Domain is hard-coded, limiting flexibility. Currently relies on `var.subdomain` + `var.yourname` + `var.domain` locals in some places, but bootstrap script uses a literal value.

**Recommendation:** Parameterize `userdata.sh` via template variables or Terraform template function to use `local.domain_name` instead of hard-coded value.

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

### 📝 Incomplete TFE Configuration Template

**Location:** `compute.tf` (entirely commented out)

**Content:** Extensive commented-out configuration for Terraform Enterprise, including:
- Database connection settings
- S3 object storage
- Redis caching (for active-active mode)
- TLS certificate configuration
- Observability and metrics
- Docker driver settings
- IACT (Initial Admin Creation Token) configuration

**Context:** These settings appear to be a template for more advanced TFE deployments but are currently unused.

**Recommendation:** Clarify whether this is:
1. A template for future expansion (consider moving to separate file with clear intent)
2. Deprecated code (consider removing if no longer needed)
3. Reference documentation (consider moving to `docs/`)

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

### 🔄 Instance Lifecycle Isolation

**Location:** `ec2.tf`, lines 43-45

**Configuration:**
```hcl
lifecycle {
  ignore_changes = all
}
```

**Behavior:** After creation, the EC2 instance is not updated by Terraform. Manual changes, Docker updates, certificate renewals, and other modifications are not detected or managed by Terraform.

**Implication:** To apply configuration changes, the instance must be destroyed and recreated (`terraform destroy && terraform apply`), which interrupts service.

**Recommendation:** Consider whether this lifecycle policy is intentional or accidental. If intentional, document why. If unintentional, remove to enable Terraform drift detection.

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

### ❌ No Terraform Version Pinning

**Location:** No `required_version` block in any `.tf` file

**Current State:** Configuration works with any Terraform version ≥ 0.12

**Risk:** Version-specific behavior differences could cause unexpected plan/apply results across team members or CI/CD systems using different Terraform versions.

**Recommendation:** Add `required_version = ">= 1.0"` or similar constraint to `providers.tf` or new `versions.tf` file based on minimum version tested with this configuration.

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

### 📦 No Module Architecture

**Current State:** All resources defined inline in root module. No `modules/` directory.

**Observation:** Configuration is monolithic and single-purpose, which is appropriate for a simple dev environment. However, if this grows to support multiple environments or configurations, consider:
- Extracting VPC as a module
- Extracting EC2 instance + security group as a module
- Creating environment-specific root modules

**Status:** Appropriate for current scope; noted for future reference.

---

### 🎯 Variables Without `.tfvars` Examples

**Current State:** No `.tfvars` example or template file in repository.

**Recommendation:** Create `terraform.tfvars.example` showing required and optional variables:
```hcl
subdomain  = "docker"
public_key = file("~/.ssh/id_rsa.pub")
# Optional:
# InstanceType = "t3.large"
# EBSSize      = 100
```

**Status:** Documented for maintainer awareness; no code changes made per task constraints.

---

## Maintenance Guide

See [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md) for guidelines on maintaining this repository as it evolves.

---

## Support and Troubleshooting

See [`docs/OPERATIONS.md`](docs/OPERATIONS.md) for detailed troubleshooting, common issues, and operational procedures.

---

**Last Updated:** Generated from Terraform configuration analysis.
