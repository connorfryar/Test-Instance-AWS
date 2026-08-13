# Maintenance Guide

This document provides guidelines for maintaining and evolving this Terraform repository over time. Use this as a reference when making changes, adding features, or updating documentation.

## Audience

This guide is intended for:
- Repository maintainers
- Engineers adding or modifying infrastructure
- DevOps teams managing deployment procedures
- New contributors onboarding to the project

## Documentation Structure Overview

The repository documentation is organized as follows:

```
README.md
  └─ Primary entry point, quick-start, architecture overview

docs/
  ├─ ARCHITECTURE.md
  │  └─ Resource details, dependencies, network flows, scaling considerations
  ├─ OPERATIONS.md
  │  └─ Deployment procedures, variable reference, troubleshooting
  └─ MAINTENANCE.md (this file)
     └─ Contributor guidelines, change procedures, documentation maintenance
```

**Principle:** Keep documentation as a single source of truth. All architecture, procedures, and design decisions should be discoverable from these files.

---

## Change Procedures

### Adding a New Resource

When adding a new AWS resource (e.g., new security group rule, EBS volume, Lambda function):

**Before Implementation:**
1. [ ] Determine resource purpose and dependencies
2. [ ] Identify which `.tf` file it belongs in (use existing organization)
3. [ ] Identify if it requires new variables
4. [ ] Determine if it needs new outputs

**After Implementation:**
1. [ ] Add variable definitions to `var.tf` if needed (with type, description, defaults)
2. [ ] Add resource definition to appropriate `.tf` file
3. [ ] Add data source lookups if referencing external resources
4. [ ] Add outputs to `outputs.tf` or appropriate `*outputs.tf` file
5. [ ] Test: `terraform validate && terraform fmt -check && terraform plan`
6. [ ] Update [`docs/ARCHITECTURE.md`](ARCHITECTURE.md):
   - Add resource to Resource Composition table
   - Update architecture diagram if resource affects topology
   - Document dependencies in Dependency Graph section
7. [ ] Update [`docs/OPERATIONS.md`](OPERATIONS.md):
   - Add new variables to Variables Reference section
   - Add new outputs to Outputs Reference section
   - Update deployment walkthrough if deployment procedure changed
8. [ ] Update [`README.md`](../README.md):
   - Update Project Overview if infrastructure purpose changed
   - Update Variable documentation if new inputs exist
   - Update architecture diagram if topology changed
9. [ ] Update this checklist below if applicable

---

### Adding a New Input Variable

When adding a new `variable` block to `var.tf`:

**Before Implementation:**
1. [ ] Determine variable name (should be descriptive and consistent with existing naming)
2. [ ] Determine type: `string`, `number`, `list`, `map`, `object`, etc.
3. [ ] Determine if required or optional (provide sensible default if optional)
4. [ ] Determine if sensitive (e.g., database password, API key)
5. [ ] Determine validation rules if needed

**After Implementation:**
1. [ ] Add complete variable block with `description`, `type`, `default` (if applicable)
2. [ ] Add validation block if constraints exist (e.g., `EBSSize < 100`)
3. [ ] Test: `terraform validate`
4. [ ] Update [`docs/OPERATIONS.md`](OPERATIONS.md) Variables Reference section:
   - Add row to table with variable name, type, default, requirement, purpose
   - Provide examples of valid values
   - Note if required (⚠️)
