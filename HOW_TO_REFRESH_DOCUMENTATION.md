# How to Use the Documentation Refresh Prompt

This guide explains how to use `DOCUMENTATION_REFRESH_PROMPT.md` to keep the repository documentation current.

## Quick Start

### When to Refresh Documentation

Refresh documentation when:

✏️ **Code Changes**
- Provider versions are updated (check `.terraform.lock.hcl`)
- New variables are added to `var.tf`
- Variables are removed or modified
- New outputs are added
- Outputs are removed or modified
- New `.tf` files are created
- Resources are added, removed, or significantly changed

🔧 **Configuration Changes**
- `docker-compose.yaml` is updated
- `userdata.sh` bootstrap script changes
- Deployment procedures change
- `providers.tf` is modified
- Terraform version constraints change

📋 **Maintenance**
- Quarterly documentation review
- After discovering documentation inconsistencies
- When new deployment issues are discovered
- When team feedback indicates documentation gaps

### How to Request a Documentation Refresh

**Copy and paste this message to Bob:**

```
Please refresh the repository documentation using the procedure in DOCUMENTATION_REFRESH_PROMPT.md.

Review the current Terraform configuration and update README.md and docs/*.md files to reflect the current state.

Key areas to focus on:
- [SPECIFY WHAT CHANGED, e.g., "Provider version updated to 6.28.0"]
- [SPECIFY ANOTHER CHANGE if relevant]

Make no changes to Terraform code or configuration—only update documentation.
```

### Example Refresh Requests

**After updating provider version:**
```
Please refresh the repository documentation using DOCUMENTATION_REFRESH_PROMPT.md.

The AWS provider was updated to version 6.28.0. Update the provider requirements 
table in README.md and verify all documentation reflects the current provider 
versions in .terraform.lock.hcl.
```

**After adding a new variable:**
```
Please refresh the repository documentation using DOCUMENTATION_REFRESH_PROMPT.md.

A new variable "CertbotEmail" was added to var.tf. Add it to the Variables 
Reference section in docs/OPERATIONS.md and update README.md if needed.
```

**After quarterly review:**
```
Please perform a quarterly documentation refresh using DOCUMENTATION_REFRESH_PROMPT.md.

Verify all documentation is current with the repository as it exists today. 
Check version numbers, resource names, deployment procedures, and troubleshooting 
sections for accuracy.
```

## What the Refresh Process Covers

The prompt guides Bob through checking:

1. **Repository Structure** — Verifies all files are in expected locations
2. **Terraform Config** — Checks provider versions, variables, outputs
3. **Resources** — Verifies resource names, types, relationships
4. **Docker/TFE** — Checks container configuration and version
5. **Deployment** — Verifies procedures match current setup
6. **Architecture** — Checks resource relationships and dependencies
7. **Variables** — Verifies all variables are documented
8. **Outputs** — Verifies all outputs are documented
9. **Observations** — Updates notes about issues or improvements
10. **Documentation Standards** — Maintains consistency and quality

## Expected Output

After a documentation refresh, Bob will provide:

- **Files Updated** — Which documentation files were modified
- **Files Created** — Any new documentation files
- **Major Changes** — Summary of significant updates
- **New Observations** — Issues or improvement opportunities discovered
- **Items Resolved** — Previous observations that are now addressed
- **Verification** — Confirmation that no Terraform code was changed

## Documentation Files Structure

The refresh process maintains these documentation files:

```
README.md                           (main entry point)
├─ Project Overview
├─ Repository Structure
├─ Quick Start
├─ Architecture Overview
├─ Provider Requirements
├─ State & Backend
├─ Variables
├─ Outputs
├─ Execution Workflow
├─ Environment Management
├─ Authentication
├─ Dependencies
├─ Operational Considerations
└─ Observations / Potential Follow-Up

docs/ARCHITECTURE.md               (detailed design)
├─ Architecture Layers
│  ├─ Networking Layer
│  ├─ Security Layer
│  ├─ Compute Layer
│  ├─ DNS Layer
│  └─ Supporting Services
├─ Dependency Graph
├─ Data Sources
├─ State and Resource Lifecycle
├─ Scaling Considerations
└─ Network Flow Examples

docs/OPERATIONS.md                 (procedures & reference)
├─ Pre-Deployment Checklist
├─ Deployment Walkthrough (14 steps)
├─ Variable Configuration
├─ Input Variables Reference
├─ Outputs Reference
├─ Troubleshooting
├─ State Management
├─ Maintenance Windows
└─ Backup & Disaster Recovery

docs/MAINTENANCE.md                (contributor guidelines)
├─ Change Procedures
├─ Documentation Maintenance Checklist
├─ Common Maintenance Tasks
├─ Documentation Standards
├─ Deprecation Procedures
└─ Troubleshooting Documentation Debt

DOCUMENTATION_REFRESH_PROMPT.md    (this process)
└─ Instructions for refreshing docs
```

