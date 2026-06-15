# SP_Crypto_NOP source-drift audit

Polls every upstream source feeding `BI_DB_dbo.SP_Crypto_NOP` twice a day
(04:00 and 09:00 local time) and produces a markdown diff report so we can
*prove* whether re-running the SP at 09:00 would have read different
upstream data than the 04:00 run.

## Files

| File | What it does |
|---|---|
| `poll_sources.py`     | Snapshot fingerprints (row count + signal sums + freshness) for the 24 sources used by SP_Crypto_NOP. Writes `snapshots/<YYYY-MM-DD>_<tag>.csv`. |
| `make_report.py`      | Diffs the earliest and latest snapshot for a given target_date. Writes `reports/<YYYY-MM-DD>.md` and copies to `~\Downloads\sp_crypto_nop_source_audit_<date>.md`. |
| `poll_and_report.ps1` | Wrapper called by the scheduled task: poll, then attempt report (no-op if only one snapshot exists yet). Writes a per-day log to `logs/<date>.log`. |
| `install_schedule.ps1`| Registers two Windows Scheduled Tasks: `CryptoNopAuditPoll04` (04:00) and `CryptoNopAuditPoll09` (09:00). |

## Daily flow

1. **04:00** → `CryptoNopAuditPoll04` runs, writes `snapshots/<yesterday>_0400.csv`. `make_report.py` runs but exits cleanly (only one snapshot for the date so far).
2. **09:00** → `CryptoNopAuditPoll09` runs, writes `snapshots/<yesterday>_0900.csv`. `make_report.py` runs and produces the diff report for yesterday.
3. Report lands at:
   - `tools/sp_crypto_nop_audit/reports/<yesterday>.md` (in-repo)
   - `C:\Users\guyman\Downloads\sp_crypto_nop_source_audit_<yesterday>.md` (Downloads copy)

`@Date` defaults to **yesterday (local)** — matching the SP's typical
`EXEC SP_Crypto_NOP @Date = yesterday` schedule.

## Manual / ad-hoc

```powershell
# Poll right now for yesterday
python tools\sp_crypto_nop_audit\poll_sources.py --tag adhoc

# Poll for a specific date
python tools\sp_crypto_nop_audit\poll_sources.py --target-date 2026-05-26 --tag adhoc

# Regenerate the report from existing snapshots
python tools\sp_crypto_nop_audit\make_report.py --target-date 2026-05-26
```

## Sources audited (24 total)

Mirrors every join in `BI_DB_dbo.SP_Crypto_NOP`:

- **Fact / base**: `BI_DB_PositionPnL` (full + crypto-only), `Dim_Position` (intersected with crypto PnL), `Fact_CurrencyPriceWithSplit` (full + crypto-only), `Fact_SnapshotCustomer`, `Dim_Customer`, `V_GermanBaFin`, `BI_DB_Client_Balance_CID_Level_New`
- **Apex staking**: `External_USABroker_Apex_UserProgramEnrolment` ∪ `External_USABroker_History_UserProgramEnrolment` filtered to opt-out and opt-in-ETH
- **Dims**: `Dim_Range`, `Dim_Regulation`, `Dim_Label`, `Dim_MifidCategorization`, `Dim_AccountType`, `Dim_PlayerLevel`, `Dim_PlayerStatus`, `Dim_Country`, `Dim_Instrument`, `External_TanganyStatus_dict`
- **Targets** (the SP's INSERT outputs, for completeness): `BI_DB_Crypto_NOP`, `BI_DB_Crypto_NOP_CID`
- **Meta**: `SP_Crypto_NOP_run_history` from `DataSolutionsProcessesStatus`

Each query is scoped to `@DateID = <target_date>` where applicable. Total
poll time on PROD ~75 seconds (most spent on the Apex enrolment UNION).

## Connection

Uses `synapse_connect.py` against PROD:
- server: `prod-synapse-dataplatform-we.sql.azuresynapse.net`
- database: `sql_dp_prod_we`
- auth: SQL login from `~/.cursor/synapse-credentials.env`
  (`SYNAPSE_SQL_USER` + `SYNAPSE_SQL_PASS`, mapped to `SYNAPSE_SQL_PASSWORD`)

## Uninstall

```powershell
powershell -File tools\sp_crypto_nop_audit\install_schedule.ps1 -Uninstall
```
