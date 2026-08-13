# Architecture Documentation

This document provides a detailed breakdown of the Terraform Enterprise development environment architecture, resource relationships, and infrastructure topology.

## Architecture Layers

### 1. Networking Layer

The networking foundation consists of a custom VPC with public-only subnet design:

```
┌─────────────────────────────────────────┐
│  AWS Region: us-east-1                  │
│                                         │
│  aws_vpc "main"                         │
│  ├─ CIDR: 10.0.0.0/16                   │
│  ├─ DNS Support: enabled                │
│  ├─ DNS Hostnames: enabled              │
│  │                                      │
│  └─ aws_subnet "mainSubnet"             │
│     ├─ CIDR: 10.0.10.0/24              │
│     ├─ Availability Zone: us-east-1a   │
│     ├─ Auto-assign public IP: yes       │
│     │                                   │
│     └─ aws_internet_gateway "gw"        │
│        └─ Default route via IGW         │
│           (0.0.0.0/0 → IGW)             │
│                                         │
└─────────────────────────────────────────┘
         ↓ (public internet)
    External Internet
```

**Key Components:**

| Component | Type | CIDR/Details | Purpose |
|-----------|------|---------|---------|
| VPC | `aws_vpc` | 10.0.0.0/16 | Network isolation boundary |
| Subnet | `aws_subnet` | 10.0.10.0/24 | EC2 instance placement |
| IGW | `aws_internet_gateway` | Attached to VPC | Public internet routing |
| Route Table | `aws_route_table` | Routes 0.0.0.0/0 → IGW | Default route to internet |
| Route Assoc. | `aws_route_table_association` | Links subnet → route table | Applies routes to subnet |

**Design Notes:**
- Single public subnet only (no private subnets, no NAT)
- All instances automatically receive public IPs
- Direct internet access for all traffic
- Suitable for development/testing; not recommended for production

### 2. Security Layer

Network access control is managed via a single security group with explicit ingress rules and permissive egress:

```
aws_security_group "TestInstanceSG"
│
├─ Ingress Rules (5 individual rules)
│  ├─ Port 22 (SSH): 0.0.0.0/0 → TCP
│  ├─ Port 80 (HTTP): 0.0.0.0/0 → TCP
│  ├─ Port 443 (HTTPS): 0.0.0.0/0 → TCP
│  ├─ Port 8080 (App): 0.0.0.0/0 → TCP
│  ├─ Port 8443 (Admin): 0.0.0.0/0 → TCP
│  └─ Port 9091 (Metrics): 0.0.0.0/0 → TCP
│
└─ Egress Rule (1 rule)
   └─ All traffic (0.0.0.0/0, all protocols): Allow
```

**Security Group Ingress Rules:**

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | 0.0.0.0/0 | SSH administration |
| 80 | TCP | 0.0.0.0/0 | HTTP redirect to HTTPS |
| 443 | TCP | 0.0.0.0/0 | TFE web UI, HTTPS traffic |
| 8080 | TCP | 0.0.0.0/0 | Additional application port |
| 8443 | TCP | 0.0.0.0/0 | TFE admin console |
| 9091 | TCP | 0.0.0.0/0 | Metrics/monitoring endpoint |

**Implementation Details:**
- Each ingress rule is a separate `aws_vpc_security_group_ingress_rule` resource
- Egress allows all traffic (protocol `-1`, all IPs)
- Firewall is permissive (0.0.0.0/0); restrict sources for production use

### 3. Compute Layer

A single EC2 instance hosts the containerized Terraform Enterprise service:

