# eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

> Alert/exception table for eToro Money daily balance reconciliation; stores the aggregate opening balance gap across all Tribe fiat accounts for any business date where the sum of per-account OpeningBalanceGAP in eMoneyClientBalance is non-zero. Populated by SP_eMoney_Client_Balance_Check_Opening_Balance (called at the end of SP_eMoney_ClientBalance daily ETL). Currently 0 rows (reconciliation is clean); non-empty only when a systemic opening balance mismatch is detected.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | SP_eMoney_Client_Balance_Check_Opening_Balance (aggregates from eMoneyClientBalance) |
| **Refresh** | Daily — TRUNCATE + conditional INSERT at the tail of SP_eMoney_ClientBalance |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | None |
| **UC Table Type** | Alert/exception table |

---

## 1. Business Meaning

`eMoney_Client_Balance_Check_Opening_Balance` is a lightweight alert table used by the eToro Money finance reconciliation pipeline. Each day, after `SP_eMoney_ClientBalance` computes the full account-level balance ledger in `eMoneyClientBalance`, it calls `SP_eMoney_Client_Balance_Check_Opening_Balance @d` as a post-load validation step.

The SP aggregates `OpeningBalanceGAP` (the difference between the prior day's recorded closing balance and today's opening balance from the Tribe snapshot file) across all accounts for the business date. If the total gap is non-zero, a single summary row is inserted. If the gap is zero (expected steady state), the table remains empty after the TRUNCATE.

The table currently holds 0 rows, indicating that reconciliation is clean. A non-empty table signals a systemic opening balance mismatch requiring investigation by the eToro Money finance team.

Author: Adi Meidan. The SP was originally part of a broader alert framework alongside `SP_eMoney_Client_Balance_Check_Exceptions_Gap`.

---

## 2. Business Logic

### 2.1 TRUNCATE + Conditional INSERT Pattern

**What**: The table is fully replaced on every SP execution, not incrementally loaded.
**Columns Involved**: All 3 columns.
**Rules**:
- `TRUNCATE TABLE` is called unconditionally at the start of every SP run
- The `#final` temp table is built with `HAVING SUM(OpeningBalanceGAP) <> 0` — rows only exist when the aggregate gap is non-zero
- If the HAVING clause filters out all rows, the INSERT produces 0 rows and the table stays empty
- Only one row per business date is possible (GROUP BY BalanceDateID with a single @DateID filter)

### 2.2 Opening Balance Gap Semantics

**What**: The gap measures the discrepancy between the prior day's closing balance in `eMoneyClientBalance` and the current day's opening balance from the Tribe snapshot file.
**Columns Involved**: `Openning_Balance_Gap`
**Rules**:
- Per-account `OpeningBalanceGAP` in `eMoneyClientBalance` is computed as: `ISNULL(prior_day_ClosingBalanceBO - current_OpeningBalance, 0)` (via `#opbalanceclientbalance`)
- This table stores the SUM across all accounts — a portfolio-level signal
- A non-zero value indicates either a Tribe file issue, a late-arriving file, or a first-fill edge case where the prior day's eMoneyClientBalance row does not exist

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — appropriate for a small alert table that is always fully replaced. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is there a current opening balance gap? | `SELECT * FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance` — if 0 rows, reconciliation is clean |
| When was the last gap detected? | Check historical monitoring systems — this table only holds the latest run's result (TRUNCATE pattern) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoneyClientBalance | BalanceDateID = CAST(CONVERT(VARCHAR(8), Date, 112) AS INT) | Drill down to per-account OpeningBalanceGAP values for the flagged date |

### 3.4 Gotchas

- **Typo in column name**: `Openning_Balance_Gap` has a double 'n' — this is the production column name, not a documentation error
- **TRUNCATE semantics**: The table only reflects the LAST execution. If the SP is re-run for a different date, the previous result is lost
- **Empty = healthy**: An empty table is the expected state. Non-empty indicates an alert condition
- **Single-row maximum**: The GROUP BY + single @DateID means at most one row exists at any time

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (passthrough or rename) |
| Tier 2 | Derived from SP code / ETL logic with full traceability |
| Tier 3 | Partial evidence — needs human review |
| Tier 4 | Inferred from name only — lowest confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for which the opening balance gap was detected. Derived from eMoneyClientBalance.BalanceDateID by converting the integer YYYYMMDD back to a date type via CAST(CONVERT(DATETIME, CONVERT(char(8), DateID)) AS DATE). (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance) |
| 2 | Openning_Balance_Gap | decimal(16,6) | YES | Aggregate opening balance gap across all Tribe fiat accounts for the business date. Computed as SUM(eMoneyClientBalance.OpeningBalanceGAP) WHERE BalanceDateID = @DateID, filtered by HAVING SUM <> 0. A non-zero value signals a systemic mismatch between the prior day's closing balance and the current day's Tribe snapshot opening balance. (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance) |
| 3 | UpdateDate | date | NO | The business date passed as the @Date input parameter to SP_eMoney_Client_Balance_Check_Opening_Balance. Set to the same value as the @d parameter from the calling SP_eMoney_ClientBalance daily run. (Tier 2 — SP_eMoney_Client_Balance_Check_Opening_Balance) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Date | eMoney_dbo.eMoneyClientBalance | BalanceDateID | INT YYYYMMDD → date conversion |
| Openning_Balance_Gap | eMoney_dbo.eMoneyClientBalance | OpeningBalanceGAP | SUM() GROUP BY BalanceDateID, HAVING <> 0 |
| UpdateDate | SP parameter | @Date | Direct assignment from SP input parameter |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoneyClientBalance (daily balance ledger, ~1.19B rows)
  |-- SP_eMoney_ClientBalance @d (daily ETL, populates eMoneyClientBalance)
  |   then calls:
  |-- SP_eMoney_Client_Balance_Check_Opening_Balance @d
  |   (TRUNCATE + conditional INSERT)
  v
eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance (alert table, 0-1 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date / Openning_Balance_Gap | eMoney_dbo.eMoneyClientBalance | Sole data source — aggregates OpeningBalanceGAP by BalanceDateID |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers. This table serves as an alert signal — likely monitored by external dashboards or alerting systems rather than consumed by other Synapse objects.

---

## 7. Sample Queries

### 7.1 Check for Current Opening Balance Gap Alert

```sql
SELECT *
FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance;
-- Empty result = reconciliation is clean
-- Any rows = opening balance mismatch detected
```

### 7.2 Drill Down to Per-Account Gaps When Alert is Active

```sql
SELECT mcb.AccountId,
       mcb.HolderId,
       mcb.Entity,
       mcb.OpeningBalanceGAP,
       mcb.OpeningBalance,
       mcb.ClosingBalanceBO
FROM eMoney_dbo.eMoneyClientBalance mcb
WHERE mcb.BalanceDateID = CAST(CONVERT(VARCHAR(8), (
    SELECT TOP 1 Date FROM eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
), 112) AS INT)
  AND mcb.OpeningBalanceGAP <> 0
ORDER BY ABS(mcb.OpeningBalanceGAP) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this specific alert table. Business context derived from the SP code comment history (Author: Adi Meidan) and the parent SP_eMoney_ClientBalance change log.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: P1, P2, P3, P4, P5, P6, P7, P8, P9, P9B, P10, P10A, P10B, P11*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 | Elements: 3/3, Logic: 8/10*
*Object: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance | Type: Table | Production Source: SP_eMoney_Client_Balance_Check_Opening_Balance*
