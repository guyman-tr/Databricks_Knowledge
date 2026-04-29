# eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

> Data quality sentinel table: records dates where the eToro Money client balance reconciliation detected a closing-balance exception (CheckCalc ≠ 0). Currently 0 rows — the expected clean state. Populated by SP_eMoney_Client_Balance_Check_Exceptions_Gap (called as sub-step of SP_eMoney_ClientBalance) with TRUNCATE + INSERT per @Date run.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Data Quality Check Result) |
| **Production Source** | eMoney_dbo.eMoneyClientBalance.CheckCalc (ETL-computed) via SP_eMoney_Client_Balance_Check_Exceptions_Gap |
| **Refresh** | TRUNCATE + INSERT per @Date parameter; called at the end of SP_eMoney_ClientBalance execution |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 0 (sampled 2026-04-21 — no exceptions detected) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Gold layer |

---

## 1. Business Meaning

`eMoney_Client_Balance_Check_Exceptions_Gap` is a data quality monitoring table for the eToro Money (eTM) balance reconciliation process. Each row represents a **date on which a closing-balance exception was detected** — meaning the DWH-calculated closing balance did not reconcile with the back-office (BO) closing balance.

The reconciliation check is defined as:

```
CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO
```

When `SUM(CheckCalc)` for any `BalanceDateID` is non-zero, a row is inserted into this table recording the date and the aggregate exception gap. A completely empty table (current state) means all balance checks have passed — the DWH and BO balances are in agreement.

The table is populated as a sub-step of `SP_eMoney_ClientBalance` (the main daily eTM balance SP). It is not part of the `SP_eMoney_Execute_Group_One` pipeline and does not use the standard eTM ETL orchestration. It is called with an explicit `@Date` parameter.

**Operational significance**: An empty table is "green" — it means eTM balance integrity is clean. Any non-zero row in this table should trigger an investigation into balance discrepancies for that date.

---

## 2. Business Logic

### 2.1 Exception Detection Logic

**What**: A row is inserted only when the aggregated reconciliation check for a date is non-zero.

**Columns Involved**: `Date`, `Exceptions_Gap`

**Rules**:
- Source: `eMoneyClientBalance.CheckCalc` column aggregated by `BalanceDateID`
- CheckCalc formula: `ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO`
- Only `BalanceDateID` values where `SUM(CheckCalc) <> 0` produce rows in this table
- The table is TRUNCATED before each INSERT — it always reflects the most recent check result for the run date
- If no exceptions: table is empty after the run

### 2.2 TRUNCATE+INSERT Pattern

**What**: The table is cleared before each run; it is NOT a cumulative log.

**Columns Involved**: All 3 columns

**Rules**:
- `TRUNCATE TABLE` runs before `INSERT` — prior rows are discarded
- The SP is parameterized: `EXEC SP_eMoney_Client_Balance_Check_Exceptions_Gap @Date`
- The `@Date` parameter is the check date; `UpdateDate` reflects when the SP was called
- Since the check date and run date may differ, `Date` and `UpdateDate` can be different

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP is appropriate for this tiny table. In the expected state (0 rows) there is no performance concern. If exceptions are found, rows are at most one per date per run.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Are there any active exceptions? | `SELECT * FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap` — 0 rows = clean |
| What was the exception gap on a specific date? | `SELECT * FROM ... WHERE [Date] = '2024-06-04'` |
| What was the most recent check date? | `SELECT MAX(UpdateDate) FROM ...` |

### 3.3 Common JOINs

This table is not typically joined to other tables. It is a standalone data quality signal.

### 3.4 Gotchas

- **Empty table is GREEN**: 0 rows means all checks passed, not that the table was never populated.
- **TRUNCATE semantics**: Each SP run replaces the previous contents. Historical exceptions are not retained.
- **Date vs UpdateDate**: `Date` is the balance date being checked; `UpdateDate` is the SP execution date. They may differ if the SP is run retroactively.
- **Table currently 0 rows**: Sampled 2026-04-21; has been empty on all recent SP runs.
- **No automated schedule**: This SP is not in Execute_Group_One; it must be called explicitly or is triggered by SP_eMoney_ClientBalance.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Description written from ETL SP code analysis |
| Tier 3 | Description inferred from column name and context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The balance date (BalanceDateID converted to date) for which a reconciliation exception was detected. Derived via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` from eMoneyClientBalance. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap) |
| 2 | Exceptions_Gap | decimal(16,6) | YES | Aggregate reconciliation gap for the check date. Computed as `SUM(CheckCalc)` from eMoneyClientBalance, where CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO − ClosingBalanceBO. Non-zero value indicates a closing-balance discrepancy requiring investigation. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap via eMoneyClientBalance) |
| 3 | UpdateDate | date | NO | The @Date parameter passed to SP_eMoney_Client_Balance_Check_Exceptions_Gap when this check was run. Represents the execution date of the SP, which may differ from Date if the check is run retroactively. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column | Production Source | Source Column | Transform |
|-----------|-------------------|--------------|-----------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE) |
| Exceptions_Gap | eMoney_dbo.eMoneyClientBalance | CheckCalc | SUM GROUP BY BalanceDateID HAVING SUM <> 0 |
| UpdateDate | SP parameter | @Date | Passthrough |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoneyClientBalance
  (CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO)
  |-- SP_eMoney_Client_Balance_Check_Exceptions_Gap @Date ---|
  |   (TRUNCATE + INSERT WHERE SUM(CheckCalc) <> 0)          |
  v
eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap
  (0 rows when clean; N rows when exceptions detected)

Orchestration:
  SP_eMoney_ClientBalance (daily balance run)
    -> EXEC SP_eMoney_Client_Balance_Check_Exceptions_Gap @d
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date | eMoney_dbo.eMoneyClientBalance.BalanceDateID | Source date key for balance check |
| Exceptions_Gap | eMoney_dbo.eMoneyClientBalance.CheckCalc | Source computed column (aggregated) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.SP_eMoney_ClientBalance | — | Orchestrator — calls the writer SP at end of daily run |

---

## 7. Sample Queries

### 7.1 Check if any exceptions are active

```sql
SELECT [Date], Exceptions_Gap, UpdateDate
FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap
ORDER BY [Date] DESC;
-- 0 rows = all checks passed (expected state)
```

### 7.2 Confirm last check run date

```sql
SELECT MAX(UpdateDate) AS LastCheckDate,
       COUNT(*) AS ExceptionCount
FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: P1-P10A/14 (P3 empty table, P10 skipped)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3*
*Object: eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap | Type: Table | Production Source: eMoneyClientBalance.CheckCalc via SP_eMoney_Client_Balance_Check_Exceptions_Gap*
