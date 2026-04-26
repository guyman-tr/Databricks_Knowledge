# BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert

> 0-row alert table (healthy state) that fires when daily deposit totals diverge anywhere in the CB/DDR aggregation chain — sourced from `DWH_dbo.Fact_CustomerAction`, the Client Balance pipeline tables, and three BLACKLISTED DDR tables, run daily by `SP_ClientBalance_DDR_Data_Integrity_Alert`. Designed to detect data-duplication or data-loss events anywhere between FactCustomerAction and the DDR/ClientBalance aggregation chain. Empty in a healthy pipeline; populated only when a mismatch is detected for the run date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + BI_DB_dbo CB/DDR pipeline tables via `SP_ClientBalance_DDR_Data_Integrity_Alert` |
| **Refresh** | Daily (SB_Daily, @date param — TRUNCATE + INSERT WHERE DataIntegrityProblem=1) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no index) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ClientBalance_DDR_Data_Integrity_Alert` is a daily-run data integrity monitoring table for the deposit aggregation chain. It reconciles the total deposits from `DWH_dbo.Fact_CustomerAction` (the canonical source) against every downstream aggregation layer in the Client Balance and DDR pipelines. If any pair mismatches for the run date, one row is inserted with `DataIntegrityProblem=1`.

The table was created on 2021-05-03 by Guy Manova following a data duplication event on 2021-04-02 that caused missing/excess data to propagate silently through the CB/DDR chain. The 2024-04-16 update by Artyom Bogomolsky extended the CB-side comparison to include ActionTypeID=44 (a new deposit type), while the DDR-side comparison intentionally retains ActionTypeID=7 only (the DDR pipeline does not process ActionTypeID=44).

**Healthy state**: 0 rows. The table is TRUNCATED on each daily run and repopulated only when a mismatch is found. Absence of rows = all deposit totals agreed for the most-recently run date.

**Alert state**: Rows present indicate the pipeline ran for a date with at least one mismatching source pair. The stored column values allow investigators to identify which layer diverged and by how much.

**Downstream consumers**: None identified. This table is consumed manually or via monitoring processes — it is not a source for other BI_DB_dbo SPs.

---

## 2. Business Logic

### 2.1 Two-Track Deposit Comparison

**What**: The SP calculates two deposit totals from `Fact_CustomerAction` and compares each against a different set of downstream sources.

**Rules**:

**Track 1 — CB comparison** (uses `FCADeposits = SUM(Amount) WHERE ActionTypeID IN (7,44)`):
- `FCADeposits` vs `CBCIDLevelDeposits` (BI_DB_Client_Balance_CID_Level_New)
- `FCADeposits` vs `CBAggLevelDeposits` (BI_DB_Client_Balance_Aggregate_Level_New)

**Track 2 — DDR comparison** (uses `DepositDDR = SUM(Amount) WHERE ActionTypeID=7` — NOT stored, internal variable only):
- `DepositDDR` vs `DDRCIDLevelDeposits` (BI_DB_DDR_CID_Level — BLACKLISTED)
- `DepositDDR` vs `DDRDailyAggLevelDeposits` (BI_DB_DDR_Daily_Aggregated — BLACKLISTED)
- `DepositDDR` vs `DDRAggLevelDeposits` (BI_DB_DDR_TimeRange_Aggregated_Country_Level — BLACKLISTED, TimeRange='Yesterday')

The asymmetry is deliberate: ActionTypeID=44 was added to the CB pipeline but not to the DDR pipeline. The DDR tables only ever receive ActionTypeID=7 data, so comparing them against `FCADeposits` (7+44) would always produce a false alert.

**Note**: `DepositDDR` is computed in the `#fca` temp table but is explicitly commented out in the INSERT statement (`-- ,DepositDDR`) — it is used only for the internal CASE comparison and is not stored in the alert table.

### 2.2 DataIntegrityProblem Flag

**What**: Single binary flag encoding all five comparison checks.

