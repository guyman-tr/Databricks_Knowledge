# BI_DB_dbo.BI_CLData_AllTimeData_Optimove

> Optimove marketing platform feed table containing cumulative all-time Credit Line (CL) data per customer, organized by month. Currently **empty (0 rows as of 2026-04-23)** — no active writer SP exists in the Synapse SSDT project and the table is not registered in OpsDB. The companion table `BI_DB_CreditLineData_Optimove` (also empty) shares a subset of the same schema. The Optimove CL feed appears discontinued.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — Optimove marketing feed |
| **Production Source** | Unknown — no Generic Pipeline mapping, no writer SP identified in SSDT |
| **Refresh** | Unknown (no active ETL) — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Table** | BI_DB_dbo.BI_DB_CreditLineData_Optimove (similar schema, per-period variant, also empty) |

---

## 1. Business Meaning

`BI_CLData_AllTimeData_Optimove` was an Optimove marketing platform feed table that stored cumulative all-time Credit Line (CL) data per customer, organized by calendar month. Optimove is an external CRM/marketing tool used by eToro for customer lifecycle management and personalization campaigns.

Credit Lines (CL) are financial bonuses/credits granted to eToro customers under specific conditions, tracked in the eToro production system as `ActionTypeID=9, BonusTypeID=71` in `Fact_CustomerAction`. The `SP_Daily_CreditLine` SP processes these daily CL actions.

The "AllTimeData" suffix distinguishes this table from the companion `BI_DB_CreditLineData_Optimove`, which stores per-period CL data. The AllTimeData version adds monthly bucketing columns (MONTH, Year, MonthYear, DailySum) alongside the cumulative all-time total (`TotalCLEver`), providing Optimove with both period-level and lifetime CL signals for campaign segmentation.

The table is currently **empty** with no active writer SP. The Optimove CL data feed appears to have been discontinued — both this table and its companion are 0 rows. The feed was likely replaced by a newer Optimove integration approach or the CL promotional program was modified.

---

## 2. Business Logic

### 2.1 Credit Line Domain

**What**: Credit Lines are financial bonuses/credits received by eToro customers, tracked daily.

**Columns Involved**: `PostiveTotalCLAmount`, `DailySum`, `TotalCLEver`, `DateReceive`

**Rules**:
- `PostiveTotalCLAmount` — cumulative sum of positive CL amounts received on and before DateReceive for this customer (note: column name has typo "Positve")
- `DailySum` — the credit line amount received on a specific day (daily granularity)
- `TotalCLEver` — the all-time cumulative credit line amount received by the customer across all time
- `DateReceive` — date on which the credit line was received; NULL where no CL was received
- Source: `Fact_CustomerAction WHERE ActionTypeID=9 AND BonusTypeID=71`

### 2.2 Monthly Bucketing for Optimove

**What**: Monthly time-series structure for Optimove campaign segmentation.

**Columns Involved**: `DateReceive`, `EndOfMonthOFDateReceive`, `MonthYear`, `MONTH`, `Year`

**Rules**:
- `EndOfMonthOFDateReceive` — last day of the month containing `DateReceive` (EOMONTH equivalent)
- `MonthYear` — human-readable or ISO month label (e.g., "January 2023" or "2023-01") — nvarchar(61)
- `MONTH` — integer month number (1–12) extracted from DateReceive
- `Year` — integer year (e.g., 2023) extracted from DateReceive
- Optimove uses monthly time windows to track customer engagement with financial incentives

### 2.3 Rounds Column (Unclear)

**What**: A date-typed column named `Rounds` — purpose uncertain.

**Columns Involved**: `Rounds`

**Rules**:
- Stored as `date` data type — unusual for a campaign round concept
- In Optimove's campaign model, a "Round" is a campaign execution cycle with a specific date range
- `Rounds` may represent the Optimove campaign round end date or the campaign period boundary associated with the credit line
- This column is Tier 4 — verification required

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no optimization for any join pattern. Suitable for small export tables loaded in bulk. Given the table is currently empty, no query tuning is relevant.

