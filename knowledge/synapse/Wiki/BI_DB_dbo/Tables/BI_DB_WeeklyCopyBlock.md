# BI_DB_dbo.BI_DB_WeeklyCopyBlock

> 4,961-row weekly copy-trading block/unblock report tracking Popular Investors and traders whose copy functionality was blocked (due to high risk score or BO admin request) during the past week — capturing block start/end timestamps, AUM and copier counts at both points, equity snapshots, risk scores, and manager assignment. Refreshed weekly (Mondays) by SP_WeeklyCopyBlock via TRUNCATE+INSERT from production BlockedCustomerOperations (current + history). Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_WeeklyCopyBlock` from etoro.Customer.BlockedCustomerOperations + History |
| **Refresh** | Weekly (Mondays) — TRUNCATE+INSERT. Only executes if result set is non-empty. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC, BlockStart ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides a **weekly snapshot of copy-trading blocks** on the eToro platform. When a Popular Investor or trader is blocked from being copied (due to high risk score exceeding platform thresholds, or manual BO admin intervention), this table captures the event along with before/after financial metrics to assess block impact.

The 4,961 rows represent blocks that were either **started or ended** during the most recent reporting week. Each row includes:
- The block event itself (CID, reason, start/end timestamps)
- **AUM** (Assets Under Management from copiers) at block start and end
- **Copier counts** at block start and end  
- **Equity** at block start and end
- **Risk scores** (1-10 scale from 7-day portfolio deviation) at block start and end
- The **account manager** responsible for the PI

The SP runs on Mondays, looking at the previous week (Monday-to-Monday). It combines currently active blocks (from the production `Customer.BlockedCustomerOperations` table) with resolved blocks (from `History.BlockedCustomerOperations`). Only BlockReasonID 1 (BO Admin) and 2 (High Risk Score) are included.

Currently all rows have OperationTypeID=2. The dominant reason is High Risk Score (96% of blocks). Active blocks use sentinel date 2999-12-31 for BlockEnd.

---

## 2. Business Logic

### 2.1 Block Source Union

**What**: Combines current active blocks with historical resolved blocks for the reporting week.
**Columns Involved**: CID, OperationTypeID, BlockStart, BlockEnd, BlockReasonID, IsBlock
**Rules**:
- Current blocks (Customer.BlockedCustomerOperations): WHERE Occurred BETWEEN @sw AND @ew, BlockReasonID IN (1,2). First occurrence per CID selected (ROW_NUMBER by Occurred). IsBlock=1, BlockEnd='2999-12-31'.
- History blocks (History.BlockedCustomerOperations): WHERE BlockStart or BlockEnd falls within the week, BlockReasonID IN (1,2). Latest by BlockEnd DESC per CID. IsBlock=0. Excluded if CID still has an active current block.

### 2.2 AUM Calculation (Start/End)

**What**: AUM from copiers at block start and end dates.
**Columns Involved**: AUMStart, AUMEnd, CopiersStart, CopiersEnd
**Rules**:
- Source: general.etoroGeneral_History_GuruCopiers
- AUM = SUM(Cash + Investment + PnL) for all copiers of this PI at the given date
- CopiersStart/End = COUNT of copier CIDs at the given date
- For active blocks (BlockEnd=2999-12-31), AUMEnd uses the max available GuruCopiers date

### 2.3 Equity Snapshot

**What**: Portfolio equity at block start and end dates.
**Columns Involved**: EquityStart, EquityEnd
**Rules**:
- Source: DWH_dbo.V_Liabilities
- Equity = PositionPnL + RealizedEquity at the block date (by DateID)
- For active blocks, uses max available Liabilities date

### 2.4 Risk Score Bucketing

**What**: 10-bucket risk score derived from 7-day portfolio deviation.
**Columns Involved**: RiskScoreStart, RiskScoreEnd
**Rules**:
- Source: BI_DB_dbo.DWH_CIDs7DaysDeviation.Deviation
- Buckets: 1 (< 0.00034) through 10 (>= 0.04763), 0 if NULL/no data
- Computed at block start date and block end date independently

### 2.5 Block Status Derivation

**What**: Human-readable block reason and status.
**Columns Involved**: BlockReason, UserStatus, WeekBlockEnd, WeekBlockStart
**Rules**:
- BlockReason: 1='Requested by BO Admin', 2='High Risk Score'
- UserStatus: IsBlock=1 → 'Blocked', IsBlock=0 → 'UnBlocked'
- WeekBlockEnd: 1 if BlockEnd falls within the reporting week (unblocked this week)
- WeekBlockStart: 1 if BlockStart falls within the reporting week (blocked this week)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution. CLUSTERED INDEX on (CID, BlockStart) supports lookups by customer and chronological ordering of blocks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Currently blocked PIs | `WHERE IsBlock = 1` |
| Blocks resolved this week | `WHERE WeekBlockEnd = 1` |
| New blocks this week | `WHERE WeekBlockStart = 1` |
| High-impact blocks (AUM loss) | `WHERE IsBlock = 1 ORDER BY AUMStart DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| DWH_dbo.Dim_Manager | Manager name match | Manager details |

