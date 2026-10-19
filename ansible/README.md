# Ansible: host changes for the test instance

Everything that changes the instance after Terraform creates it (TFE version, container settings, extra containers) goes through these playbooks, run from this directory.

```bash
cd ansible
ansible-playbook playbooks/<playbook>.yml -e ...
```

The inventory uses the `docker-tfe-test-instance` alias from `~/.ssh/config`. Update that alias's `HostName` when the instance's public IP changes.

| Playbook | What it does |
|---|---|
| `playbooks/tfe-compose.yml` | Changes the TFE image version (`tfe_version`) and the `/tmp` tmpfs size (`tfe_tmp_size`) in the existing `docker-compose.yaml`, then restarts TFE and waits for `/_health_check`. `tfe_fresh_data=true` moves the data directory aside first (needed for a downgrade) and writes the initial admin link to `/root/tfe-iact-url.txt`. Edits keep a `.bak` copy of the compose file. |
| `playbooks/tfc-agent.yml` | Replaces the `tfc-agent-NN` containers: `tfc_agent_count` agents at `tfc_agent_version`, registered to this TFE with `TFC_AGENT_TOKEN` from your environment. `tfc_agent_state=absent` removes them. |

Examples:

```bash
# Fresh TFE 1.2.1
ansible-playbook playbooks/tfe-compose.yml -e tfe_version=1.2.1 -e tfe_fresh_data=true

# Small /tmp for a disk-pressure test, then back to the default (half of RAM)
ansible-playbook playbooks/tfe-compose.yml -e tfe_tmp_size=200m
ansible-playbook playbooks/tfe-compose.yml

# Three agents
TFC_AGENT_TOKEN=... ansible-playbook playbooks/tfc-agent.yml -e tfc_agent_count=3
```