**Rules**:
```sql
DataIntegrityProblem =
  CASE WHEN ISNULL(FCADeposits,0)  <> ISNULL(CBCIDLevelDeposits,0)
        OR  ISNULL(FCADeposits,0)  <> ISNULL(CBAggLevelDeposits,0)
        OR  ISNULL(DepositDDR,0)   <> ISNULL(DDRCIDLevelDeposits,0)
        OR  ISNULL(DepositDDR,0)   <> ISNULL(DDRAggLevelDeposits,0)
        OR  ISNULL(DepositDDR,0)   <> ISNULL(DDRDailyAggLevelDeposits,0)
  THEN 1 ELSE 0 END
```

- NULL handling: `ISNULL(x,0)` — a NULL source (table failed to write data for the date) triggers a mismatch vs. a non-zero FCA total, catching silent ETL failures
- Only rows with `DataIntegrityProblem=1` are inserted — value is always 1 in any row present in this table
- `DataIntegrityProblem=0` rows exist only in the `#control` temp table and are discarded before INSERT

### 2.3 TRUNCATE + INSERT Pattern

**What**: Daily full refresh with no history.

**Rules**:
- Table is TRUNCATED before each INSERT — only the most recent alert run is retained
- If the daily run finds no mismatches, the table remains empty after TRUNCATE
- No historical record is preserved — for trend analysis, rely on job run logs or external monitoring

### 2.4 LEFT JOIN Source Structure

**What**: The SP joins all sources via LEFT JOIN from `#fca` (the FCA temp table).

