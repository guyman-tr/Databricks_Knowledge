# BI_DB_dbo.BI_DB_Deposit_checking_temp_table

> Single-row ETL quality-check table: holds the output of `SP_Client_Balance_Check_Opening_Balance`, comparing daily deposit totals from `Fact_CustomerAction` (FCA source) against the Client Balance aggregate (CB source). Written during the daily `SP_Client_Balance_New` run; last sampled 2026-04-27, diff=0.000000 (clean reconciliation).

| Property | Value |
|---|---|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (ETL check / staging) |
| **Row Count** | 1 (DELETE + INSERT on every successful run) |
| **Production Source** | Derived — `SP_Client_Balance_Check_Opening_Balance` writing from `DWH_dbo.Fact_CustomerAction` and `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` |
| **Refresh** | Daily (called from `SP_Client_Balance_New`) |
| **Last UpdateDate (sampled 2026-04-27)** | 2026-04-27 03:33:55 |
| | |
| **Synapse Distribution** | HASH(UpdateDate) |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | Not yet provisioned |

---

## 1. Business Meaning

`BI_DB_Deposit_checking_temp_table` is a **single-row ETL quality gate** written by `SP_Client_Balance_Check_Opening_Balance` during the daily `SP_Client_Balance_New` run. It captures the deposit reconciliation check for the most recent processed date: total deposits from `Fact_CustomerAction` (`Deposits_FCA`) versus net deposits from the Client Balance aggregate (`Deposits_CB`), their difference (`Balance_diff_deposit`), and an error message when they diverge. The SP issues `DELETE` before each `INSERT`; however, if the prior opening-balance check fires `RAISERROR(severity 18)`, the batch aborts before the DELETE/INSERT and the table retains stale data from the previous run. As of 2026-04-27, `Balance_diff_deposit` = 0.000000 and `Error_Message` = NULL (clean reconciliation).

---

## 2. Business Logic

### 2.1 Deposit reconciliation check