5. [ ] If required, add to `.tfvars.example` (create if doesn't exist):
   ```hcl
   # Example of new variable with explanation
   new_variable = "example-value"  # Purpose: ...
   ```
6. [ ] Update [`README.md`](../README.md) Variables section if user-facing

---

### Adding a New Output

When adding new outputs:

**Before Implementation:**
1. [ ] Determine what data is useful for consumers (other modules, users, tools)
2. [ ] Choose output name (descriptive, consistent with existing naming)
3. [ ] Determine if output should be sensitive (mark `sensitive = true` if needed)

**After Implementation:**
1. [ ] Add output block to `outputs.tf` or appropriate `*outputs.tf` file
2. [ ] Include `description` explaining what value means and how to use it
3. [ ] Test: `terraform apply && terraform output`
4. [ ] Update [`docs/OPERATIONS.md`](OPERATIONS.md) Outputs Reference section:
   - Add row to table with output name, source, purpose
   - Provide example value
   - Note use case
5. [ ] Update [`README.md`](../README.md) Outputs section if consumer-facing

---

### Adding a New Provider or Changing Provider Versions

When adding a new provider or updating `required_providers`:

**Before Implementation:**
1. [ ] Determine if provider is necessary (avoid unnecessary dependencies)
2. [ ] Choose appropriate version constraint (e.g., `~> 5.0` for AWS)
3. [ ] Verify compatibility with current Terraform version constraint

**After Implementation:**
1. [ ] Add provider block to `providers.tf`
2. [ ] Update `required_providers` version constraint
3. [ ] Run `terraform init` to download new provider and update `.terraform.lock.hcl`
4. [ ] Test: `terraform plan`
5. [ ] Update [`README.md`](../README.md) "Terraform and Provider Requirements" section:
   - Add provider to requirements table
   - Note version constraint and current version
6. [ ] Update [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) if provider affects architecture

---

### Adding a New Module or Module Reference

If splitting code into modules (not currently in use):

**Before Implementation:**
1. [ ] Justify modularity (e.g., code reuse, environment separation)
2. [ ] Design module boundaries (inputs, outputs, responsibilities)
3. [ ] Create module directory structure

**After Implementation:**
1. [ ] Implement module code in `modules/<module_name>/`
2. [ ] Create `modules/<module_name>/variables.tf`, `outputs.tf`, `main.tf`
3. [ ] Add module call to root configuration
4. [ ] Test: `terraform init && terraform plan`
5. [ ] Document in new file `docs/MODULES.md`:
   - Module purpose, inputs, outputs
   - How root calls the module
   - Dependencies and assumptions
6. [ ] Update [`docs/ARCHITECTURE.md`](ARCHITECTURE.md):
   - Add module diagram showing composition
   - Document module dependencies
7. [ ] Update [`README.md`](../README.md) Repository Structure section
8. [ ] Update this file with modules section in maintenance checklist

---

### Updating Terraform or Version Constraints

When updating `terraform` `required_version`:

**Before Implementation:**
1. [ ] Test current configuration with target Terraform version
2. [ ] Review Terraform release notes for breaking changes
3. [ ] Verify AWS provider supports target Terraform version

**After Implementation:**
1. [ ] Update or add `required_version` constraint in `providers.tf`
   ```hcl
   terraform {
     required_version = ">= 1.0"
   }
   ```
2. [ ] Test locally: `terraform init && terraform plan`
3. [ ] Verify `.terraform.lock.hcl` updates appropriately
4. [ ] Update [`README.md`](../README.md) "Terraform and Provider Requirements" section
5. [ ] Test in CI/CD environment if applicable

---

### Significant Architecture Changes

When restructuring infrastructure (e.g., adding new environment, changing networking):

**Planning Phase:**
1. [ ] Document current state in [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
2. [ ] Create design document outlining changes and rationale
3. [ ] Identify breaking changes or backwards-compatibility concerns
4. [ ] Plan migration/deployment strategy

**Implementation Phase:**
1. [ ] Implement changes in `.tf` files
2. [ ] Test: `terraform plan` and review resources being modified
3. [ ] If state migration needed, plan `terraform state mv` commands

**Documentation Phase:**
1. [ ] Update [`docs/ARCHITECTURE.md`](ARCHITECTURE.md):
   - Update architecture diagram
   - Update resource composition table
   - Update dependency graph
   - Update data source documentation
2. [ ] Update [`README.md`](../README.md):
   - Update Project Overview if purpose changed
   - Update Repository Structure if file organization changed
   - Update Architecture section if topology changed
3. [ ] Update [`docs/OPERATIONS.md`](OPERATIONS.md):
   - Update deployment walkthrough if procedure changed
   - Update troubleshooting if relevant
4. [ ] Update this section of MAINTENANCE.md if pattern changed

---

## Documentation Maintenance Checklist

Use this checklist during code review or pull request approval to ensure documentation stays current with implementation:

### On Every Pull Request

- [ ] **Code Changes Reviewed**
  - `.tf` files match Terraform best practices
  - Variable and output descriptions are clear
  - Resource naming is consistent

- [ ] **README.md Current**
  - Project Overview accurately describes infrastructure
  - Repository Structure matches file organization
  - Architecture diagram reflects actual resources
  - Variables section lists all user-facing inputs
  - Outputs section lists all user-facing outputs

- [ ] **Architecture Documentation Current** (`docs/ARCHITECTURE.md`)
  - Resource Composition table includes all resources
  - Resource relationships documented
  - Dependency Graph reflects actual references
  - Data sources documented
  - New resources added to appropriate architecture section

- [ ] **Operations Documentation Current** (`docs/OPERATIONS.md`)
  - Deployment walkthrough matches current procedure
  - All input variables documented in Variables Reference
  - All outputs documented in Outputs Reference
  - Troubleshooting section covers new error conditions

- [ ] **Version Constraints Updated**
  - `providers.tf` has correct `required_providers` versions
  - `.terraform.lock.hcl` is up to date
  - README provider table reflects actual versions

- [ ] **Variables and Outputs Complete**
  - New variables in `var.tf` have descriptions
  - New outputs have descriptions
  - Sensitive variables marked `sensitive = true` where appropriate
  - Examples provided in documentation

### Monthly Documentation Review

- [ ] [ ] Review README for accuracy and clarity
- [ ] [ ] Verify all links in documentation work
- [ ] [ ] Check Architecture diagram for accuracy
- [ ] [ ] Validate Troubleshooting section with recent support issues
- [ ] [ ] Confirm version numbers match reality (provider, Terraform, TFE)

### Quarterly Documentation Audit

- [ ] Review all observations in "Observations / Potential Follow-Up" section:
  - [ ] Have any been resolved? Update or remove.
  - [ ] Are new observations needed? Add them.
  - [ ] Do they still apply to current version?

- [ ] [ ] Review Examples section for outdated values or incorrect paths

- [ ] [ ] Verify dependency and component diagrams still match implementation

- [ ] [ ] Check for documentation TODOs or unfinished sections

---

## Common Maintenance Tasks

### Regenerating Architecture Diagram

The architecture diagram in `README.md` is ASCII-art. When infrastructure changes:

1. Update diagram structure to match new resources
2. Ensure indentation and connections are clear
3. Example tools: `graphviz`, `mermaid`, or ASCII art editors
4. After updating, verify in markdown preview

### Updating Provider Versions

When provider updates are available:

```bash
# Check for updates
terraform init -upgrade

# Review changes in .terraform.lock.hcl
git diff .terraform.lock.hcl

# Update README with new version
# Example: AWS 6.27.0 → 6.28.0
```

### Adding Screenshots or Diagrams

If adding visual documentation (screenshots of console, network diagram):

1. Keep files in `docs/images/` directory (create if needed)
2. Use descriptive filenames (e.g., `route53-a-record-setup.png`)
3. Add `.gitignore` entry if needed
4. Reference in documentation with relative paths

### Documenting New Error Conditions

When issues are discovered and resolved:

1. Add to Troubleshooting section in [`docs/OPERATIONS.md`](OPERATIONS.md)
2. Include:
   - Error message (exact or paraphrased)
   - Root cause explanation
   - Resolution steps
   - Prevention advice

### Refactoring or Reorganizing Code

If `.tf` files are split, consolidated, or reorganized:

1. Update [`README.md`](../README.md) Repository Structure section
2. Add comments explaining organization rationale
3. Update all documentation references to file locations
4. Test: `terraform validate`

---

## Documentation Standards

### Writing Style

- **Technical Language:** Use precise, technical terminology
- **Active Voice:** Prefer "the resource creates an EC2 instance" over "an EC2 instance is created"
- **Clear Examples:** Provide concrete examples with expected output
- **Scannable:** Use headers, tables, and code blocks for readability
- **No Marketing:** Avoid sales language or promotional content

### Naming Conventions

- **Files:** Use descriptive names (e.g., `ARCHITECTURE.md`, not `arch.md`)
- **Variables:** Use PascalCase or snake_case (consistent with existing)
- **Resources:** Use descriptive names with type prefix (e.g., `aws_instance.TestInstanceInstance`)
- **Outputs:** Use snake_case, descriptive names

### Code Examples

- Always include language identifier: ` ```hcl `, ` ```bash `, ` ```json `
- Show full command and expected output
- Highlight important lines with comments
- Provide before/after examples for changes

### Links

- Use relative paths for internal documentation links
- Make links descriptive (e.g., `[ARCHITECTURE.md](docs/ARCHITECTURE.md)`, not `[click here]`)
- Verify links work after making documentation changes

---

## Deprecation Procedures

When a resource, variable, or feature needs to be deprecated:

1. **Announce in Code:** Add comment explaining deprecation
   ```hcl
   # DEPRECATED: Use NewFeature instead (v1.2.0+)
   # Scheduled for removal: v2.0.0
   variable "OldVariable" {
     # ...
   }
   ```

2. **Document in OPERATIONS.md:** Add migration guide
   ```markdown
   ### Migrating from OldVariable to NewFeature
   If using OldVariable, migrate to NewFeature by:
   1. Update var.tf to use NewFeature
   2. Run terraform plan to review changes
   3. Apply changes with terraform apply
   ```

3. **Add to Observations:** Document deprecation rationale

4. **Remove in Next Major Version:** After deprecation period

---

## Troubleshooting Documentation Debt

### Warning Signs

- Documentation describes different behavior than code
- No comments in complex `.tf` files
- Examples don't match current output
- Version numbers are stale
- Broken internal links

### Resolving Debt

1. **Quick Fixes:** Typos, outdated version numbers (15 minutes)
2. **Medium Fixes:** Update examples, verify links (1 hour)
3. **Large Fixes:** Rewrite sections, add missing architecture (half day)

### Prevention

- Review documentation during code review
- Use documentation as acceptance criteria for features
- Schedule quarterly documentation audits

---

## Related Documentation

- **README.md:** Project overview and quick start
- **ARCHITECTURE.md:** Technical architecture details
- **OPERATIONS.md:** Deployment and troubleshooting procedures
- **Terraform Configuration:** Comments in `.tf` files explaining non-obvious patterns

---

## Appendix: Documentation Templates

### New Resource Documentation Template

When adding a new resource, use this template:

```hcl
# aws_example_resource "name"
# Purpose: [Describe what this resource does]
# Dependencies: [List upstream resources]
# Configuration: [Key settings explained]
# Lifecycle: [Any special lifecycle rules]

resource "aws_example_resource" "name" {
  # Configuration...
}
```

### New Variable Documentation Template

In `var.tf`:

```hcl
variable "ExampleVariable" {
  type        = string
  description = "Clear description of purpose and usage"
  default     = "default-value"  # Remove if required
  
  # Add validation if constraints exist
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.ExampleVariable))
    error_message = "Must contain only lowercase letters, numbers, and hyphens."
  }
}
```

In `OPERATIONS.md`:

```markdown
#### `ExampleVariable`
- **Type:** `string`
- **Default:** `"default-value"`
- **Required:** No
- **Description:** Purpose and usage details
- **Valid Values:** List of acceptable values or format
- **Example:** `ExampleVariable = "example-value"`
```

### Troubleshooting Entry Template

In `OPERATIONS.md`:

```markdown
### Issue Description

**Error:**
```
error message here
```

**Cause:** Root cause explanation

**Solution:**
1. First step
2. Second step

**Verify:**
```bash
command to confirm resolution
```
```

---

**Last Updated:** Generated from maintenance analysis.
**Maintenance Responsibility:** Repository maintainers and contributors.