**Rules**:
- If `Fact_CustomerAction` has no rows for `@dateID` (no deposits that day), `#fca` is empty → no `#control` row → nothing inserted even if downstream tables have data
- If any downstream table is empty for `@dateID`, its column appears as NULL → ISNULL(x,0)=0 → triggers mismatch alert if FCA total is non-zero
- The LEFT JOIN cascade: `#fca` → `#cbCID` → `#cbAgg` → `#ddrCID` → `#ddrCountry` → `#ddrDailyAgg`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution — appropriate for a diagnostic alert table that normally holds 0 rows. **HEAP** index — no clustering needed given the near-always-empty state and single-row-per-run write pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| "Is there a current alert?" | `SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert` — any non-zero count = alert |
| "What diverged for the last alert date?" | `SELECT * FROM BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert` — compare column values |
| "Which layer is the outlier?" | Compare FCADeposits, CBCIDLevelDeposits, CBAggLevelDeposits (CB track) and DDRCIDLevelDeposits, DDRDailyAggLevelDeposits, DDRAggLevelDeposits (DDR track) — the diverging value identifies the pipeline layer |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Dim_Date` | `DateID = Dim_Date.DateID` | Resolve DateID to calendar date |
| `DWH_dbo.Fact_CustomerAction` | `DateID = fca.DateID AND ActionTypeID IN (7,44)` | Verify FCA deposits independently for the alert date |

### 3.4 Gotchas

- **Table is always empty in healthy state**: `SELECT COUNT(*) = 0` is the normal result. Do not assume the table is broken if it returns 0 rows.
- **Only the last run date is retained**: TRUNCATE before INSERT means no history. If an alert fired yesterday and was re-run today with no mismatches, yesterday's alert data is gone.
- **DataIntegrityProblem is always 1 here**: The WHERE clause filters to DataIntegrityProblem=1 before INSERT — querying this column is redundant; its presence in a row means the flag is set.
- **DepositDDR is not stored**: The ActionTypeID=7-only benchmark used for DDR comparisons is computed internally but excluded from the INSERT. The stored `FCADeposits` column includes both ActionTypeID 7 and 44 — do not use it to understand DDR alert logic.
- **DDR sources are BLACKLISTED**: DDRCIDLevelDeposits, DDRDailyAggLevelDeposits, and DDRAggLevelDeposits come from blacklisted DDR tables — their documented values have lower confidence (Tier 4).
- **NULL sources trigger alerts**: A downstream table that simply failed to load data for a date (resulting in NULL/0 for that column) will cause DataIntegrityProblem=1. This is by design — it catches silent ETL failures.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Description derived from SP code analysis and live data sampling |
| Tier 4 | Source table is on the blacklist; description is best available from SP logic |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL-computed date integer from @date parameter: CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Identifies the business date for which the deposit reconciliation was run. Joins to DWH_dbo.Dim_Date.DateID. (Tier 2 — SP_ClientBalance_DDR_Data_Integrity_Alert) |
| 2 | FCADeposits | float | YES | Total deposit amount from DWH_dbo.Fact_CustomerAction for @dateID: SUM(Amount) WHERE ActionTypeID IN (7,44). Includes both standard FCA deposits (ActionTypeID=7) and the deposit type added in the April 2024 update (ActionTypeID=44). Used as the CB-track benchmark — compared against CBCIDLevelDeposits and CBAggLevelDeposits. (Tier 2 — SP_ClientBalance_DDR_Data_Integrity_Alert) |
| 3 | CBCIDLevelDeposits | float | YES | Total deposits from BI_DB_Client_Balance_CID_Level_New for @dateID: SUM(Deposits). CID-level client balance aggregate. Compared against FCADeposits (ActionTypeID 7+44) in the DataIntegrityProblem check. (Tier 2 — SP_ClientBalance_DDR_Data_Integrity_Alert) |
| 4 | CBAggLevelDeposits | float | YES | Total deposits from BI_DB_Client_Balance_Aggregate_Level_New for @dateID: SUM(Deposits). Aggregate-level client balance rollup. Compared against FCADeposits (ActionTypeID 7+44) in the DataIntegrityProblem check. (Tier 2 — SP_ClientBalance_DDR_Data_Integrity_Alert) |
| 5 | DDRCIDLevelDeposits | float | YES | Total deposits from BI_DB_DDR_CID_Level (BLACKLISTED) for @dateID: SUM(Deposits). DDR CID-level aggregate. Compared against DepositDDR (ActionTypeID=7 only — not stored) in the DataIntegrityProblem check. The DDR pipeline does not process ActionTypeID=44, so the benchmark for DDR comparisons uses ActionTypeID=7 only. (Tier 4 — source blacklisted) |
| 6 | DDRDailyAggLevelDeposits | float | YES | Total deposits from BI_DB_DDR_Daily_Aggregated (BLACKLISTED) for @dateID: SUM(Deposits). DDR daily aggregate rollup. Compared against DepositDDR (ActionTypeID=7 only — not stored) in the DataIntegrityProblem check. (Tier 4 — source blacklisted) |
| 7 | DDRAggLevelDeposits | float | YES | Total deposits from BI_DB_DDR_TimeRange_Aggregated_Country_Level (BLACKLISTED) for @dateID with TimeRange='Yesterday': SUM(Deposits). Country-level DDR time-range aggregate. Compared against DepositDDR (ActionTypeID=7 only — not stored) in the DataIntegrityProblem check. (Tier 4 — source blacklisted) |
| 8 | DataIntegrityProblem | int | YES | Binary reconciliation flag. Value is always 1 in this table (only rows with DataIntegrityProblem=1 are inserted). Set to 1 if any of five comparisons mismatch: FCADeposits vs CBCIDLevelDeposits, FCADeposits vs CBAggLevelDeposits, DepositDDR(7 only) vs DDRCIDLevelDeposits, DepositDDR(7 only) vs DDRDailyAggLevelDeposits, or DepositDDR(7 only) vs DDRAggLevelDeposits. NULL sources are treated as 0 (ISNULL logic) — a missing source triggers an alert. (Tier 2 — SP_ClientBalance_DDR_Data_Integrity_Alert) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| DateID | ETL (@date param) | — | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| FCADeposits | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID IN (7,44) |
| CBCIDLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Deposits | SUM(Deposits) for @dateID |
| CBAggLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Deposits | SUM(Deposits) for @dateID |
| DDRCIDLevelDeposits | BI_DB_dbo.BI_DB_DDR_CID_Level (BLACKLISTED) | Deposits | SUM(Deposits) for @dateID |
| DDRDailyAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (BLACKLISTED) | Deposits | SUM(Deposits) for @dateID |
| DDRAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level (BLACKLISTED) | Deposits | SUM(Deposits) WHERE TimeRange='Yesterday' |
| DataIntegrityProblem | Computed | — | CASE WHEN any pair mismatches THEN 1 ELSE 0 END — only rows with =1 inserted |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction               (ActionTypeID IN (7,44) = FCADeposits; ActionTypeID=7 = internal DepositDDR)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New    (CBCIDLevelDeposits)
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (CBAggLevelDeposits)
BI_DB_dbo.BI_DB_DDR_CID_Level             (DDRCIDLevelDeposits — BLACKLISTED)
BI_DB_dbo.BI_DB_DDR_Daily_Aggregated      (DDRDailyAggLevelDeposits — BLACKLISTED)
BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level (DDRAggLevelDeposits — BLACKLISTED, TimeRange='Yesterday')
    |-- SP_ClientBalance_DDR_Data_Integrity_Alert (@date, Daily SB_Daily) ---|
    |-- TRUNCATE + INSERT WHERE DataIntegrityProblem = 1 ---|
    v
BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert (0 rows in healthy state)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| FCADeposits | DWH_dbo.Fact_CustomerAction | Source: SUM(Amount) for ActionTypeID IN (7,44) |
| CBCIDLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Source: SUM(Deposits) |
| CBAggLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Source: SUM(Deposits) |
| DDRCIDLevelDeposits | BI_DB_dbo.BI_DB_DDR_CID_Level (BLACKLISTED) | Source: SUM(Deposits) |
| DDRDailyAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (BLACKLISTED) | Source: SUM(Deposits) |
| DDRAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level (BLACKLISTED) | Source: SUM(Deposits) WHERE TimeRange='Yesterday' |
| DateID | DWH_dbo.Dim_Date | Logical FK — resolves to calendar date |

### 6.2 Referenced By (other objects point to this)

No downstream SPs or views identified in the BI_DB_dbo schema.

---

## 7. Sample Queries

### Check for Active Alert

```sql
SELECT *
FROM [BI_DB_dbo].[BI_DB_ClientBalance_DDR_Data_Integrity_Alert]
```

*(Returns 0 rows in healthy state. Any row = active alert for the last run date.)*

### Identify Diverging Layer

```sql
SELECT
    DateID,
    FCADeposits,
    CBCIDLevelDeposits,
    FCADeposits - CBCIDLevelDeposits AS CB_CID_Delta,
    CBAggLevelDeposits,
    FCADeposits - CBAggLevelDeposits AS CB_Agg_Delta,
    DDRCIDLevelDeposits,
    DDRDailyAggLevelDeposits,
    DDRAggLevelDeposits
FROM [BI_DB_dbo].[BI_DB_ClientBalance_DDR_Data_Integrity_Alert]
```

*(Compare deltas to identify which pipeline layer diverged. CB deltas compare against FCADeposits (7+44). DDR deltas compare against the unstored DepositDDR (7 only) — reconstruct by querying Fact_CustomerAction WHERE ActionTypeID=7 for the same DateID.)*

### Reconstruct DepositDDR (ActionTypeID=7 Only) for Cross-Reference

```sql
SELECT
    CAST(CONVERT(VARCHAR(8), DateID, 112) AS DATE) AS alert_date,
    SUM(Amount) AS DepositDDR_Baseline
FROM [DWH_dbo].[Fact_CustomerAction]
WHERE DateID = (SELECT TOP 1 DateID FROM [BI_DB_dbo].[BI_DB_ClientBalance_DDR_Data_Integrity_Alert])
  AND ActionTypeID = 7
GROUP BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this data integrity alert table.

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 3 T4, 0 T5, 0 Propagation | Elements: 8/8, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + BI_DB_dbo CB/DDR pipeline*