`Deposits_FCA` = `SUM(ISNULL(Amount,0))` from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 7` for the check date. `Deposits_CB` = `SUM(ISNULL(Deposits,0)) - SUM(ISNULL(InternalTransferDeposits,0))` from `BI_DB_Client_Balance_Aggregate_Level_New` for the same date. `Balance_diff_deposit = Deposits_FCA - Deposits_CB`. If the difference is non-zero, `Error_Message` is set to a diagnostic string and a non-fatal `PRINT` is issued; when zero, `Error_Message` is NULL (the variable `@v_error_message_deposit` is declared but never assigned in the success branch — `CAST(NULL AS VARCHAR(MAX))` inserts NULL).

---

## 3. Query Advisory

### 3.1 Distribution & Index

HEAP + HASH(UpdateDate) — effective for single-row access; no range scan benefit. Always read with no filter or `TOP 1 ORDER BY UpdateDate DESC`.

### 3.2 Common Query Patterns

| Question | Query |
|---|---|
| Latest check result | `SELECT * FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |
| Is there a deposit discrepancy? | `SELECT Balance_diff_deposit, Error_Message FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |
| When was the last run? | `SELECT UpdateDate FROM BI_DB_dbo.BI_DB_Deposit_checking_temp_table` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | (none — source table) | Review deposit components |
| DWH_dbo.Fact_CustomerAction | (none — source table) | Review raw FCA deposit amounts |

### 3.4 Gotchas

- Table normally holds exactly **1 row**, but `UpdateDate` can be stale: if the opening-balance check fires `RAISERROR(severity 18)`, the SP aborts before the `DELETE/INSERT` executes, leaving the prior run's values in the table.
- `Error_Message` is **NULL** (not empty string) when the check passes — `@v_error_message_deposit` is declared but never SET in the success branch; `CAST(NULL AS VARCHAR(MAX))` inserts NULL.
- `UpdateDate` is `GETDATE()` (local server time), not UTC — do not compare directly to UTC-timestamped columns in other tables.
- HASH(UpdateDate) distribution on a 1-row HEAP table is meaningless for performance; it is a DDL artifact from the original CTAS pattern (commented out in SP source).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|---|---|---|
| ★★★★ | Tier 1 | Upstream wiki verbatim (passthrough or rename) |
| ★★★ | Tier 2 | Derived from SP code (`SP_Client_Balance_Check_Opening_Balance`) |
| ★★ | Tier 3 | ETL-assigned constant (GETDATE, NULL placeholder) |
| ★ | Tier 4 | Inferred from column name only — `[UNVERIFIED]` |

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | Deposits_FCA | decimal(26,6) | YES | Total raw deposit amount for the check date: `SUM(ISNULL(Amount,0))` from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID = 7`. (Tier 2 — SP_Client_Balance_Check_Opening_Balance, DWH_dbo.Fact_CustomerAction) |
| 2 | Deposits_CB | decimal(26,6) | YES | Net deposit amount per Client Balance aggregate: `SUM(Deposits) - SUM(InternalTransferDeposits)` from `BI_DB_Client_Balance_Aggregate_Level_New`. (Tier 2 — SP_Client_Balance_Check_Opening_Balance, BI_DB_Client_Balance_Aggregate_Level_New) |
| 3 | Balance_diff_deposit | decimal(26,6) | YES | Reconciliation difference: `Deposits_FCA - Deposits_CB`; 0.000000 = clean run. (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |
| 4 | Error_Message | varchar(max) | YES | ETL-generated diagnostic string when `Balance_diff_deposit <> 0`; NULL when check passes (variable never SET in success branch). (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |
| 5 | UpdateDate | datetime | NOT NULL | Server timestamp (`GETDATE()`) at INSERT time; distribution key; can be stale if RAISERROR aborts batch before DELETE/INSERT. (Tier 2 — SP_Client_Balance_Check_Opening_Balance) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Deposits_FCA | DWH_dbo.Fact_CustomerAction | Amount | `SUM(ISNULL(Amount,0)) WHERE ActionTypeID=7 AND DateID=@dateID` |
| Deposits_CB | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Deposits, InternalTransferDeposits | `SUM(Deposits)-SUM(InternalTransferDeposits) WHERE DateID=@dateID` |
| Balance_diff_deposit | Computed | @v_Deposits_FCA, @v_Deposits_CB | `@v_Deposits_FCA - @v_Deposits_CB` |
| Error_Message | SP_Client_Balance_Check_Opening_Balance | — | Constructed diagnostic string if diff≠0; NULL on clean run |
| UpdateDate | SP_Client_Balance_Check_Opening_Balance | — | `GETDATE()` at INSERT time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=7, DateID=@dateID)
  → SUM(Amount) → @v_Deposits_FCA
    ↓
BI_DB_Client_Balance_Aggregate_Level_New (DateID=@dateID)
  → SUM(Deposits) - SUM(InternalTransferDeposits) → @v_Deposits_CB
    ↓
SP_Client_Balance_Check_Opening_Balance
  [IF opening balance mismatch → RAISERROR(severity 18) → ABORT (stale data remains)]
  [IF deposit mismatch → PRINT (non-fatal) → continue]
  → DELETE BI_DB_Deposit_checking_temp_table
  → INSERT BI_DB_Deposit_checking_temp_table (1 row: FCA total, CB total, diff, error msg, timestamp)
```

Called by `SP_Client_Balance_New` as a post-load quality check step (daily).

### 5.3 References To

| Target Object | Join Column | Purpose |
|---|---|---|
| DWH_dbo.Fact_CustomerAction | ActionTypeID=7, DateID | Source of FCA deposit total |
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | DateID | Source of CB deposit total |

### 5.4 Referenced By

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
- `Balance_diff_deposit <> 0` triggers a `PRINT` (not `RAISERROR`) — the deposit discrepancy is logged but does not fail the SP run; monitor `Error_Message` for silent deposit failures.
- The opening-balance check is separate and uses `RAISERROR(severity 18)`, which CAN abort the batch — leaving this table with stale deposit-check data from the prior run.

---

*Generated: 2026-04-28 | Quality: 8.2/10 | Phases: P1-P11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 | Elements: 5/5*
*Object: BI_DB_dbo.BI_DB_Deposit_checking_temp_table | Type: ETL check / staging | Production Source: SP_Client_Balance_Check_Opening_Balance via SP_Client_Balance_New*
