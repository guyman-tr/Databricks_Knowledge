---
description: "Create a Deploy Approval (Change Request) in JSM from a Jira ticket key. Auto-fills all Data Group defaults and submits — zero manual form filling."
---

# Deploy Approval — Auto-Create Change Request

The user wants to create an OC (Operations Changes) Change Request for a Jira ticket.

## Input

Ask the user for:
1. **Jira ticket key** (e.g., `DSM-2790`) — REQUIRED
2. **Change type** — optional, default "New Feature". Options: "New Feature", "Bug Fix", "Hotfix", "Configuration Change"
3. **Any overrides** — optional: DBA involved? Custom rollback minutes? Custom deployment window?

## Execution

### Step 1: Read the source Jira ticket

Use the Atlassian MCP:

```
getJiraIssue(cloudId: "1d3038a6-59ab-451c-bf3b-55c45c5a07d8", issueIdOrKey: "<TICKET_KEY>", responseContentFormat: "markdown")
```

Extract: `summary`, `description`, `project.key`

### Step 2: Run the PowerShell script

The script is at `.cursor/scripts/New-ChangeRequest.ps1`. Run it:

```powershell
.\.cursor\scripts\New-ChangeRequest.ps1 -TicketKey "<TICKET_KEY>"
```

Optional parameters:
- `-ChangeType "Bug Fix"` — override change type
- `-DbaInvolved` — flag if DBA is involved
- `-RollbackMinutes 30` — override rollback duration
- `-PlannedStart "2026-03-20T08:00:00.000+0200"` — custom start time
- `-PlannedEnd "2026-03-20T14:00:00.000+0200"` — custom end time
- `-DryRun` — preview the payload without submitting
- `-Summary "custom summary"` — override summary
- `-Description "custom description"` — override description

### Step 3: Handle the result

**If the script succeeds**:
- It will print the OC ticket key and URL
- It will auto-link the OC ticket to the source ticket
- Tell the user: "Change request created and linked. Approval workflow has started."

**If the script fails** (API error):
- The script automatically falls back to opening the JSM portal URL with pre-filled fields
- Tell the user they need to click Submit in the browser

### Step 4: Offer next steps

After creation, ask the user:
- "Want me to transition `<TICKET_KEY>` to 'Done' now, or wait for the OC approval first?"
- "Want me to add a comment on the source ticket with the OC link?"

## First-time setup

If the user hasn't set up their API token yet, the PowerShell script will prompt them.
They need:
1. An Atlassian API token from https://id.atlassian.com/manage-profile/security/api-tokens
2. Their Atlassian email (guyman@etoro.com)

The credentials are stored locally in `.cursor/scripts/jira-creds.json` (gitignored).

## Data Group Defaults Reference

These defaults match the Data Group's typical deployment pattern:

| Field | Default | Field ID | Option ID |
|-------|---------|----------|-----------|
| Change Type | New Feature | customfield_14177 | 18888 |
| Downtime | No | customfield_14180 | 18899 |
| Business Impact | No | customfield_14181 | 18904 |
| DBA Involved | No | customfield_14184 | 18906 |
| Multiple Domains | No | customfield_14185 | 18908 |
| Rollback Duration | 10 min | customfield_14186 | (numeric) |
| Describe Risks | none | customfield_14188 | (text) |
| Rollback Tested | Yes | customfield_10602 | 12043 |
| Validation Status | Tested in alt env | customfield_14194 | 20126 |
| Change Category | Planned | customfield_10494 | 11270 |

## JSM Reference

- **Service Desk ID**: 1073
- **Request Type ID**: 1133 (General Change Request)
- **Issue Type ID**: 10423 (Change Management)
- **Project**: OC (Operations Changes)
- **Link Type**: Defect (id: 10216, inward: "created by", outward: "created")
