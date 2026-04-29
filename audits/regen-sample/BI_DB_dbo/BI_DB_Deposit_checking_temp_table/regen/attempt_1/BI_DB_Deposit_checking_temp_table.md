# BI_DB_dbo.BI_DB_Deposit_checking_temp_table

> Single-row ETL quality-check table: holds the output of `SP_Client_Balance_Check_Opening_Balance`, comparing daily deposit totals from `Fact_CustomerAction` (FCA source) against the Client Balance aggregate (CB source). Written by `SP_Client_Balance_New` as part of the daily Client Balance run.

| Property | Value |
|---|---|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (ETL check / staging) |
| **Row Count** | 1 (DELETE + INSERT on every run — always the latest check result) |
| **Production Source** | Derived — `SP_Client_Balance_Check_Opening_Balance` writing from `DWH_dbo.Fact_CustomerAction` and `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` |
| **Refresh** | Daily (called from `SP_Client_Balance_New`) |
| **Last UpdateDate (sampled 2026-04-27)** | 2026-04-27 03:33:55 |
| | |
| **Synapse Distribution** | HASH(UpdateDate) |
| **Synapse Index** | HEAP |

---

## 1. Business Meaning

`BI_DB_Deposit_checking_temp_table` is a **single-row ETL quality gate** written by `SP_Client_Balance_Check_Opening_Balance` during the daily `SP_Client_Balance_New` run. It captures the deposit reconciliation check for the most recent processed date: total deposits from `Fact_CustomerAction` (`Deposits_FCA`) versus net deposits from the Client Balance aggregate (`Deposits_CB`), their difference (`Balance_diff_deposit`), and an error message when they diverge. The table always holds exactly 1 row (the SP issues `DELETE` before each `INSERT`). As of 2026-04-27, the balance difference was 0.000000, indicating a clean reconciliation.

---

## 2. Business Logic

### 2.1 Deposit reconciliation check

`Deposits_FCA` = `SUM(ISNULL(Amount,0))` from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 7` for the check date. `Deposits_CB` = `SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))` from `BI_DB_Client_Balance_Aggregate_Level_New` for the same date. `Balance_diff_deposit = Deposits_FCA - Deposits_CB`. If the difference is non-zero, `Error_Message` is populated with a diagnostic string and a non-fatal `PRINT` is issued; when zero, `Error_Message` is NULL/empty.

---

## 3. Query Advisory

### 3.1 Distribution & Index

HEAP + HASH(UpdateDate) — effective for single-row access; no range scan benefit. Always read the single row directly with no filter or `TOP 1 ORDER BY UpdateDate DESC`.

### 3.2 Common Query Patterns

| Question | Query |
|---|---|
| Latest check result | `SELECT * FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |
| Is there a deposit discrepancy? | `SELECT Balance_diff_deposit, Error_Message FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |
| When was the last run? | `SELECT UpdateDate FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | (none — source, not a join target) | Review deposit components |
| DWH_dbo.Fact_CustomerAction | (none — source, not a join target) | Review raw FCA deposit amounts |

### 3.4 Gotchas

- Table always holds exactly **1 row** — the DELETE before INSERT makes it a volatile status register, not a history.
- `Error_Message` is an empty string (not NULL) when the check passes, per SP observed behavior.
- `UpdateDate` is `GETDATE()` (local server time), not UTC — do not compare directly to UTC-timestamped columns in other tables.
- HASH(UpdateDate) distribution on a 1-row table is meaningless for performance; it is an artifact of the Synapse HEAP CTAS pattern used when the table was originally created.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | Deposits_FCA | decimal(26,6) | YES | Total raw deposit amount for the check date: `SUM(ISNULL(Amount,0))` from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 7`. (Tier 2 — SP_Client_Balance_Check_Opening_Balance, DWH_dbo.Fact_CustomerAction) |
| 2 | Deposits_CB | decimal(26,6) | YES | Net deposit amount per Client Balance aggregate: `SUM(Deposits) - SUM(InternalTransferDeposits)` from `BI_DB_Client_Balance_Aggregate_Level_New`. (Tier 2 — SP_Client_Balance_Check_Opening_Balance, BI_DB_Client_Balance_Aggregate_Level_New) |
| 3 | Balance_diff_deposit | decimal(26,6) | YES | Reconciliation difference: `Deposits_FCA - Deposits_CB`; 0.000000 = clean run. (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |
| 4 | Error_Message | varchar(max) | YES | ETL-generated diagnostic string when `Balance_diff_deposit <> 0`; empty string when check passes. (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |
| 5 | UpdateDate | datetime | NOT NULL | Server timestamp (`GETDATE()`) at INSERT time; distribution key. (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |

---

## 5. ETL & Relationships

### 5.1 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=7, DateID=@dateID)
  → SUM(Amount)
    ↓
BI_DB_Client_Balance_Aggregate_Level_New (DateID=@dateID)
  → SUM(Deposits) - SUM(InternalTransferDeposits)
    ↓
SP_Client_Balance_Check_Opening_Balance
  → DELETE BI_DB_Deposit_checking_temp_table
  → INSERT BI_DB_Deposit_checking_temp_table (1 row: FCA total, CB total, diff, error msg, timestamp)
```

Called by `SP_Client_Balance_New` as a post-load quality check step (daily).

### 5.2 References To

| Target Object | Join Column | Purpose |
|---|---|---|
| DWH_dbo.Fact_CustomerAction | ActionTypeID=7, DateID | Source of FCA deposit total |
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | DateID | Source of CB deposit total |

### 5.3 Referenced By

| Source Object | Type | Usage |
|---|---|---|
| BI_DB_dbo.SP_Client_Balance_Check_Opening_Balance | Stored Procedure | Writes to this table; also SELECTs from it at end of run |
| BI_DB_dbo.SP_Client_Balance_New | Stored Procedure (caller) | Triggers SP_Client_Balance_Check_Opening_Balance as a check step |

---

## 6. Relationships

### 6.1 Source Upstream

| Object | Schema | Columns Used |
|---|---|---|
| Fact_CustomerAction | DWH_dbo | Amount (ActionTypeID=7) |
| BI_DB_Client_Balance_Aggregate_Level_New | BI_DB_dbo | Deposits, InternalTransferDeposits |

---

## 7. Sample Queries

**Check today's deposit reconciliation result.**
```sql
SELECT Deposits_FCA, Deposits_CB, Balance_diff_deposit, Error_Message, UpdateDate
FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table;
```

**Manually reproduce the FCA deposit total for comparison against CB.**
```sql
SELECT SUM(ISNULL(Amount, 0)) AS Deposits_FCA
FROM DWH_dbo.Fact_CustomerAction
WHERE ActionTypeID = 7
  AND DateID = CAST(FORMAT(DATEADD(DAY,-1,CAST(GETDATE() AS DATE)),'yyyyMMdd') AS INT);
```

---

## 8. Atlassian Knowledge

- No Jira issues found in bundle referencing this table directly.
- Table was created as a persistent replacement for a `##` global temp table in `SP_Client_Balance_Check_Opening_Balance` (commented-out CTAS visible in SP source).
- Non-zero `Balance_diff_deposit` triggers a `PRINT` (not `RAISERROR`) — the discrepancy is logged but does not fail the SP run; monitor `Error_Message` for silent failures.

---

| Property | Value |
|---|---|
| **Production Source** | Derived — `SP_Client_Balance_Check_Opening_Balance` via `SP_Client_Balance_New` |
| **Upstream Objects** | `DWH_dbo.Fact_CustomerAction`, `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` |