```
aws_instance "TestInstanceInstance"
│
├─ AMI Lookup (via data source)
│  └─ aws_ami.Ubuntu["amd64"]
│     ├─ Owner: 888995627335 (HashiCorp)
│     ├─ Name pattern: hc-base-ubuntu-2404-amd64-*
│     ├─ State: available
│     └─ Filter: most recent
│
├─ Instance Configuration
│  ├─ Instance Type: t3.medium (default, configurable)
│  ├─ Subnet: aws_subnet.mainSubnet
│  ├─ Security Group: aws_security_group.TestInstanceSG
│  ├─ Public IP: Auto-assigned (via subnet setting)
│  ├─ Availability Zone: us-east-1a (hard-coded)
│  ├─ Key Pair: aws_key_pair.deployer
│  │
│  ├─ EBS Root Volume (via root_block_device)
│  │  ├─ Size: 50 GiB (default, configurable < 100 GiB)
│  │  └─ Type: gp3 (default, configurable)
│  │
│  ├─ User Data
│  │  └─ file("${path.module}/userdata.sh")
│  │     ├─ Install Docker
│  │     ├─ Install Certbot
│  │     ├─ Generate SSL certificates
│  │     └─ Prepare certificate directories
│  │
│  ├─ Tags
│  │  └─ Name: random_pet.pet.id (random name)
│  │
│  └─ Lifecycle Policy
│     └─ ignore_changes = all (post-creation changes not tracked)
│
└─ Key Pair (aws_key_pair "deployer")
   └─ Public key: ${var.public_key} (user-provided)
```

**EC2 Instance Specifications:**

| Attribute | Default | Configurable | Purpose |
|-----------|---------|--------------|---------|
| Instance Type | t3.medium | Yes (var.InstanceType) | 2 vCPU, 8 GiB RAM (dev/test suitable) |
| AMI | Ubuntu 24.04 amd64 | Limited (via owner/name filter) | HashiCorp-maintained Ubuntu base |
| Root Volume Size | 50 GiB | Yes (var.EBSSize, < 100) | Storage for Docker layers, TFE data |
| Root Volume Type | gp3 | Yes (var.EBSType) | Cost-optimized general-purpose storage |
| Availability Zone | us-east-1a | Yes (var.availability_zone) | Regional placement (hard-coded in instance) |
| Public IP | Auto-assigned | Managed by subnet | Internet-facing access |

**Key Design Points:**
- AMI lookup filters by HashiCorp account ID (888995627335) to ensure official Ubuntu images
- Architecture supports both amd64 and arm64 (ami data source uses `for_each`), but instance uses amd64 explicitly
- `lifecycle { ignore_changes = all }` means post-creation changes won't trigger Terraform updates (manual management required)
- User data script runs at first boot to prepare Docker and SSL certificates

### 4. DNS Layer

Route53 is used for public DNS routing:

```
data "aws_route53_zone" "hashidemos"
└─ Lookup by domain: connor-fryar.sbx.hashidemos.io
   ├─ Private zone: false (public)
   └─ Used by downstream A record

aws_route53_record "ARecordTestInstance"
├─ Zone ID: from data.aws_route53_zone
├─ Record name: ${local.domain_name}
│  └─ Constructed as: ${var.subdomain}.${var.yourname}.${var.domain}
│     └─ Example: docker.connor-fryar.sbx.hashidemos.io
├─ Type: A (IPv4 address)
├─ TTL: 300 seconds (5 minutes)
├─ Value: aws_instance.public_ip
└─ Dependency: depends_on = [aws_instance] (explicit)
```

**Domain Construction:**

```
Local Value: local.domain_name
= "${var.subdomain}.${var.yourname}.${var.domain}"
= "docker.connor-fryar.sbx.hashidemos.io"

Example configuration:
  subdomain  = "docker"         (required)
  yourname   = "connor-fryar"  (default)
  domain     = "sbx.hashidemos.io" (default)
```

