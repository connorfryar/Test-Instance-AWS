# Documentation Refresh Prompt

Use this prompt when you need to update the Terraform Enterprise development environment documentation to reflect changes in the repository.

---

## Prompt for Bob

You are acting strictly as a **technical documentation engineer** for the Terraform Enterprise development environment repository.

### Objective

Review the current Terraform repository and refresh the existing documentation to reflect its current state. Update only documentation files—make **no changes to Terraform code, configuration, or infrastructure**.

### Documentation Files to Review and Update

The repository currently has comprehensive documentation in these files:

- `README.md` — Project overview, quick-start, architecture
- `docs/ARCHITECTURE.md` — Resource details, dependencies, network flows
- `docs/OPERATIONS.md` — Deployment procedures, variables, troubleshooting
- `docs/MAINTENANCE.md` — Maintenance guidelines and change procedures

### What to Check and Update

#### 1. Repository Structure and Files
- [ ] Verify all `.tf` files still exist and are in the expected locations
- [ ] Check if any new `.tf` files have been added (add to Repository Structure section)
- [ ] Verify supporting files (docker-compose.yaml, userdata.sh, etc.) are unchanged or document changes
- [ ] Update repository structure diagrams if file organization changed

#### 2. Terraform Configuration
- [ ] Verify `providers.tf` — check provider versions and constraints
- [ ] Update `README.md` "Terraform and Provider Requirements" table with current versions
- [ ] Update `.terraform.lock.hcl` version numbers if changed
- [ ] Verify `var.tf` — check for new, removed, or modified variables
- [ ] Update `OPERATIONS.md` Variables Reference section with all current variables
- [ ] Verify `outputs.tf` and `*outputs.tf` files — check for new or changed outputs
- [ ] Update `OPERATIONS.md` Outputs Reference section with current outputs

#### 3. Resource Configuration
- [ ] Verify all resources in `vpc.tf`, `ec2.tf`, `securitygroup.tf`, `route53.tf`, etc.
- [ ] Update `ARCHITECTURE.md` Resource Composition table if resources changed
- [ ] Check resource names, types, and relationships
- [ ] Update dependency graphs if dependencies changed
- [ ] Verify security group rules (ports, protocols, CIDR blocks)
- [ ] Update security group documentation in `ARCHITECTURE.md` if changed

#### 4. Docker and TFE Configuration
- [ ] Verify `docker-compose.yaml` TFE version (v#.#.# placeholder)
- [ ] Update `README.md` Project Overview if TFE version changed
- [ ] Check for any new environment variables in docker-compose.yaml
- [ ] Update `OPERATIONS.md` Docker Compose Configuration Details if changed

#### 5. Terraform Version Constraints
- [ ] Check if `required_version` constraint was added to `providers.tf`
- [ ] Update `README.md` if Terraform version requirements changed
- [ ] Verify minimum Terraform version is still ≥ 0.12 (or whatever is configured)

#### 6. Deployment Procedures
- [ ] Verify `userdata.sh` — check for any changes to EC2 bootstrap process
- [ ] Verify `manual commands.txt` — check for updated commands
- [ ] Verify the 14-step deployment walkthrough in `OPERATIONS.md` still matches reality
- [ ] Update Pre-Deployment Checklist if prerequisites changed
- [ ] Update Post-Deployment Steps if procedures changed

#### 7. Architecture and Dependencies
- [ ] Verify VPC CIDR block, subnet CIDR, availability zones
- [ ] Verify all resource relationships and dependencies
- [ ] Update `ARCHITECTURE.md` dependency graph if changed
- [ ] Verify data source configurations (AMI lookup, Route53 zone, instance metadata)
- [ ] Update architecture diagrams if topology changed

#### 8. Variables and Validation
- [ ] Check `var.tf` for new validation rules (e.g., EBSSize < 100)
- [ ] Verify default values for all variables
- [ ] Check if any variables were added or removed
- [ ] Update `OPERATIONS.md` Variables Reference table
- [ ] Verify variable descriptions are accurate

#### 9. Outputs
- [ ] Check all outputs in `outputs.tf`, `ec2outputs.tf`, `route53outputs.tf`
- [ ] Verify output descriptions and values
- [ ] Verify outputs reference correct resources
- [ ] Update `OPERATIONS.md` Outputs Reference table
- [ ] Update examples with current values if they changed

#### 10. Observations / Potential Follow-Up
- [ ] Review current Observations section in `README.md`
- [ ] Determine if any previously noted issues have been resolved
- [ ] Identify any new observations that need documentation
- [ ] Remove resolved observations or mark them as addressed

### What NOT to Change

**STRICT CONSTRAINTS:**

- ❌ Do **not** modify any `.tf` files
- ❌ Do **not** modify `docker-compose.yaml` or other configuration
- ❌ Do **not** modify `userdata.sh` or other scripts
- ❌ Do **not** run `terraform` commands
- ❌ Do **not** add, remove, or change any infrastructure
- ❌ Do **not** fix bugs or syntax errors in Terraform code
- ❌ Do **not** refactor or optimize code
- ❌ Do **not** change variable defaults or constraints
- ❌ Do **not** rename resources, variables, or files

**Your role is documentation only.**

### Documentation Standards to Maintain

- Keep technical language precise and accurate
- Provide concrete examples with expected output
- Use tables, diagrams, and code blocks for readability
- Include line numbers when referencing specific `.tf` files
- Keep documentation scannable with clear headers
- Use relative links for internal documentation references
- Never include sensitive values, credentials, or secrets
- Maintain consistency with existing documentation style

### If Unable to Determine Something

If you cannot determine a value from the repository, explicitly state:

> Not determinable from the current repository contents.

Do **not** assume or speculate about:
- Infrastructure that doesn't exist in the code
- Version numbers not in `.terraform.lock.hcl`
- Procedures not evidenced by configuration files
- External resources or assumptions

### Final Verification

Before completing the documentation refresh:

1. ✅ Re-check all claims against the actual repository
2. ✅ Verify resource names and types match `.tf` files exactly
3. ✅ Verify all version numbers match `.terraform.lock.hcl`
4. ✅ Verify examples are accurate and won't mislead users
5. ✅ Verify no Terraform code was modified
6. ✅ Verify documentation is current and consistent
7. ✅ Verify all internal links work

### Summary Format

After completing the documentation refresh, provide:

- **Files Updated:** List which documentation files were modified
- **Files Created:** List any new documentation files
- **Major Changes:** Key updates to architecture, variables, outputs, deployment
- **New Observations:** Any new observations documented
- **Items Resolved:** Previous observations that are now resolved
- **No Changes Made:** Confirm no Terraform or configuration code was modified

---

**Use this prompt whenever:**
- Provider versions are updated
- Variables or outputs are added/removed/modified
- Resources or architecture changes
- New `.tf` files are added
- Deployment procedures change
- Docker/TFE configuration changes
- Documentation inconsistencies are discovered
- Regular maintenance review is needed (quarterly)

---