### 3.4 Gotchas

- **BlockEnd sentinel**: Active blocks use 2999-12-31 as BlockEnd — filter or handle in calculations.
- **TRUNCATE+INSERT**: Table only contains the most recent week's data. No historical weeks are retained.
- **Conditional execution**: SP only inserts if result set > 0. If no blocks occurred in the week, the table retains the PREVIOUS week's data (TRUNCATE happens only when data exists).
- **AUM can be 0**: If the PI has no copiers at the snapshot date, AUMStart/AUMEnd = 0 (not NULL).
- **OperationTypeID**: Currently always 2 in the data despite the column existing.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — verbatim description |
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID of the blocked PI/trader. FK to Dim_Customer.RealCID. One row per distinct block event per week. (Tier 2 — SP_WeeklyCopyBlock) |
| 2 | OperationTypeID | int | NO | Operation type from BlockedCustomerOperations. Currently always 2 (copy block). (Tier 2 — SP_WeeklyCopyBlock) |
| 3 | BlockStart | datetime | NO | Timestamp when the copy block was initiated. For current blocks: the first Occurred datetime in the week. For history blocks: original BlockStart. (Tier 2 — SP_WeeklyCopyBlock) |
| 4 | BlockEnd | datetime | NO | Timestamp when the copy block was lifted. 2999-12-31 00:00:00 = still active (sentinel). For resolved blocks: actual unblock timestamp from History.BlockedCustomerOperations. (Tier 2 — SP_WeeklyCopyBlock) |
| 5 | BlockReasonID | int | NO | Reason code for the block. 1=Requested by BO Admin, 2=High Risk Score. Only these two values are loaded (SP filters on IN (1,2)). (Tier 2 — SP_WeeklyCopyBlock) |
| 6 | IsBlock | int | NO | Active block indicator. 1=currently blocked (from Customer.BlockedCustomerOperations), 0=block resolved/unblocked (from History.BlockedCustomerOperations). (Tier 2 — SP_WeeklyCopyBlock) |
| 7 | AUMStart | money | YES | Assets Under Management from copiers at block start date. SUM(Cash+Investment+PnL) from GuruCopiers. 0 if no copiers exist. NULL if no match in GuruCopiers. (Tier 2 — SP_WeeklyCopyBlock) |
| 8 | AUMEnd | money | YES | Assets Under Management from copiers at block end date (or latest available date for active blocks). SUM(Cash+Investment+PnL) from GuruCopiers. (Tier 2 — SP_WeeklyCopyBlock) |
| 9 | CopiersStart | int | YES | Number of copiers at block start date. COUNT of CIDs from GuruCopiers table at that date. (Tier 2 — SP_WeeklyCopyBlock) |
| 10 | CopiersEnd | int | YES | Number of copiers at block end date (or latest available date for active blocks). (Tier 2 — SP_WeeklyCopyBlock) |
| 11 | EquityStart | decimal(20,4) | YES | Portfolio equity at block start date. PositionPnL + RealizedEquity from V_Liabilities. (Tier 2 — SP_WeeklyCopyBlock) |
| 12 | EquityEnd | decimal(20,4) | YES | Portfolio equity at block end date. PositionPnL + RealizedEquity from V_Liabilities. 0 if active block uses max date with no match. (Tier 2 — SP_WeeklyCopyBlock) |
| 13 | RiskScoreStart | int | YES | Portfolio risk score (1-10) at block start date. Derived from 7-day deviation buckets in DWH_CIDs7DaysDeviation. 0=no data/below minimum threshold. (Tier 2 — SP_WeeklyCopyBlock) |
| 14 | RiskScoreEnd | int | YES | Portfolio risk score (1-10) at block end date. 0 for resolved blocks typically means deviation dropped below all thresholds. (Tier 2 — SP_WeeklyCopyBlock) |
| 15 | BlockReason | varchar(21) | NO | Human-readable block reason. 'Requested by BO Admin' (BlockReasonID=1) or 'High Risk Score' (BlockReasonID=2). (Tier 2 — SP_WeeklyCopyBlock) |
| 16 | UserName | varchar(50) | YES | Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 17 | Manager | nvarchar(50) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). NULL if no manager assigned. (Tier 2 — SP_WeeklyCopyBlock) |
| 18 | UserStatus | varchar(9) | NO | Block status label. 'Blocked' (IsBlock=1) or 'UnBlocked' (IsBlock=0). (Tier 2 — SP_WeeklyCopyBlock) |
| 19 | WeekBlockEnd | int | NO | Flag: 1 if the block ended during the reporting week, 0 otherwise. Identifies unblock events this week. (Tier 2 — SP_WeeklyCopyBlock) |
| 20 | WeekBlockStart | int | NO | Flag: 1 if the block started during the reporting week, 0 otherwise. Identifies new blocks this week. (Tier 2 — SP_WeeklyCopyBlock) |
| 21 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_WeeklyCopyBlock. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | etoro.Customer.BlockedCustomerOperations | CID | passthrough |
| OperationTypeID | etoro.Customer.BlockedCustomerOperations | OperationTypeID | passthrough |
| BlockStart | etoro.Customer/History.BlockedCustomerOperations | Occurred / BlockStart | passthrough (first per CID for current) |
| BlockEnd | etoro.History.BlockedCustomerOperations | BlockEnd | passthrough (sentinel 2999-12-31 for current) |
| BlockReasonID | etoro.Customer.BlockedCustomerOperations | BlockReasonID | passthrough (filtered IN (1,2)) |
| IsBlock | — | — | SP computed: 1=current, 0=history |
| AUMStart/End | etoroGeneral_History_GuruCopiers | Cash+Investment+PnL | computed SUM at block date |
| CopiersStart/End | etoroGeneral_History_GuruCopiers | CID count | computed COUNT at block date |
| EquityStart/End | DWH_dbo.V_Liabilities | PositionPnL+RealizedEquity | computed at block date |
| RiskScoreStart/End | BI_DB_dbo.DWH_CIDs7DaysDeviation | Deviation | computed 10-bucket CASE |
| BlockReason | — | BlockReasonID | computed CASE to display name |
| UserName | DWH_dbo.Dim_Customer (← Customer.CustomerStatic) | UserName | passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | computed concatenation |
| UserStatus | — | IsBlock | computed CASE to display label |
| WeekBlockEnd/Start | — | BlockEnd/Start | computed — date range flag |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.BlockedCustomerOperations (active blocks, production)
etoro.History.BlockedCustomerOperations (resolved blocks, production)
  |-- External Tables (lake export)
  v
