# notify — agent-to-user notification helper

One tiny script (`notify.py`) for pinging you when a long-running agent task
finishes. Supports email (AgentMail) today; Teams webhook plug-and-play once
you set `TEAMS_WEBHOOK_URL`.

## Quick reference

```powershell
# Simple success
python tools\notify\notify.py --subject "Backfill done" --body "3,412 rows applied"

# Failure (red stripe in Teams; [FAIL] prefix in subject)
python tools\notify\notify.py --subject "Cron failed" --status fail --body "see log at ..."

# Pipe a log file as the body
Get-Content tools\sp_crypto_nop_audit\logs\2026-06-09.log | `
    python tools\notify\notify.py --subject "Audit log" --body -

# Both channels at once (once Teams webhook is set)
python tools\notify\notify.py --subject "Done" --channel email,teams --body "..."

# From inside a Python script
from tools.notify.notify import notify
notify(subject="Task complete", body="...", status="ok", channels=["email","teams"])
```

Status values:
| status | subject prefix | Teams color |
|---|---|---|
| `ok`   | `[OK]`   | green  |
| `warn` | `[WARN]` | yellow |
| `fail` | `[FAIL]` | red    |
| `info` | `[INFO]` | blue   |

Every notification includes a footer with `host / cwd / pid / ts` so you can
identify which session sent it. Suppress with `--no-context`.

## Credentials

Loaded from `%USERPROFILE%\.cursor\notify-credentials.env` (auto, never logged):

```
AGENTMAIL_API_KEY=am_us_...
AGENTMAIL_INBOX_ID=gmanova@agentmail.to
NOTIFY_DEFAULT_TO=guyman@etoro.com
# TEAMS_WEBHOOK_URL=https://etoro.webhook.office.com/...     # see below
```

## Setting up a Teams webhook

Microsoft is sunsetting the legacy "Office 365 Connector" webhooks; the modern
way is a **Power Automate Workflow**. Either works with this script — the
JSON body it sends is the MessageCard schema both accept.

### Modern way (Workflows, recommended)

1. In Teams, open the **chat** or **channel** you want notifications in.
2. Click the `+` tab → search **Workflows** → click **Workflows**.
3. Choose template: **"Post to a channel when a webhook request is received"**
   (for channels) or **"Post to a chat when a webhook request is received"**
   (for 1:1 / group chat).
4. Sign in / accept defaults → **Next** → confirm channel/chat → **Create**.
5. Copy the **HTTP POST URL** at the end of the wizard — it looks like
   `https://prod-XX.westeurope.logic.azure.com:443/workflows/.../triggers/manual/...`.
6. Paste it into `~/.cursor/notify-credentials.env` as
   `TEAMS_WEBHOOK_URL=<that-url>`.
7. Test:
   ```powershell
   python tools\notify\notify.py --subject "Teams plumbing online" --channel teams
   ```

### Legacy way (Office 365 Connector — still works if your tenant allows it)

1. Channel name → ⋯ → **Connectors** → **Incoming Webhook** → **Configure**.
2. Name it, upload an icon (optional), **Create** → copy the URL.
3. Same step 6/7 above.

## A simpler alternative — ntfy.sh (mobile push, zero auth)

If what you actually want is a phone push when something finishes, [ntfy.sh](https://ntfy.sh)
is the dead-simplest option:

1. Install the **ntfy** app on your phone (free, iOS/Android).
2. Pick a private topic name like `guyman-agent-notifs-xyz789`.
3. Subscribe to that topic in the app.
4. Send a notification from anywhere with one curl:
   ```powershell
   Invoke-WebRequest -Method POST `
       -Uri "https://ntfy.sh/guyman-agent-notifs-xyz789" `
       -Body "Audit done, 3 errors"
   ```

No accounts, no API keys, push lands on your phone in <1 second. The downside
is the topic name is the only "secret" so anyone who guesses it can spam you.
If you want this added as a `--channel ntfy` option in `notify.py`, say the word.

## How to wire this into long-running scripts

End-of-script pattern that works for any Python long-runner (cron jobs,
backfills, audits):

```python
import traceback
from tools.notify.notify import notify

def main():
    # ... do the long-running work ...
    rows = 12345
    return rows

if __name__ == "__main__":
    try:
        rows = main()
        notify(
            subject=f"Backfill finished — {rows:,} rows",
            body=f"OK in $(elapsed)s. Output at: ...",
            status="ok",
            channels=["email", "teams"],  # belt + suspenders
        )
    except Exception:
        notify(
            subject="Backfill FAILED",
            body=traceback.format_exc(),
            status="fail",
            channels=["email", "teams"],
        )
        raise
```

For PowerShell wrappers (like `tools\sp_crypto_nop_audit\poll_and_report.ps1`):

```powershell
$exitCode = $LASTEXITCODE
$status = if ($exitCode -eq 0) { "ok" } else { "fail" }
python C:\path\to\Databricks_Knowledge\tools\notify\notify.py `
    --subject "SP_Crypto_NOP audit run" `
    --status $status `
    --body-file tools\sp_crypto_nop_audit\logs\$today.log
```