**Warning**: The table is currently empty. Any query returns 0 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All-time CL per customer | `SELECT RealCID, TotalCLEver FROM ... GROUP BY RealCID` |
| Monthly CL activity | `WHERE MONTH = 3 AND Year = 2023` |
| Customers with CL in a period | `WHERE DateReceive BETWEEN @start AND @end` |
| Join to customer data | `JOIN DWH_dbo.Dim_Customer ON RealCID = RealCID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON a.RealCID = c.RealCID` | Customer demographics |
| BI_DB_dbo.BI_DB_CreditLineData_Optimove | `ON a.RealCID = b.RealCID AND a.DateReceive = b.DateReceive` | Compare AllTimeData vs per-period CL |
| DWH_dbo.Fact_CustomerAction | `ON a.RealCID = b.RealCID AND ActionTypeID=9 AND BonusTypeID=71` | Verify CL source transactions |

### 3.4 Gotchas

- **Table is currently empty** — no rows as of 2026-04-23. All queries return 0 rows.
- **Column name typo** — `PostiveTotalCLAmount` is missing the second 'i' (should be "Positive"). Use exact spelling when querying.
- **`Rounds` is typed as `date`** — semantically unusual; purpose unclear. Do not assume it contains a campaign round number.
- **No OpsDB registration** — table will not be refreshed by the OpsDB service broker pipeline.
- **Companion table also empty** — `BI_DB_CreditLineData_Optimove` is also 0 rows; this confirms the Optimove CL feed is fully discontinued, not just this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, related table schema, and domain context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | eToro customer ID (Real account). Links to DWH_dbo.Dim_Customer.RealCID. (Tier 3 — BI_DB_CreditLineData_Optimove + SP_Daily_CreditLine domain) |
| 2 | DateReceive | date | YES | Date on which the credit line was received by the customer. NULL where no credit line was received in the period. (Tier 3 — BI_DB_CreditLineData_Optimove + SP_Daily_CreditLine) |
| 3 | EndOfMonthOFDateReceive | date | YES | Last calendar day of the month containing DateReceive (EOMONTH equivalent). Used by Optimove for monthly campaign segmentation. (Tier 3 — column name + Optimove monthly bucketing pattern) |
| 4 | Rounds | date | YES | Optimove campaign round date or period boundary. Purpose unclear — date type for a "round" concept is atypical. Requires verification. (Tier 4 — unknown source) |
| 5 | MonthYear | nvarchar(61) | YES | Human-readable or ISO formatted month-year label (e.g., "January 2023" or "2023-01"). Used by Optimove for campaign round labeling. Wide nvarchar(61) accommodates full month names. (Tier 3 — column name + Optimove feed pattern) |
| 6 | MONTH | int | YES | Integer month number (1–12) extracted from DateReceive. Used for Optimove campaign targeting by month. (Tier 3 — column name) |
| 7 | Year | int | YES | Integer calendar year extracted from DateReceive (e.g., 2023). (Tier 3 — column name) |
| 8 | PostiveTotalCLAmount | decimal(38,2) | YES | Cumulative total of positive credit line amounts received by this customer on and before DateReceive. Note: column name has typo ("Positve" missing second 'i'). (Tier 3 — BI_DB_CreditLineData_Optimove + CL domain) |
| 9 | DailySum | decimal(38,2) | YES | Credit line amount received on the specific DateReceive (daily granularity). Distinct from PostiveTotalCLAmount which is cumulative. (Tier 3 — column name + CL domain) |
| 10 | TotalCLEver | decimal(38,2) | YES | All-time cumulative credit line received by this customer across all dates. The "AllTimeData" distinguisher — this column is absent from the per-period BI_DB_CreditLineData_Optimove table. (Tier 3 — BI_DB_CreditLineData_Optimove schema comparison + name) |
| 11 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | etoro production (Customer) | RealCID | Passthrough |
| DateReceive | etoro production (CL transaction) | DateReceive | Passthrough |
| EndOfMonthOFDateReceive | Computed | DateReceive | EOMONTH(DateReceive) |
| Rounds | Unknown | Unknown | — |
| MonthYear | Computed | DateReceive | FORMAT(DateReceive, ...) |
| MONTH | Computed | DateReceive | MONTH(DateReceive) |
| Year | Computed | DateReceive | YEAR(DateReceive) |
| PostiveTotalCLAmount | etoro production (CL amount) | TotalCLAmount | Cumulative positive sum |
| DailySum | etoro production (CL amount) | TotalCLAmount | Daily amount |
| TotalCLEver | etoro production (CL amount) | TotalCLAmount | All-time cumulative sum |
| UpdateDate | ETL pipeline | — | GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro production (ActionTypeID=9, BonusTypeID=71 in Fact_CustomerAction)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_CLData_AllTimeData_Optimove (0 rows — EMPTY as of 2026-04-23)
  |-- Was presumably exported to Optimove marketing platform --|
  v