## Common Refresh Scenarios

### Scenario 1: Provider Version Updated

**What changed:**
- `.terraform.lock.hcl` shows AWS provider 6.28.0 (previously 6.27.0)

**Request to Bob:**
```
Please refresh the repository documentation using DOCUMENTATION_REFRESH_PROMPT.md.

The AWS provider has been updated to version 6.28.0. Update the provider version 
in README.md's "Terraform and Provider Requirements" table to reflect the current 
version in .terraform.lock.hcl.
```

**Expected updates:**
- README.md: AWS provider version updated in requirements table
- Verification that no other documentation needs updates
- Confirmation no Terraform code was modified

---

### Scenario 2: New Variable Added

**What changed:**
- New variable `NotificationEmail` added to `var.tf`

**Request to Bob:**
```
Please refresh the repository documentation using DOCUMENTATION_REFRESH_PROMPT.md.

A new variable "NotificationEmail" (string type, required) was added to var.tf. 
Add this to the Variables Reference section in docs/OPERATIONS.md and update 
README.md variables overview if needed.
```

**Expected updates:**
- docs/OPERATIONS.md: New row added to Variables Reference table
- README.md: Variables section updated if user-facing
- Verification that variable documentation is complete

---

### Scenario 3: Resource Removed

**What changed:**
- The `aws_security_group_rule` for port 9091 was deleted

**Request to Bob:**
```
Please refresh the repository documentation using DOCUMENTATION_REFRESH_PROMPT.md.

The security group rule for port 9091 (metrics) was removed. Update:
- docs/ARCHITECTURE.md: Remove port 9091 from Security Group Ingress Rules table
- docs/OPERATIONS.md: Remove port 9091 from any deployment procedures
- README.md: Update if port 9091 is referenced anywhere
```

**Expected updates:**
- ARCHITECTURE.md: Port 9091 removed from security group documentation
- OPERATIONS.md: Port references updated
- README.md: References removed if present
- Architecture diagrams updated if affected

---

### Scenario 4: Quarterly Maintenance Review

**What changed:**
- Everything — general accuracy check

**Request to Bob:**
```
Please perform a quarterly documentation refresh using DOCUMENTATION_REFRESH_PROMPT.md.

Verify all documentation is current with the repository as it exists today:
- All resource names and types match .tf files
- All provider versions match .terraform.lock.hcl
- All variables match var.tf
- All outputs match *outputs.tf files
- Deployment procedures still match current setup
- Examples and troubleshooting are still relevant

Update anything that has drifted from reality.
```

**Expected updates:**
- Any outdated version numbers updated
- Any changed resource names or types updated
- Any new observations documented
- Confirmation all documentation is current

## Checklist: Before Requesting a Refresh

Before asking for a documentation refresh, verify:

- [ ] The change was made to actual `.tf` or configuration files
- [ ] The change is complete (not in progress)
- [ ] You can describe what changed specifically
- [ ] You know which documentation files might be affected
- [ ] No other changes are in progress that would require another refresh soon

## Tips for Maintaining Documentation Quality

1. **Request Refreshes Early** — After making changes, request a refresh quickly while changes are fresh in mind

2. **Be Specific** — Tell Bob exactly what changed (e.g., "AWS provider updated from 6.27.0 to 6.28.0")

3. **Quarterly Reviews** — Schedule quarterly full documentation reviews to catch drift

4. **Document as You Code** — When adding a resource, document it at the same time

5. **Review Pull Requests** — Check documentation changes in PRs using the checklist in docs/MAINTENANCE.md

## Related Files

- **DOCUMENTATION_REFRESH_PROMPT.md** — The detailed refresh procedure
- **README.md** — Main entry point (updated frequently)
- **docs/ARCHITECTURE.md** — Resource details (updated when architecture changes)
- **docs/OPERATIONS.md** — Procedures (updated when deployment changes)
- **docs/MAINTENANCE.md** — Includes contributor checklist (reference during reviews)

---

**Remember:** Documentation is a living artifact. Keep it current, keep it accurate, and it will keep your team productive.
