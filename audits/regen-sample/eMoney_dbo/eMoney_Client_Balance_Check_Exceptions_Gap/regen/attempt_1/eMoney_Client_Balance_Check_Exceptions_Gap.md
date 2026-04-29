# eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap

> Daily balance decomposition alert table for the eToro Money fiat platform; currently 0 rows (empty when no exceptions detected). Populated by SP_eMoney_Client_Balance_Check_Exceptions_Gap at the end of each SP_eMoney_ClientBalance daily run. Contains a single summary row per business date only when the sum of CheckCalc (ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO) across all accounts is non-zero, indicating a positive/negative balance decomposition error.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | SP_eMoney_Client_Balance_Check_Exceptions_Gap (reads eMoneyClientBalance) |
| **Refresh** | Daily — called at end of SP_eMoney_ClientBalance via `EXEC SP_eMoney_Client_Balance_Check_Exceptions_Gap @d` |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | None |
| **UC Table Type** | Alert / data quality flag table |

---

## 1. Business Meaning

`eMoney_Client_Balance_Check_Exceptions_Gap` is a lightweight alert table used by the eToro Money finance team to detect balance decomposition errors in the daily `eMoneyClientBalance` load. Each day, after `SP_eMoney_ClientBalance` inserts the full account-level balance ledger, it calls `SP_eMoney_Client_Balance_Check_Exceptions_Gap` which:

1. Truncates this table (clearing prior alert state)
2. Computes `SUM(CheckCalc)` across all accounts for the business date
3. Inserts a row ONLY if the sum is non-zero

`CheckCalc` in `eMoneyClientBalance` is defined as `ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO`. This should always equal zero — it verifies that the positive and negative balance decomposition sums back to the total closing balance. A non-zero value indicates a data integrity issue in the positive/negative split logic.

The table is currently empty (0 rows), meaning the most recent daily run found no decomposition exceptions. By design, this table holds at most one row at any given time — it is a point-in-time flag, not a historical log.

---

## 2. Business Logic

### 2.1 TRUNCATE + INSERT Alert Pattern

**What**: The SP truncates the entire table on every run, then conditionally inserts.
**Columns Involved**: All (Date, Exceptions_Gap, UpdateDate)
**Rules**:
- Table is cleared on every execution regardless of outcome
- A row is inserted only when `SUM(CheckCalc) <> 0` for the business date
- If `SUM(CheckCalc) = 0` (no exceptions), the table remains empty after the run
- At most one row exists at any time (single business date aggregation)

### 2.2 CheckCalc Decomposition Validation

**What**: The `Exceptions_Gap` value aggregates the per-account CheckCalc consistency check.
**Columns Involved**: Exceptions_Gap
**Rules**:
- `CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO` (per account in eMoneyClientBalance)
- Expected value: 0 for each account, 0 in aggregate
- Non-zero aggregate means the positive/negative balance split does not reconcile with the total closing balance
- This is a secondary check distinct from `ClosingBalanceGAP` (which compares DWH-computed vs. Tribe back-office closing balance)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP is appropriate for a table that holds 0-1 rows. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Are there any current balance decomposition exceptions? | `SELECT * FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap` (empty = no exceptions) |
| What was the exception gap value? | Same query — check `Exceptions_Gap` column |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoneyClientBalance | `BalanceDateID = CAST(CONVERT(VARCHAR(8), [Date], 112) AS INT)` | Drill into per-account CheckCalc values for the exception date |

### 3.4 Gotchas

- **Empty table is normal**: 0 rows means no exceptions — not a data load failure
- **Not a historical log**: TRUNCATE on every run means only the latest run's result survives. Historical exception tracking requires external monitoring
- **UpdateDate is the SP input date, not GETDATE()**: Unlike eMoneyClientBalance.UpdateDate (which is GETDATE()), this table's UpdateDate is `@Date` — the business date parameter passed to the SP

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (passthrough or rename) |
| Tier 2 | Derived from SP code with full transform visibility |
| Tier 3 | Partial evidence — needs human review |
| Tier 4 | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for which the balance decomposition exception was detected. Converted from eMoneyClientBalance.BalanceDateID integer (YYYYMMDD) to date via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), DateID)) AS DATE)`. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap) |
| 2 | Exceptions_Gap | decimal(16,6) | YES | Aggregate balance decomposition error: `SUM(eMoneyClientBalance.CheckCalc)` across all accounts for the business date. CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO. Should be zero; non-zero indicates positive/negative balance split does not reconcile with total closing balance. Only populated when HAVING SUM(CheckCalc) <> 0. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap) |
| 3 | UpdateDate | date | NO | Business date parameter (@Date) passed to SP_eMoney_Client_Balance_Check_Exceptions_Gap. Represents the reconciliation date, not a load timestamp. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_Gap) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | INT→DATE conversion via CAST/CONVERT |
| Exceptions_Gap | eMoney_dbo.eMoneyClientBalance | CheckCalc | SUM() aggregation with HAVING <> 0 filter |
| UpdateDate | SP parameter | @Date | Direct assignment |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoneyClientBalance (source — daily balance ledger, ~1.19B rows)
  |
  |-- SP_eMoney_ClientBalance @d (daily load, calls alert SP at end)
  |     |
  |     v
  |   SP_eMoney_Client_Balance_Check_Exceptions_Gap @d
  |     Step 1: TRUNCATE TABLE eMoney_Client_Balance_Check_Exceptions_Gap
  |     Step 2: SELECT BalanceDateID, SUM(CheckCalc)
  |             FROM eMoneyClientBalance WHERE BalanceDateID=@DateID
  |             GROUP BY BalanceDateID HAVING SUM(CheckCalc)<>0
  |     Step 3: INSERT (only if non-zero exceptions found)
  |     v
  v
eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap (0-1 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date / Exceptions_Gap | eMoney_dbo.eMoneyClientBalance | Source data — BalanceDateID and CheckCalc columns |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers. This is a terminal alert/flag table.

---

## 7. Sample Queries

### 7.1 Check for Current Exceptions

```sql
-- Empty result = no exceptions; a row means decomposition error detected
SELECT *
FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap;
```

### 7.2 Drill Into Per-Account CheckCalc for an Exception Date

```sql
-- If the alert table has a row, find which accounts contribute to the gap
SELECT AccountId, CheckCalc, ClosingPositiveBalanceCalc, ClosingNegativeBalanceBO, ClosingBalanceBO
FROM eMoney_dbo.eMoneyClientBalance
WHERE BalanceDateID = CAST(CONVERT(VARCHAR(8), (SELECT [Date] FROM eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap), 112) AS INT)
  AND CheckCalc <> 0
ORDER BY ABS(CheckCalc) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (low-value alert table with clear SP-derived logic).

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: P1, P2, P3, P4, P5, P6, P7, P8, P9, P9B, P10A, P10B, P11*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 | Elements: 3/3, Logic: 8/10*
*Object: eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap | Type: Table | Production Source: SP_eMoney_Client_Balance_Check_Exceptions_Gap*
