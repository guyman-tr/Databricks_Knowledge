# eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

> Data quality sentinel table: records dates where the eToro Money opening balance reconciliation detected a discrepancy between the currency-balance system and back-office (BO) opening balances. Currently 0 rows — the expected clean state. Populated by SP_eMoney_Client_Balance_Check_Opening_Balance (called as sub-step of SP_eMoney_ClientBalance) with TRUNCATE + INSERT per @Date run.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Data Quality Check Result) |
| **Production Source** | eMoney_dbo.eMoneyClientBalance.OpeningBalanceGAP (ETL-computed) via SP_eMoney_Client_Balance_Check_Opening_Balance |
| **Refresh** | TRUNCATE + INSERT per @Date parameter; called at the end of SP_eMoney_ClientBalance execution |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 0 (sampled 2026-04-21 — no opening balance discrepancies detected) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Gold layer |

---

## 1. Business Meaning

`eMoney_Client_Balance_Check_Opening_Balance` is a data quality monitoring table for the eToro Money (eTM) opening balance reconciliation process. Each row represents a **date on which an opening balance discrepancy was detected** — meaning the DWH-computed opening balance (derived from the currency balance system, `OpeningBalanceByCB`) differed from the back-office recorded opening balance (`OpeningBalance`).

The reconciliation gap is defined as:

```
OpeningBalanceGAP = CASE WHEN oc.AccountId IS NULL THEN 0
                         ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END
```

When `SUM(OpeningBalanceGAP)` for any `BalanceDateID` is non-zero, a row is inserted recording the date and the aggregate gap. A completely empty table (current state) means opening balance integrity checks are passing. The SP is a companion to `eMoney_Client_Balance_Check_Exceptions_Gap` (both called from `SP_eMoney_ClientBalance`).

**Note on column naming**: The column `Openning_Balance_Gap` contains a typo (double 'n' in "Openning") — this is the DDL definition and SP column name as deployed. Do not correct it in queries.

---

## 2. Business Logic

### 2.1 Opening Balance Gap Logic

**What**: A row is inserted only when the aggregated opening balance discrepancy for a date is non-zero.

**Columns Involved**: `Date`, `Openning_Balance_Gap`

**Rules**:
- Source: `eMoneyClientBalance.OpeningBalanceGAP` column aggregated by `BalanceDateID`
- OpeningBalanceGAP formula: `OpeningBalanceByCB − OpeningBalance` per account (0 when no matching currency-balance record exists for the account)
- Only `BalanceDateID` values where `SUM(OpeningBalanceGAP) <> 0` produce rows in this table
- The table is TRUNCATED before each INSERT — it always reflects the most recent check result for the run date

### 2.2 Comparison with eMoney_Client_Balance_Check_Exceptions_Gap

**What**: These two tables are companion check tables, both written at the end of each SP_eMoney_ClientBalance run.

**Rules**:
- `eMoney_Client_Balance_Check_Exceptions_Gap` checks CLOSING balance reconciliation (CheckCalc)
- `eMoney_Client_Balance_Check_Opening_Balance` checks OPENING balance reconciliation (OpeningBalanceGAP)
- Both use the same execution pattern: TRUNCATE + INSERT per @Date, HAVING ≠ 0 filter
- Both are currently empty (all checks passing)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP is appropriate for this tiny table. 0 rows expected when balance checks are clean.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Are there any opening balance gaps? | `SELECT * FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance` — 0 rows = clean |
| What was the gap magnitude on a date? | `SELECT * FROM ... WHERE [Date] = '2024-06-04'` |
| Compare with closing balance exceptions | Join or UNION with `eMoney_Client_Balance_Check_Exceptions_Gap` on `[Date]` |

### 3.3 Common JOINs

This table is not typically joined to other tables. It is a standalone data quality signal.

### 3.4 Gotchas

- **Empty table is GREEN**: 0 rows means all opening balance checks passed.
- **TRUNCATE semantics**: Each SP run replaces the previous contents. No cumulative history.
- **Typo in column name**: `Openning_Balance_Gap` — double 'n'. Hardcoded in DDL; must be used as-is in queries.
- **Date vs UpdateDate**: `Date` is the balance date being checked; `UpdateDate` is the SP execution date. They may differ if run retroactively.
- **Companion table**: See also `eMoney_Client_Balance_Check_Exceptions_Gap` for closing-balance checks.

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
| 1 | Date | date | YES | The balance date (BalanceDateID converted to date) for which an opening balance discrepancy was detected. Derived via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` from eMoneyClientBalance. (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance) |
| 2 | Openning_Balance_Gap | decimal(16,6) | YES | Aggregate opening balance gap for the check date. Computed as `SUM(OpeningBalanceGAP)` from eMoneyClientBalance, where OpeningBalanceGAP = OpeningBalanceByCB − OpeningBalance per account. Non-zero value indicates opening balance mismatch between the currency-balance system and BO records. Note: column name intentionally preserves the "Openning" typo from the DDL. (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance via eMoneyClientBalance) |
| 3 | UpdateDate | date | NO | The @Date parameter passed to SP_eMoney_Client_Balance_Check_Opening_Balance when this check was run. Represents the SP execution date, which may differ from Date if the check is run retroactively. (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column | Production Source | Source Column | Transform |
|-----------|-------------------|--------------|-----------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE) |
| Openning_Balance_Gap | eMoney_dbo.eMoneyClientBalance | OpeningBalanceGAP | SUM GROUP BY BalanceDateID HAVING SUM <> 0 |
| UpdateDate | SP parameter | @Date | Passthrough |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoneyClientBalance
  (OpeningBalanceGAP = OpeningBalanceByCB − OpeningBalance per account)
  |-- SP_eMoney_Client_Balance_Check_Opening_Balance @Date ---|
  |   (TRUNCATE + INSERT WHERE SUM(OpeningBalanceGAP) <> 0)   |
  v
eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
  (0 rows when clean; N rows when discrepancies detected)

Orchestration:
  SP_eMoney_ClientBalance (daily balance run)
    -> EXEC SP_eMoney_Client_Balance_Check_Opening_Balance @d
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date | eMoney_dbo.eMoneyClientBalance.BalanceDateID | Source date key for balance check |
| Openning_Balance_Gap | eMoney_dbo.eMoneyClientBalance.OpeningBalanceGAP | Source computed column (aggregated) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.SP_eMoney_ClientBalance | — | Orchestrator — calls the writer SP at end of daily run |

---

## 7. Sample Queries

### 7.1 Check if any opening balance gaps are active

```sql
SELECT [Date], Openning_Balance_Gap, UpdateDate
FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
ORDER BY [Date] DESC;
-- 0 rows = all checks passed (expected state)
```

### 7.2 Compare both balance check tables

```sql
-- Overview of both check tables together
SELECT 'ExceptionsGap' AS CheckType, [Date], UpdateDate
FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap
UNION ALL
SELECT 'OpeningBalanceGap' AS CheckType, [Date], UpdateDate
FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
ORDER BY [Date] DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: P1-P10A/14 (P3 empty table, P10 skipped)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3*
*Object: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance | Type: Table | Production Source: eMoneyClientBalance.OpeningBalanceGAP via SP_eMoney_Client_Balance_Check_Opening_Balance*
