# DDR recurring-investment decoupling canary

Daily check that the **2026-06 "fund recurring investments from available USD balance"**
decoupling has **not regressed into data loss** on the Databricks side, with an
AgentMail status email.

## What & why

Recurring positions can now open **without a deposit** (funded from balance), so a
successful position can have a `NULL DepositID`. The Synapse DDR pipeline was audited and
is safe — every consumer keys on `PositionID`, never `DepositID`:

- `Function_Trading_Volume` / `_PositionLevel` / `Function_Revenue_Trading_Instrument_Level`
  — `LEFT JOIN` bridge `ON PositionID`, flag `rec.PositionID IS NOT NULL`.
- `SP_DDR_Fact_Revenue_Generating_Actions` — loads bridge into `#isRecurring`, then
  `UPDATE ... SET IsRecurring=1 ... INNER JOIN #isRecurring ON PositionID` (DepositID loaded
  but never referenced; UPDATE so no rows dropped).
- `SP_DDR_Fact_MIMO_Trading_Platform` — `IsRecurring` from `Fact_BillingDeposit.IsRecurring`
  (deposit side; counts recurring *deposits*, not the bridge).

The one way the decoupling could still cause loss is if the **Databricks positions bridge**
stopped carrying deposit-less positions (e.g. a writer change re-introducing a deposit gate).
This canary watches exactly that.

## The check (volume-independent)

| Metric | Meaning |
|---|---|
| `bridge_total` | rows in `main.bi_output.bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet` |
| `bridge_balance_funded` | rows with `PositionID` present and `DepositID` NULL/0 |
| `src_balfunded` | `planinstances` rows: `PositionStatus=1 AND DepositID IS NULL` |
| `src_balfunded_withorder` | …and `OrderID IS NOT NULL` |

Verdict:
- **FAIL** — `bridge_total = 0` (pipeline stalled), or `src_balfunded > 0` while
  `bridge_balance_funded = 0` (regression → deposit-less positions dropped).
- **WARN** — bridge carries <50% of the source's resolvable deposit-less positions, or
  `bridge_total` dropped >50% vs the last run.
- **OK** — invariants hold (including the all-zero early-rollout case: nothing to lose).

State is kept in `out/last_run.json` for trend comparison; logs in `out/logs/<date>.log`.

## Run manually

```powershell
# dry run, no email
python tools\ddr_recurring_canary\check.py --no-email

# real run, email only on WARN/FAIL
python tools\ddr_recurring_canary\check.py

# real run, always email (daily heartbeat — what the scheduled task uses)
python tools\ddr_recurring_canary\check.py --always-email
```

Auth = same as the Cursor Databricks MCP (`WorkspaceClient` + `~/.databrickscfg`,
profile `DATABRICKS_MCP_PROFILE` or `guyman`). Email via `tools/notify/notify.py`
(AgentMail creds in `~/.cursor/notify-credentials.env`, recipient `NOTIFY_DEFAULT_TO`).

## Daily schedule (Windows Task Scheduler)

Registered as task **`DDR_Recurring_Canary`**, daily at **11:00 local** (safely after the
~07:10Z planinstances refresh). Per-user task (runs when you're logged on — no admin needed):

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\guyman\Documents\github\Databricks_Knowledge\tools\ddr_recurring_canary\run_canary.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 11:00am
$settings= New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 20)
Register-ScheduledTask -TaskName "DDR_Recurring_Canary" -Action $action -Trigger $trigger -Settings $settings -Force
```

> To run **whether logged on or not**, re-register from an **elevated** shell adding
> `-Principal (New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Limited)`.

Manage:
```powershell
Start-ScheduledTask    -TaskName "DDR_Recurring_Canary"   # run now
Get-ScheduledTaskInfo  -TaskName "DDR_Recurring_Canary"   # LastRunTime / LastTaskResult / NextRunTime
Unregister-ScheduledTask -TaskName "DDR_Recurring_Canary" -Confirm:$false   # remove
```

`LastTaskResult = 0` means success. To switch from daily heartbeat to alert-only, add
`-AlertOnly` to the wrapper's `-Argument ... run_canary.ps1` line (re-register).