**Important Notes:**
- Route53 zone must pre-exist (data source looks it up, doesn't create it)
- A record TTL is 5 minutes (relatively short for DNS caching)
- Record points to instance public IP (which is assigned by AWS at launch)
- `depends_on` explicit dependency ensures instance exists before DNS creation

### 5. Supporting Services

#### Random Name Generation

```
resource "random_pet" "pet"
└─ Generates: random two-word combination
   └─ Used as: EC2 instance Name tag
   └─ Example: "hopeful-giraffe", "sunny-badger"
```

Purpose: Provides unique, readable instance identifiers without collisions.

#### SSH Key Management

```
aws_key_pair "deployer"
├─ Key Name: "deployer-key" (static)
└─ Public Key: ${var.public_key}
   └─ User provides via terraform.tfvars or -var

Flow:
1. User generates local SSH key (ssh-keygen)
2. Provides public key to Terraform
3. Terraform creates key pair in AWS
4. AWS associates with EC2 instance
5. User SSH via local private key
```

#### Docker and Container Orchestration

```
Host: EC2 Instance (ubuntu)
│
├─ Docker Engine (installed via userdata.sh)
│  │
│  ├─ Docker Compose (configured via docker-compose.yaml)
│  │  │
│  │  ├─ Service: tfe
│  │  │  ├─ Image: hashicorp/terraform-enterprise:#.#.#
│  │  │  ├─ Environment Variables:
│  │  │  │  ├─ TFE_LICENSE (must be provided by user)
│  │  │  │  ├─ TFE_HOSTNAME (must be provided by user)
│  │  │  │  ├─ TFE_ENCRYPTION_PASSWORD (must be provided by user)
│  │  │  │  ├─ TFE_OPERATIONAL_MODE: "disk"
│  │  │  │  ├─ TFE_TLS_CERT_FILE (from Certbot)
│  │  │  │  ├─ TFE_TLS_KEY_FILE (from Certbot)
│  │  │  │  ├─ TFE_METRICS_ENABLE: true
│  │  │  │  └─ (other settings in docker-compose.yaml)
│  │  │  │
│  │  │  ├─ Volumes (bind/named)
│  │  │  │  ├─ /run/docker.sock (Docker socket for nested Docker)
│  │  │  │  ├─ ./certs (SSL certificates from Certbot)
│  │  │  │  ├─ ./data (TFE application data)
│  │  │  │  └─ terraform-enterprise-cache (named volume for TFE cache)
│  │  │  │
│  │  │  └─ Ports (published)
│  │  │     ├─ 80:80 (HTTP)
│  │  │     ├─ 443:443 (HTTPS)
│  │  │     ├─ 9090:9090 (Prometheus)
│  │  │     ├─ 9091:9091 (Pushgateway)
│  │  │     └─ 8443:8443 (Admin console)
│  │  │
│  │  └─ Security
│  │     ├─ Capabilities: IPC_LOCK (for mlock support)
│  │     ├─ read_only: true (filesystem read-only except tmpfs)
│  │     └─ tmpfs mounts (for writable transient storage)
│  │
│  └─ SSL Certificate Management (Certbot)
│     ├─ Installed via userdata.sh during EC2 bootstrap
│     ├─ Provider: Let's Encrypt (free, automated)
│     ├─ Domain: docker.connor-fryar.sbx.hashidemos.io (hard-coded in userdata.sh)
│     ├─ Certificate Path: /etc/letsencrypt/live/{domain}/
│     └─ Mounted into TFE container at /etc/ssl/private/terraform-enterprise/
│
└─ Data Directories
   ├─ /opt/{date}/certs/ (where Certbot copies certificates)
   ├─ /opt/{date}/data/ (TFE application data, if used)
   └─ (managed by EC2 bootstrap script)
```

**Docker Compose Configuration Details:**

- **Image:** `images.releases.hashicorp.com/hashicorp/terraform-enterprise:#.#.#`
  - Version placeholder (#.#.#) must be specified by user
  - Requires Docker Hub authentication (`docker login`)

- **Operational Mode:** `disk` (no external PostgreSQL or object storage)
  - Suitable for development/testing
  - All data stored locally on EC2 instance

- **TLS:** Configured via Certbot certificates
  - Must be mounted into container at `/etc/ssl/private/terraform-enterprise/`

- **Volumes:**
  - `/run/docker.sock` enables Docker-in-Docker functionality (TFE can spawn containers)
  - `./certs` must contain certificate files before container starts
  - `./data` provides persistent storage for TFE application state

## Dependency Graph

### Explicit Dependencies

```
aws_vpc
├─ aws_subnet (vpc_id)
├─ aws_internet_gateway (vpc_id)
└─ aws_security_group (vpc_id)

aws_internet_gateway
└─ aws_route_table (gateway_id)

aws_route_table
└─ aws_route_table_association (route_table_id)

aws_route_table_association
└─ aws_subnet (subnet_id)

aws_security_group
├─ aws_vpc_security_group_ingress_rule (security_group_id) ✕ 6 rules
└─ aws_vpc_security_group_egress_rule (security_group_id) ✕ 1 rule

aws_instance
├─ aws_subnet (subnet_id)
├─ aws_security_group (security_groups)
├─ aws_key_pair (key_name)
├─ random_pet (used in tags)
└─ userdata.sh (file dependency)

aws_route53_record
├─ aws_route53_zone (zone_id) [data source]
├─ aws_instance (public_ip via local.domain_name)
└─ depends_on = [aws_instance] [explicit]

random_pet
└─ (no dependencies)

aws_key_pair
└─ (no dependencies)
```

### Implicit (Terraform-inferred) Dependencies

Terraform automatically resolves resource references:

```
aws_instance.TestInstanceInstance
├─ references aws_security_group.TestInstanceSG.id
├─ references aws_subnet.mainSubnet.id
├─ references aws_key_pair.deployer.key_name
└─ references random_pet.pet.id (in tags)

aws_route53_record.ARecordTestInstance
└─ references aws_instance.TestInstanceInstance.public_ip
```

**Impact:** Changing any upstream resource triggers cascading updates downstream.

## Data Sources

### AMI Lookup

```
data "aws_ami" "Ubuntu"
├─ for_each: ["amd64", "arm64"]
├─ Owner: 888995627335 (HashiCorp)
├─ Filter Name: hc-base-ubuntu-2404-{amd64|arm64}-*
├─ Filter State: available
└─ Most Recent: true
   └─ Returns: Most recent matching AMI

Used By:
└─ aws_instance references Ubuntu["amd64"].id
```

**Behavior:**
- Creates two data source instances: `Ubuntu["amd64"]` and `Ubuntu["arm64"]`
- Instance uses amd64 explicitly, but arm64 data is also fetched and available in outputs
- Requires internet access to query AWS AMI catalog

### Instance Metadata

```
data "aws_instance" "TestInstanceInstanceData"
└─ Filters by instance_id
   └─ instance_id = aws_instance.TestInstanceInstance.id
   └─ Creates data dependency on EC2 instance creation

Used By:
└─ Output "Instance_data" exposes all instance metadata
```

**Behavior:**
- Queries AWS for current instance state after creation
- Provides data such as private IP, security group IDs, VPC info, etc.
- Useful for debugging and cross-stack data lookup

### Route53 Zone Lookup

```
data "aws_route53_zone" "hashidemos"
├─ Domain Name: connor-fryar.sbx.hashidemos.io
├─ Private Zone: false
└─ Returns: Zone ID for data.aws_route53_zone.zone_id

Used By:
└─ aws_route53_record (zone_id)
```

**Behavior:**
- Assumes Route53 zone already exists in AWS account
- Data source fails if zone doesn't exist (plan/apply fails)
- Zone is looked up by exact name match

**Important:** The zone must be created outside Terraform before applying this configuration.

## State and Resource Lifecycle

### Resource Creation Flow

```
1. terraform init
   └─ Download provider plugins (AWS v6.27.0, Random v3.7.2)

2. terraform plan
   └─ Query AWS API for current state
   └─ Compare to .tf configuration
   └─ Output execution plan

3. terraform apply
   ├─ Resolve data sources (AMI lookup, Route53 zone)
   ├─ Create VPC → Subnet → IGW → Route Table
   ├─ Create Security Group + 6 ingress rules + 1 egress rule
   ├─ Create Key Pair (AWS)
   ├─ Create random_pet (local)
   ├─ Create EC2 instance (with user_data script)
   │  └─ Run userdata.sh on first boot (Docker + Certbot setup)
   ├─ Query instance metadata (data source)
   ├─ Create Route53 A record
   └─ Write terraform.tfstate file

4. Post-apply
   └─ User manually configures docker-compose.yaml
   └─ User starts Docker containers
   └─ TFE service online
```

### Post-Creation Lifecycle

```
EC2 Instance Lifecycle: ignore_changes = all

Impact:
├─ Terraform doesn't detect manual changes to instance
├─ EBS volume modifications not tracked
├─ User data re-execution: depends on EC2 RebootInstanceWithAssociatedInstances
├─ To change instance type or other properties:
│  └─ terraform destroy && terraform apply
│  └─ Results in service downtime
└─ Manual management required for:
    ├─ Docker updates
    ├─ TFE version upgrades
    ├─ Certificate renewals
    └─ Application configuration changes
```

## Scaling and Multi-Environment Considerations

### Current Limitations

1. **Single Instance:** No redundancy, no load balancing
2. **Single AZ:** us-east-1a hard-coded (no multi-AZ support)
3. **Single Environment:** All resources in root module
4. **Monolithic:** No separation of concerns via modules
5. **Manual Scaling:** Requires manual resource recreation (due to lifecycle rules)

### Theoretical Expansion Points

To support multiple environments or scaling:

```
Future Architecture (proposed, not implemented):
├─ modules/vpc/                    (reusable VPC module)
├─ modules/ec2/                    (reusable EC2 module)
├─ modules/security/               (reusable security group)
├─ environments/dev/               (dev environment root)
│  ├─ main.tf
│  ├─ terraform.tfvars
│  └─ outputs.tf
├─ environments/staging/           (staging environment root)
│  ├─ main.tf
│  ├─ terraform.tfvars
│  └─ outputs.tf
└─ environments/prod/              (production environment root)
   ├─ main.tf
   ├─ terraform.tfvars
   └─ outputs.tf
```

This is not currently implemented; documented for reference only.

## Network Flow Examples

### Incoming HTTP/HTTPS Request

```
1. Client sends request to docker.connor-fryar.sbx.hashidemos.io
2. DNS resolves to EC2 instance public IP (via Route53 A record)
3. Request reaches AWS ELB/NAT → EC2 instance public IP
4. Security Group evaluates ingress rule (port 443 allowed from 0.0.0.0/0)
5. Request routed to EC2 instance kernel → Docker container (TFE)
6. TFE service responds (via port 443 mapping in docker-compose.yaml)
```

### Outbound Internet Access

```
1. EC2 instance needs external resource (e.g., download Docker image)
2. Security Group evaluates egress rule (allow all, protocol -1)
3. Packet routed to IGW
4. AWS translates private IP → public IP (elastic IP or instance public IP)
5. Request exits to internet
6. Response returns to EC2 instance public IP
7. IGW routes back to instance
```

### EC2 Instance to AWS API Access

```
1. Userdata script calls AWS CLI (e.g., to tag instance)
2. AWS credentials from environment (EC2 IAM role or env vars)
3. Request routed via VPC + IGW to AWS API endpoint
4. AWS API validates credentials and performs operation
5. Response returns to instance
```

## Cost Considerations

### Primary Cost Drivers

| Component | Typical Cost | Notes |
|-----------|--------------|-------|
| **EC2 t3.medium** | $0.04/hour (on-demand) | Runs 24/7 in dev environment |
| **EBS gp3 50GB** | $1-2/month | Elastic Block Store storage |
| **Data transfer** | $0.02/GB out | Outbound data to internet |
| **Route53 zone** | $0.50/month | Hosted zone management (existing) |
| **Route53 A record** | $0.40/month | Per record query charges minimal |

### Cost Optimization Suggestions

- Use **spot instances** (if interruption tolerance) → 70% savings
- **Stop instance** when not in use → pause EC2 charges
- Monitor data transfer for unexpected egress charges
- Set lifecycle rules to auto-destroy unused resources (requires code change)

---

**Last Updated:** Derived from Terraform configuration analysis.