BI_DB_dbo.External_etoro_Customer_BlockedCustomerOperations
BI_DB_dbo.External_etoro_History_BlockedCustomerOperations
  |
  +-- general.etoroGeneral_History_GuruCopiers (AUM/copiers)
  +-- DWH_dbo.V_Liabilities (equity)
  +-- BI_DB_dbo.DWH_CIDs7DaysDeviation (risk scores)
  +-- DWH_dbo.Dim_Customer (username)
  +-- DWH_dbo.Dim_Manager (manager name)
  |
  |-- SP_WeeklyCopyBlock @dd (weekly, Mondays)
  |   TRUNCATE + INSERT (conditional on non-empty result)
  v
BI_DB_dbo.BI_DB_WeeklyCopyBlock (4,961 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile (RealCID) |
| Manager | DWH_dbo.Dim_Manager | Account manager lookup |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| — | — | No known downstream consumers in SSDT |

---

## 7. Sample Queries

### 7.1 Currently Blocked PIs with High AUM Impact

```sql
SELECT CID, UserName, Manager, AUMStart, CopiersStart, RiskScoreStart, BlockStart
FROM BI_DB_dbo.BI_DB_WeeklyCopyBlock
WHERE IsBlock = 1
ORDER BY AUMStart DESC
```

### 7.2 Blocks Resolved This Week — Risk Score Change

```sql
SELECT CID, UserName, BlockReason, RiskScoreStart, RiskScoreEnd,
       DATEDIFF(DAY, BlockStart, BlockEnd) AS block_days
FROM BI_DB_dbo.BI_DB_WeeklyCopyBlock
WHERE WeekBlockEnd = 1
ORDER BY block_days DESC
```

### 7.3 Block Summary by Manager

```sql
SELECT Manager, COUNT(*) AS total_blocks,
       SUM(IsBlock) AS currently_blocked,
       SUM(CASE WHEN WeekBlockStart = 1 THEN 1 ELSE 0 END) AS new_this_week
FROM BI_DB_dbo.BI_DB_WeeklyCopyBlock
GROUP BY Manager
ORDER BY total_blocks DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found for "WeeklyCopyBlock". Context derived from SP code and production table names.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 21/21, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_WeeklyCopyBlock | Type: Table | Production Source: SP_WeeklyCopyBlock (ETL-computed from BlockedCustomerOperations + DWH dimensions)*