Optimove (external CRM — campaign segmentation, personalization)

Domain context: Credit Line data also flows via:
  SP_Daily_CreditLine → BI_DB_dbo.BI_DB_Daily_CreditLine (active, separate pipeline)

Companion Optimove table (also empty):
  BI_DB_dbo.BI_DB_CreditLineData_Optimove (per-period CL data, subset of columns)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer demographics via RealCID FK |
| Credit Line domain | DWH_dbo.Fact_CustomerAction | Source CL transactions (ActionTypeID=9, BonusTypeID=71) |
| Schema sibling | BI_DB_dbo.BI_DB_CreditLineData_Optimove | Per-period CL Optimove feed (also empty) |
| CL daily tracker | BI_DB_dbo.BI_DB_Daily_CreditLine | Active daily CL tracking table (separate pipeline) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views. The table was presumably consumed by an external Optimove API integration.

---

## 7. Sample Queries

### Check table state

```sql
SELECT
    COUNT(*) AS row_count,
    MIN(DateReceive) AS earliest,
    MAX(DateReceive) AS latest,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_CLData_AllTimeData_Optimove];
-- Returns 0 rows as of 2026-04-23
```

### All-time credit line by customer (when populated)

```sql
SELECT
    RealCID,
    TotalCLEver,
    MAX(PostiveTotalCLAmount) AS PeakCumulativeCL,
    MIN(DateReceive) AS FirstCLDate,
    MAX(DateReceive) AS LastCLDate
FROM [BI_DB_dbo].[BI_CLData_AllTimeData_Optimove]
GROUP BY RealCID
ORDER BY TotalCLEver DESC;
```

### Monthly CL activity for Optimove segmentation

```sql
SELECT
    MonthYear,
    MONTH,
    Year,
    COUNT(DISTINCT RealCID) AS CustomersWithCL,
    SUM(DailySum) AS TotalCLGranted
FROM [BI_DB_dbo].[BI_CLData_AllTimeData_Optimove]
WHERE DailySum > 0
GROUP BY MonthYear, MONTH, Year
ORDER BY Year DESC, MONTH DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table is not registered in OpsDB and has no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 6.5/10 | Phases: 6/14 (P3/P5/P6/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 9 T3, 1 T4, 1 T5 | Elements: 11/11 | Object: BI_DB_dbo.BI_CLData_AllTimeData_Optimove | Type: Table | Production Source: Unknown (Optimove CL feed — discontinued)*
*Note: Table is currently empty (0 rows). Companion table BI_DB_CreditLineData_Optimove also empty. No active writer SP. Quality capped at 6.5 due to empty table and partial Tier 3 inference only.*
